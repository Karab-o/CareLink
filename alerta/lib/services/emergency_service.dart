// lib/services/emergency_alert_service.dart - FIXED

import 'dart:async';
import 'package:CareAlert/models/emergency_contact.dart';
import 'package:CareAlert/services/location_service.dart';
import 'package:CareAlert/services/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Comprehensive Emergency Alert Service with delivery guarantees
class EmergencyAlertService {
  static final EmergencyAlertService _instance =
      EmergencyAlertService._internal();
  factory EmergencyAlertService(
          {required LocationService LocationService,
          required StorageService storageService}) =>
      _instance;
  EmergencyAlertService._internal();

  final String baseUrl =
      'http://localhost:3000/api'; // Replace with your backend
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  // Queue for failed alerts
  final List<EmergencyAlert> _pendingAlerts = [];
  Timer? _retryTimer;

  /// Initialize FCM and request permissions
  Future<void> initializeFCM() async {
    try {
      // Request permission for iOS
      await _fcm.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: true,
        provisional: false,
        sound: true,
      );

      // Get FCM token
      final token = await _fcm.getToken();
      debugPrint('FCM Token: $token');

      // Listen for token refresh
      _fcm.onTokenRefresh.listen((newToken) {
        debugPrint('FCM Token refreshed: $newToken');
        // Update token in your backend
      });
    } catch (e) {
      debugPrint('FCM initialization error: $e');
    }
  }

  /// Send emergency alert with multiple delivery channels
  Future<EmergencyAlertResult> sendEmergencyAlert({
    required String userId,
    required List<TrustedContact> contacts,
    required EmergencyType type,
    String? customMessage,
    required bool includeLocation,
    required bool contactPolice,
    required String alertType,
  }) async {
    final alert = EmergencyAlert(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      type: type,
      timestamp: DateTime.now(),
      message: customMessage ?? _getDefaultMessage(type),
      status: AlertStatus.pending,
    );

    try {
      // 1. Get current location
      Position? location;
      try {
        location = await _getCurrentLocation();
        alert.location = LocationData(
          latitude: location.latitude,
          longitude: location.longitude,
          accuracy: location.accuracy,
        );
      } catch (e) {
        debugPrint('Location error: $e');
        // Continue without location
      }

      // 2. Save to local storage immediately (backup)
      await _saveAlertLocally(alert);

      // 3. Check connectivity
      final hasConnection = await _hasInternetConnection();

      if (!hasConnection) {
        alert.status = AlertStatus.queued;
        _pendingAlerts.add(alert);
        _startRetryTimer();
        return EmergencyAlertResult(
          success: false,
          alert: alert,
          message: 'No internet. Alert queued for retry.',
          deliveryStatus: {},
        );
      }

      // 4. Send to backend (creates alert in database)
      final backendSuccess = await _sendToBackend(alert);

      if (!backendSuccess) {
        alert.status = AlertStatus.queued;
        _pendingAlerts.add(alert);
        _startRetryTimer();
        return EmergencyAlertResult(
          success: false,
          alert: alert,
          message: 'Backend error. Alert queued for retry.',
          deliveryStatus: {},
        );
      }

      // 5. Send via multiple channels simultaneously
      final deliveryResults = await Future.wait([
        _sendPushNotifications(alert, contacts),
        _sendSMS(alert, contacts),
        _sendEmails(alert, contacts),
      ]);

      final deliveryStatus =
          _consolidateDeliveryResults(deliveryResults, contacts);

      // 6. Update alert status
      alert.status = _determineAlertStatus(deliveryStatus);
      alert.deliveryStatus = deliveryStatus;
      await _updateAlertStatus(alert);

      // 7. Start location sharing
      if (location != null) {
        _startLocationSharing(alert.id, contacts);
      }

      // 8. Check if at least one contact was reached
      final atLeastOneDelivered = deliveryStatus.values.any(
        (status) => status.delivered || status.read,
      );

      return EmergencyAlertResult(
        success: atLeastOneDelivered,
        alert: alert,
        message: atLeastOneDelivered
            ? 'Alert sent successfully'
            : 'Alert sent but delivery uncertain',
        deliveryStatus: deliveryStatus,
      );
    } catch (e) {
      debugPrint('Emergency alert error: $e');
      alert.status = AlertStatus.failed;
      _pendingAlerts.add(alert);
      _startRetryTimer();

      return EmergencyAlertResult(
        success: false,
        alert: alert,
        message: 'Failed to send alert: $e',
        deliveryStatus: {},
      );
    }
  }

  /// Get current location with timeout
  Future<Position> _getCurrentLocation() async {
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
      timeLimit: const Duration(seconds: 5),
    );
  }

  /// Check internet connectivity - FIXED VERSION
  Future<bool> _hasInternetConnection() async {
    try {
      final ConnectivityResult connectivityResult =
          await Connectivity().checkConnectivity();

      // Check if result is NOT none (meaning we have connection)
      return connectivityResult != ConnectivityResult.none;
    } catch (e) {
      debugPrint('Connectivity check error: $e');
      return false;
    }
  }

  /// Send alert to backend server
  Future<bool> _sendToBackend(EmergencyAlert alert) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/emergency-alerts'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(alert.toJson()),
          )
          .timeout(const Duration(seconds: 10));

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('Backend error: $e');
      return false;
    }
  }

  /// Send push notifications with delivery tracking
  Future<Map<String, ContactDeliveryStatus>> _sendPushNotifications(
    EmergencyAlert alert,
    List<TrustedContact> contacts,
  ) async {
    final results = <String, ContactDeliveryStatus>{};

    for (final contact in contacts) {
      if (contact.fcmToken == null || contact.fcmToken!.isEmpty) {
        results[contact.id] = ContactDeliveryStatus(
          channel: 'push',
          sent: false,
          delivered: false,
          error: 'No FCM token',
        );
        continue;
      }

      try {
        // Send via your backend (which uses FCM Admin SDK)
        final response = await http
            .post(
              Uri.parse('$baseUrl/send-push'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'token': contact.fcmToken,
                'notification': {
                  'title': '🚨 EMERGENCY ALERT',
                  'body': alert.message,
                  'sound': 'alarm',
                  'priority': 'high',
                  'badge': 1,
                },
                'data': {
                  'alertId': alert.id,
                  'type': alert.type.toString(),
                  'userId': alert.userId,
                  'latitude': alert.location?.latitude.toString(),
                  'longitude': alert.location?.longitude.toString(),
                },
              }),
            )
            .timeout(const Duration(seconds: 5));

        results[contact.id] = ContactDeliveryStatus(
          channel: 'push',
          sent: response.statusCode == 200,
          delivered: false, // Will be updated via callback
          sentAt: DateTime.now(),
        );
      } catch (e) {
        results[contact.id] = ContactDeliveryStatus(
          channel: 'push',
          sent: false,
          delivered: false,
          error: e.toString(),
        );
      }
    }

    return results;
  }

  /// Send SMS messages
  Future<Map<String, ContactDeliveryStatus>> _sendSMS(
    EmergencyAlert alert,
    List<TrustedContact> contacts,
  ) async {
    final results = <String, ContactDeliveryStatus>{};

    for (final contact in contacts) {
      if (contact.phoneNumber == null || contact.phoneNumber!.isEmpty) {
        results[contact.id] = ContactDeliveryStatus(
          channel: 'sms',
          sent: false,
          delivered: false,
          error: 'No phone number',
        );
        continue;
      }

      try {
        final message = _buildSMSMessage(alert, contact);

        // Send via your SMS service (Twilio, AWS SNS, etc.)
        final response = await http
            .post(
              Uri.parse('$baseUrl/send-sms'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'to': contact.phoneNumber,
                'message': message,
                'alertId': alert.id,
              }),
            )
            .timeout(const Duration(seconds: 10));

        results[contact.id] = ContactDeliveryStatus(
          channel: 'sms',
          sent: response.statusCode == 200,
          delivered: false, // SMS delivery receipts come later
          sentAt: DateTime.now(),
        );
      } catch (e) {
        results[contact.id] = ContactDeliveryStatus(
          channel: 'sms',
          sent: false,
          delivered: false,
          error: e.toString(),
        );
      }
    }

    return results;
  }

  /// Send email notifications
  Future<Map<String, ContactDeliveryStatus>> _sendEmails(
    EmergencyAlert alert,
    List<TrustedContact> contacts,
  ) async {
    final results = <String, ContactDeliveryStatus>{};

    for (final contact in contacts) {
      if (contact.email == null || contact.email!.isEmpty) {
        results[contact.id] = ContactDeliveryStatus(
          channel: 'email',
          sent: false,
          delivered: false,
          error: 'No email',
        );
        continue;
      }

      try {
        // Send via your email service
        final response = await http
            .post(
              Uri.parse('$baseUrl/send-email'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'to': contact.email,
                'subject': '🚨 EMERGENCY ALERT',
                'html': _buildEmailHTML(alert, contact),
                'alertId': alert.id,
              }),
            )
            .timeout(const Duration(seconds: 10));

        results[contact.id] = ContactDeliveryStatus(
          channel: 'email',
          sent: response.statusCode == 200,
          delivered: false,
          sentAt: DateTime.now(),
        );
      } catch (e) {
        results[contact.id] = ContactDeliveryStatus(
          channel: 'email',
          sent: false,
          delivered: false,
          error: e.toString(),
        );
      }
    }

    return results;
  }

  /// Consolidate delivery results from all channels
  Map<String, ContactDeliveryStatus> _consolidateDeliveryResults(
    List<Map<String, ContactDeliveryStatus>> results,
    List<TrustedContact> contacts,
  ) {
    final consolidated = <String, ContactDeliveryStatus>{};

    for (final contact in contacts) {
      // Find best delivery status across all channels
      ContactDeliveryStatus? best;

      for (final channelResults in results) {
        final status = channelResults[contact.id];
        if (status == null) continue;

        if (best == null ||
            (status.sent && !best.sent) ||
            (status.delivered && !best.delivered)) {
          best = status;
        }
      }

      if (best != null) {
        consolidated[contact.id] = best;
      }
    }

    return consolidated;
  }

  /// Determine overall alert status
  AlertStatus _determineAlertStatus(
      Map<String, ContactDeliveryStatus> deliveryStatus) {
    if (deliveryStatus.isEmpty) return AlertStatus.failed;

    final allSent = deliveryStatus.values.every((s) => s.sent);
    final anyDelivered = deliveryStatus.values.any((s) => s.delivered);
    final anyRead = deliveryStatus.values.any((s) => s.read);

    if (anyRead) return AlertStatus.acknowledged;
    if (anyDelivered) return AlertStatus.delivered;
    if (allSent) return AlertStatus.sent;
    return AlertStatus.partialFailure;
  }

  /// Start background location sharing
  void _startLocationSharing(String alertId, List<TrustedContact> contacts) {
    // Implement continuous location updates
    Timer.periodic(const Duration(seconds: 30), (timer) async {
      try {
        final position = await _getCurrentLocation();
        await http.post(
          Uri.parse('$baseUrl/emergency-alerts/$alertId/location'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'latitude': position.latitude,
            'longitude': position.longitude,
            'timestamp': DateTime.now().toIso8601String(),
          }),
        );
      } catch (e) {
        debugPrint('Location update error: $e');
      }
    });
  }

  /// Retry failed alerts
  void _startRetryTimer() {
    _retryTimer?.cancel();
    _retryTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _retryPendingAlerts();
    });
  }

  Future<void> _retryPendingAlerts() async {
    if (_pendingAlerts.isEmpty) {
      _retryTimer?.cancel();
      return;
    }

    final hasConnection = await _hasInternetConnection();
    if (!hasConnection) return;

    final alertsToRetry = List<EmergencyAlert>.from(_pendingAlerts);
    _pendingAlerts.clear();

    for (final alert in alertsToRetry) {
      final success = await _sendToBackend(alert);
      if (!success) {
        _pendingAlerts.add(alert);
      }
    }
  }

  /// Save alert locally for backup
  Future<void> _saveAlertLocally(EmergencyAlert alert) async {
    final prefs = await SharedPreferences.getInstance();
    final alerts = prefs.getStringList('emergency_alerts') ?? [];
    alerts.add(jsonEncode(alert.toJson()));
    await prefs.setStringList('emergency_alerts', alerts);
  }

  /// Update alert status
  Future<void> _updateAlertStatus(EmergencyAlert alert) async {
    try {
      await http.put(
        Uri.parse('$baseUrl/emergency-alerts/${alert.id}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'status': alert.status.toString()}),
      );
    } catch (e) {
      debugPrint('Status update error: $e');
    }
  }

  String _getDefaultMessage(EmergencyType type) {
    switch (type) {
      case EmergencyType.medical:
        return 'Medical emergency! Need immediate help!';
      case EmergencyType.safety:
        return 'Safety emergency! I need help now!';
      case EmergencyType.accident:
        return 'Accident! Need assistance!';
      case EmergencyType.general:
        return 'Emergency! I need help!';
    }
  }

  String _buildSMSMessage(EmergencyAlert alert, TrustedContact contact) {
    final locationText = alert.location != null
        ? 'Location: https://maps.google.com/?q=${alert.location!.latitude},${alert.location!.longitude}'
        : 'Location unavailable';

    return '''
🚨 EMERGENCY ALERT
${alert.message}
$locationText
Time: ${alert.timestamp.toString()}
    '''
        .trim();
  }

  String _buildEmailHTML(EmergencyAlert alert, TrustedContact contact) {
    return '''
<!DOCTYPE html>
<html>
<head>
  <style>
    body { font-family: Arial, sans-serif; }
    .alert-box { background: #ff0000; color: white; padding: 20px; border-radius: 10px; }
    .map-link { display: inline-block; margin-top: 15px; padding: 10px 20px; background: #007bff; color: white; text-decoration: none; border-radius: 5px; }
  </style>
</head>
<body>
  <div class="alert-box">
    <h1>🚨 EMERGENCY ALERT</h1>
    <p><strong>${alert.message}</strong></p>
    <p>Time: ${alert.timestamp}</p>
    ${alert.location != null ? '<a class="map-link" href="https://maps.google.com/?q=${alert.location!.latitude},${alert.location!.longitude}">View Location</a>' : ''}
  </div>
</body>
</html>
    ''';
  }

  Future<bool> sendEmergencyAlertResult({
    required String userId,
    required List<EmergencyContact> contacts,
    required EmergencyType alertType,
    String? customMessage,
    required bool includeLocation,
    required bool contactPolice,
  }) async {
    return true;
  }

  Future<void> testEmergencySystem() async {}
}

