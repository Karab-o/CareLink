// lib/services/trusted_contacts_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class TrustedContactsService with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Add trusted contact
  Future<Map<String, dynamic>> addTrustedContact({
    required String userId,
    required String name,
    required String phone,
    String? email,
    String? relationship,
  }) async {
    try {
      final Map<String, dynamic> contact = {
        'name': name.trim(),
        'phone': phone.trim(),
        'email': email?.trim(),
        'relationship': relationship ?? 'Friend',
        'addedAt': DateTime.now().toIso8601String(),
      };

      await _firestore.collection('users').doc(userId).update({
        'trustedContacts': FieldValue.arrayUnion([contact]),
      });

      debugPrint('✅ Trusted contact added: $name');

      return {
        'success': true,
        'message': '$name added as trusted contact',
        'contact': contact,
      };
    } catch (e) {
      debugPrint('❌ Error adding trusted contact: $e');
      return {
        'success': false,
        'message': 'Failed to add contact: ${e.toString()}',
      };
    }
  }

  // Get all trusted contacts
  Future<List<Map<String, dynamic>>> getTrustedContacts(String userId) async {
    try {
      final DocumentSnapshot doc = await _firestore.collection('users').doc(userId).get();
      
      if (doc.exists) {
        final Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        final List<dynamic> contacts = data['trustedContacts'] ?? [];
        return contacts.cast<Map<String, dynamic>>();
      }
      
      return [];
    } catch (e) {
      debugPrint('❌ Error getting trusted contacts: $e');
      return [];
    }
  }

  // Remove trusted contact
  Future<Map<String, dynamic>> removeTrustedContact({
    required String userId,
    required Map<String, dynamic> contact,
  }) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'trustedContacts': FieldValue.arrayRemove([contact]),
      });

      debugPrint('✅ Trusted contact removed: ${contact['name']}');

      return {
        'success': true,
        'message': '${contact['name']} removed from trusted contacts',
      };
    } catch (e) {
      debugPrint('❌ Error removing trusted contact: $e');
      return {
        'success': false,
        'message': 'Failed to remove contact: ${e.toString()}',
      };
    }
  }

  // Update trusted contact
  Future<Map<String, dynamic>> updateTrustedContact({
    required String userId,
    required Map<String, dynamic> oldContact,
    required Map<String, dynamic> newContact,
  }) async {
    try {
      // Remove old contact
      await _firestore.collection('users').doc(userId).update({
        'trustedContacts': FieldValue.arrayRemove([oldContact]),
      });

      // Add updated contact
      await _firestore.collection('users').doc(userId).update({
        'trustedContacts': FieldValue.arrayUnion([newContact]),
      });

      debugPrint('✅ Trusted contact updated: ${newContact['name']}');

      return {
        'success': true,
        'message': 'Contact updated successfully',
      };
    } catch (e) {
      debugPrint('❌ Error updating trusted contact: $e');
      return {
        'success': false,
        'message': 'Failed to update contact: ${e.toString()}',
      };
    }
  }

  // Check if contact exists
  Future<bool> contactExists(String userId, String phone) async {
    try {
      final List<Map<String, dynamic>> contacts = await getTrustedContacts(userId);
      return contacts.any((contact) => contact['phone'] == phone);
    } catch (e) {
      debugPrint('❌ Error checking contact existence: $e');
      return false;
    }
  }
}