// lib/services/alert_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart';
import 'location_service.dart';
import 'package:geocoding/geocoding.dart';

class AlertService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LocationService _locationService = LocationService();

  // Send emergency alert to trusted contacts with location
  Future<Map<String, dynamic>> sendEmergencyAlert({
    required String userId,
    required String userName,
    required String userPhone,
    String? customMessage,
  }) async {
    try {
      debugPrint('🚨 Starting emergency alert process...');

      // Get current location
      final Position? position = await Geolocator.getCurrentPosition();

      // Check if position is null
      if (position == null) {
        return {
          'success': false,
          'message': 'Unable to get location. Please enable location services.',
        };
      }

      debugPrint('📍 Location obtained: ${position.latitude}, ${position.longitude}');

      // Get address from coordinates
      final String address = await _getAddressFromCoordinates(
        position.latitude,
        position.longitude,
      );

      // Get user's trusted contacts
      final DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(userId)
          .get();

      if (!userDoc.exists) {
        return {
          'success': false,
          'message': 'User profile not found',
        };
      }

      final Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
      final List<dynamic> trustedContacts = userData['trustedContacts'] ?? [];

      if (trustedContacts.isEmpty) {
        return {
          'success': false,
          'message': 'No trusted contacts added. Please add contacts first.',
        };
      }

      debugPrint('👥 Found ${trustedContacts.length} trusted contacts');

      // Create Google Maps URL
      final String locationUrl = _getGoogleMapsUrl(position);
      
      // Alert message
      final String alertMessage = customMessage ?? 
          'EMERGENCY! I need help immediately! Please check my location.';

      // Create alert document
      final Map<String, dynamic> alertData = {
        'senderId': userId,
        'senderName': userName,
        'senderPhone': userPhone,
        'message': alertMessage,
        'location': {
          'latitude': position.latitude,
          'longitude': position.longitude,
          'accuracy': position.accuracy,
          'address': address,
        },
        'locationUrl': locationUrl,
        'timestamp': FieldValue.serverTimestamp(),
        'createdAt': DateTime.now().toIso8601String(),
        'status': 'active',
        'contactedPeople': [],
      };

      // Save alert to Firestore
      final DocumentReference alertRef = await _firestore
          .collection('emergencyAlerts')
          .add(alertData);

      debugPrint('💾 Alert saved to Firestore: ${alertRef.id}');

      // Send alerts to all trusted contacts
      final List<Map<String, dynamic>> notificationResults = [];
      
      for (final contact in trustedContacts) {
        final Map<String, dynamic> result = await _sendAlertToContact(
          contact: contact as Map<String, dynamic>,
          userName: userName,
          userPhone: userPhone,
          message: alertMessage,
          location: address,
          locationUrl: locationUrl,
          latitude: position.latitude,
          longitude: position.longitude,
          alertId: alertRef.id,
        );

        notificationResults.add(result);
        
        // Update alert document with contacted person
        if (result['success']) {
          await alertRef.update({
            'contactedPeople': FieldValue.arrayUnion([contact['name']]),
          });
        }
      }

      // Count successful notifications
      final int successCount = notificationResults
          .where((r) => r['success'] == true)
          .length;

      debugPrint('✅ Alert sent to $successCount/${trustedContacts.length} contacts');

      return {
        'success': true,
        'message': 'Emergency alert sent to $successCount contact(s)',
        'alertId': alertRef.id,
        'totalContacts': trustedContacts.length,
        'successfulAlerts': successCount,
        'location': address,
        'notificationResults': notificationResults,
      };
    } catch (e) {
      debugPrint('❌ Error sending emergency alert: $e');
      return {
        'success': false,
        'message': 'Failed to send alert: ${e.toString()}',
        'error': e.toString(),
      };
    }
  }

  // Send alert to individual contact
  Future<Map<String, dynamic>> _sendAlertToContact({
    required Map<String, dynamic> contact,
    required String userName,
    required String userPhone,
    required String message,
    required String location,
    required String locationUrl,
    required double latitude,
    required double longitude,
    required String alertId,
  }) async {
    try {
      final String contactName = contact['name'] ?? 'Contact';
      final String? contactPhone = contact['phone'];
      final String? contactEmail = contact['email'];

      debugPrint('📞 Sending alert to $contactName...');

      bool smsSent = false;
      bool emailSent = false;

      // Prepare SMS message
      final String smsMessage = '''
🚨 EMERGENCY ALERT 🚨

From: $userName
Phone: $userPhone

$message

📍 Location: $location

🗺️ View on map: $locationUrl

⚠️ PLEASE RESPOND IMMEDIATELY!
''';

      // Send SMS if phone number exists
      if (contactPhone != null && contactPhone.isNotEmpty) {
        smsSent = await _sendSMS(
          phoneNumber: contactPhone,
          message: smsMessage,
        );
      }

      // Send Email if email exists
      if (contactEmail != null && contactEmail.isNotEmpty) {
        emailSent = await _sendEmail(
          email: contactEmail,
          userName: userName,
          message: message,
          location: location,
          locationUrl: locationUrl,
          userPhone: userPhone,
        );
      }

      // Save notification record
      await _firestore.collection('notifications').add({
        'alertId': alertId,
        'recipientName': contactName,
        'recipientPhone': contactPhone,
        'recipientEmail': contactEmail,
        'smsSent': smsSent,
        'emailSent': emailSent,
        'sentAt': FieldValue.serverTimestamp(),
        'status': (smsSent || emailSent) ? 'sent' : 'failed',
      });

      return {
        'success': smsSent || emailSent,
        'contactName': contactName,
        'smsSent': smsSent,
        'emailSent': emailSent,
      };
    } catch (e) {
      debugPrint('❌ Error sending to contact: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Send SMS using native SMS app
  Future<bool> _sendSMS({
    required String phoneNumber,
    required String message,
  }) async {
    try {
      // Clean phone number
      final String cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
      
      // Create SMS URI
      final Uri smsUri = Uri(
        scheme: 'sms',
        path: cleanNumber,
        queryParameters: {'body': message},
      );

      // Launch SMS app
      if (await canLaunchUrl(smsUri)) {
        await launchUrl(smsUri);
        debugPrint('✅ SMS app launched for $cleanNumber');
        return true;
      } else {
        debugPrint('⚠️ Cannot launch SMS app');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error sending SMS: $e');
      return false;
    }
  }

  // Send Email (This requires a backend service)
  Future<bool> _sendEmail({
    required String email,
    required String userName,
    required String message,
    required String location,
    required String locationUrl,
    required String userPhone,
  }) async {
    try {
      // Option 1: Use mailto (opens email client)
      final Uri emailUri = Uri(
        scheme: 'mailto',
        path: email,
        query: _encodeQueryParameters(<String, String>{
          'subject': '🚨 EMERGENCY ALERT from $userName',
          'body': '''
EMERGENCY ALERT

From: $userName
Phone: $userPhone

Message: $message

Location: $location

View location on map: $locationUrl

PLEASE RESPOND IMMEDIATELY!
          ''',
        }),
      );

      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
        return true;
      }

      // Option 2: Use your backend API (recommended for production)
      // Uncomment and configure this for production use
      /*
      final response = await http.post(
        Uri.parse('YOUR_BACKEND_API_URL/send-emergency-email'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'to': email,
          'userName': userName,
          'userPhone': userPhone,
          'message': message,
          'location': location,
          'locationUrl': locationUrl,
        }),
      );

      return response.statusCode == 200;
      */

      return false;
    } catch (e) {
      debugPrint('❌ Error sending email: $e');
      return false;
    }
  }

  // Helper to encode query parameters
  String? _encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
  }

  // Get address from coordinates using Geocoding
  Future<String> _getAddressFromCoordinates(double latitude, double longitude) async {
    try {
      final List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        final Placemark place = placemarks.first;
        return '${place.street ?? ''}, ${place.locality ?? ''}, ${place.country ?? ''}';
      }
      return 'Lat: ${latitude.toStringAsFixed(6)}, Long: ${longitude.toStringAsFixed(6)}';
    } catch (e) {
      debugPrint('Error getting address: $e');
      return 'Location: $latitude, $longitude';
    }
  }

  // Generate Google Maps URL from position
  String _getGoogleMapsUrl(Position position) {
    return 'https://maps.google.com/?q=${position.latitude},${position.longitude}';
  }

  // Get alert history
  Future<List<Map<String, dynamic>>> getAlertHistory(String userId) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('emergencyAlerts')
          .where('senderId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(50)
          .get();

      return snapshot.docs
          .map((doc) => {...doc.data() as Map<String, dynamic>, 'id': doc.id})
          .toList();
    } catch (e) {
      debugPrint('❌ Error getting alert history: $e');
      return [];
    }
  }

  // Cancel active alert
  Future<bool> cancelAlert(String alertId) async {
    try {
      await _firestore.collection('emergencyAlerts').doc(alertId).update({
        'status': 'cancelled',
        'cancelledAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      debugPrint('❌ Error cancelling alert: $e');
      return false;
    }
  }
}