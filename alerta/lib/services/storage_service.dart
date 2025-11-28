import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/emergency_contact.dart';
import '../models/emergency_alert.dart';
import '../models/user_profile.dart';

/// Service for local data storage using SharedPreferences
class StorageService {
  static const String _userProfileKey = 'user_profile';
  static const String _emergencyContactsKey = 'emergency_contacts';
  static const String _emergencyAlertsKey = 'emergency_alerts';
  static const String _onboardingCompletedKey = 'onboarding_completed';

  late SharedPreferences _prefs;

  /// Initialize the storage service
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // --------------------- USER PROFILE METHODS ---------------------

  Future<void> saveUserProfile(UserProfile profile) async {
    final json = jsonEncode(profile.toJson());
    await _prefs.setString(_userProfileKey, json);
  }

  UserProfile? getUserProfile() {
    final json = _prefs.getString(_userProfileKey);
    if (json == null) return null;

    try {
      final data = jsonDecode(json) as Map<String, dynamic>;
      return UserProfile.fromJson(data);
    } catch (e) {
      return null;
    }
  }

  Future<void> deleteUserProfile() async {
    await _prefs.remove(_userProfileKey);
  }

  // --------------------- EMERGENCY CONTACTS METHODS ---------------------

  Future<void> saveEmergencyContacts(List<EmergencyContact> contacts) async {
    final jsonList = contacts.map((contact) => contact.toJson()).toList();
    final json = jsonEncode(jsonList);
    await _prefs.setString(_emergencyContactsKey, json);
  }

  List<EmergencyContact> getEmergencyContacts() {
    final json = _prefs.getString(_emergencyContactsKey);
    if (json == null) return [];

    try {
      final jsonList = jsonDecode(json) as List;
      return jsonList
          .map((item) => EmergencyContact.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> addEmergencyContact(EmergencyContact contact) async {
    final contacts = getEmergencyContacts();
    contacts.add(contact);
    await saveEmergencyContacts(contacts);
  }

  Future<void> updateEmergencyContact(EmergencyContact updatedContact) async {
    final contacts = getEmergencyContacts();
    final index = contacts.indexWhere((c) => c.id == updatedContact.id);
    if (index != -1) {
      contacts[index] = updatedContact;
      await saveEmergencyContacts(contacts);
    }
  }

  Future<void> deleteEmergencyContact(String contactId) async {
    final contacts = getEmergencyContacts();
    contacts.removeWhere((c) => c.id == contactId);
    await saveEmergencyContacts(contacts);
  }

  // --------------------- EMERGENCY ALERTS METHODS ---------------------

  Future<void> saveEmergencyAlerts(List<EmergencyAlertss> alerts) async {
    final jsonList = alerts.map((alert) => alert.toJson()).toList();
    final json = jsonEncode(jsonList);
    await _prefs.setString(_emergencyAlertsKey, json);
  }

  List<EmergencyAlertss> getEmergencyAlerts() {
    final json = _prefs.getString(_emergencyAlertsKey);
    if (json == null) return [];

    try {
      final jsonList = jsonDecode(json) as List;
      return jsonList
          .map((item) => EmergencyAlertss.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> addEmergencyAlert(EmergencyAlertss alert) async {
    final alerts = getEmergencyAlerts();
    alerts.insert(0, alert); // Add to beginning for chronological order
    await saveEmergencyAlerts(alerts);
  }

  Future<void> updateEmergencyAlert(EmergencyAlertss updatedAlert) async {
    final alerts = getEmergencyAlerts();
    final index = alerts.indexWhere((a) => a.id == updatedAlert.id);
    if (index != -1) {
      alerts[index] = updatedAlert;
      await saveEmergencyAlerts(alerts);
    }
  }

  // --------------------- ONBOARDING METHODS ---------------------

  Future<void> setOnboardingCompleted(bool completed) async {
    await _prefs.setBool(_onboardingCompletedKey, completed);
  }

   Future<void> clearOnboardingStatus() async {
    await _prefs.remove('onboarding_complete');
  }

  Future<bool> getOnboardingStatus() async {
    return _prefs.getBool('onboarding_complete') ?? false;
  }

  bool isOnboardingCompleted() {
    return _prefs.getBool(_onboardingCompletedKey) ?? false;
  }

  // --------------------- UTILITY METHODS ---------------------

  Future<void> clearAllData() async {
    await _prefs.clear();
  }

  /// Export all stored data (for backup or debugging)
  Future<void> exportData() async {
    final data = {
      'userProfile': getUserProfile()?.toJson(),
      'emergencyContacts':
          getEmergencyContacts().map((c) => c.toJson()).toList(),
      'emergencyAlerts': getEmergencyAlerts().map((a) => a.toJson()).toList(),
    };

    final json = jsonEncode(data);

    // ✅ Use the variable so it’s not marked as unused
    debugPrint('Exported JSON Data: $json');

    // TODO: Implement actual export functionality (e.g., save to file or cloud)
  }
}