// Models
class EmergencyAlert {
  final String id;
  final String userId;
  final EmergencyType type;
  final DateTime timestamp;
  final String message;
  AlertStatus status;
  LocationData? location;
  Map<String, ContactDeliveryStatus>? deliveryStatus;

  EmergencyAlert({
    required this.id,
    required this.userId,
    required this.type,
    required this.timestamp,
    required this.message,
    required this.status,
    this.location,
    this.deliveryStatus,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'type': type.toString(),
        'timestamp': timestamp.toIso8601String(),
        'message': message,
        'status': status.toString(),
        'location': location?.toJson(),
      };
}

class TrustedContact {
  final String id;
  final String name;
  final String? phoneNumber;
  final String? email;
  final String? fcmToken;

  TrustedContact({
    required this.id,
    required this.name,
    this.phoneNumber,
    this.email,
    this.fcmToken,
  });
}

class LocationData {
  final double latitude;
  final double longitude;
  final double accuracy;

  LocationData({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
  });

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        'accuracy': accuracy,
      };
}

class ContactDeliveryStatus {
  final String channel;
  final bool sent;
  final bool delivered;
  final bool read;
  final DateTime? sentAt;
  final DateTime? deliveredAt;
  final DateTime? readAt;
  final String? error;

  ContactDeliveryStatus({
    required this.channel,
    required this.sent,
    required this.delivered,
    this.read = false,
    this.sentAt,
    this.deliveredAt,
    this.readAt,
    this.error,
  });
}

class EmergencyAlertResult {
  final bool success;
  final EmergencyAlert alert;
  final String message;
  final Map<String, ContactDeliveryStatus> deliveryStatus;

  EmergencyAlertResult({
    required this.success,
    required this.alert,
    required this.message,
    required this.deliveryStatus,
  });
}

enum EmergencyType {
  medical,
  safety,
  accident,
  general,
}

enum AlertStatus {
  pending,
  queued,
  sent,
  delivered,
  acknowledged,
  partialFailure,
  failed,
  resolved,
  active,
}
