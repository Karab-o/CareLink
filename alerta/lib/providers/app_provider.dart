import 'dart:developer';

import 'package:CareAlert/models/emergency_alert.dart' hide AlertStatus;
import 'package:flutter/foundation.dart';
import '../models/user_profile.dart';
import '../models/emergency_contact.dart';
import '../models/emergency_alert.dart' hide EmergencyAlertss, AlertStatus;
import '../services/storage_service.dart';
import '../services/location_service.dart';
import '../services/emergency_service.dart';

/// Main app state provider managing user data and app state

class AppProvider extends ChangeNotifier {
  final StorageService _storageService;
  final LocationService _locationService;
  final EmergencyAlertService _emergencyService;

  AppProvider({
    required StorageService storageService,
    required LocationService locationService,
    required EmergencyAlertService emergencyService,
  })  : _storageService = storageService,
        _locationService = locationService,
        _emergencyService = emergencyService;

  // State variables
  UserProfile? _userProfile;
  List<EmergencyContact> _emergencyContacts = [];
  List<EmergencyAlert> _emergencyAlerts = [];
  bool _isLoading = false;
  String? _error;
  bool _isOnboardingCompleted = false;

  // Getters
  UserProfile? get userProfile => _userProfile;
  List<EmergencyContact> get emergencyContacts => _emergencyContacts;
  void emergencyAlerts() async => _emergencyAlerts;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isOnboardingCompleted => _isOnboardingCompleted;
  List<EmergencyContact> get activeContacts =>
      _emergencyContacts.where((contact) => contact.isActive).toList();

  /// Initialize the app provider
  Future<void> initialize() async {
    // _setLoading(true);
    try {
      await _storageService.initialize();
      await _loadUserData();
      _isOnboardingCompleted = _storageService.isOnboardingCompleted();
      _clearError();
    } catch (e) {
      _setError('Failed to initialize app: $e');
    } finally {
      // _setLoading(false);
    }
  }

  /// Load all user data from storage
  Future<void> _loadUserData() async {
    _userProfile = _storageService.getUserProfile();
    _emergencyContacts = _storageService.getEmergencyContacts();
    _emergencyAlerts =
        _storageService.getEmergencyAlerts().cast<EmergencyAlert>();
    notifyListeners();
  }

  // User Profile Methods
  Future<void> updateUserProfile(UserProfile profile) async {
    _setLoading(true);
    try {
      await _storageService.saveUserProfile(profile);
      _userProfile = profile;
      _clearError();
      notifyListeners();
    } catch (e) {
      _setError('Failed to update profile: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> createUserProfile({
    required String name,
    String? phoneNumber,
    String? email,
    String? emergencyMedicalInfo,
  }) async {
    final profile = UserProfile(
      name: name,
      phoneNumber: phoneNumber,
      email: email,
      emergencyMedicalInfo: emergencyMedicalInfo,
    );
    await updateUserProfile(profile);
  }

  // Emergency Contacts Methods
  Future<void> addEmergencyContact(EmergencyContact contact) async {
    _setLoading(true);
    try {
      await _storageService.addEmergencyContact(contact);
      _emergencyContacts.add(contact);
      _clearError();
      notifyListeners();
    } catch (e) {
      _setError('Failed to add contact: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateEmergencyContact(EmergencyContact contact) async {
    _setLoading(true);
    try {
      await _storageService.updateEmergencyContact(contact);
      final index = _emergencyContacts.indexWhere((c) => c.id == contact.id);
      if (index != -1) {
        _emergencyContacts[index] = contact;
      }
      _clearError();
      notifyListeners();
    } catch (e) {
      _setError('Failed to update contact: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteEmergencyContact(String contactId) async {
    _setLoading(true);
    try {
      await _storageService.deleteEmergencyContact(contactId);
      _emergencyContacts.removeWhere((c) => c.id == contactId);
      _clearError();
      notifyListeners();
    } catch (e) {
      _setError('Failed to delete contact: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> toggleContactActive(String contactId) async {
    final contact = _emergencyContacts.firstWhere((c) => c.id == contactId);
    final updatedContact = contact.copyWith(isActive: !contact.isActive);
    await updateEmergencyContact(updatedContact);
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

  // Emergency Alert Methods
  Future<EmergencyAlert?> sendEmergencyAlert({
    required AlertType type,
    String? message,
    bool includeLocation = true,
    bool contactPolice = false,
  }) async {
    _setLoading(true);
    try {
      // Convert AlertType to EmergencyType
      final emergencyType = _convertAlertTypeToEmergencyType(type);
      log('Converted AlertType $type to EmergencyType $emergencyType');

      final result = await _emergencyService.sendEmergencyAlertResult(
        userId: _userProfile?.id ?? 'unknown',
        contacts: _emergencyContacts,
        alertType: emergencyType,
        customMessage: message,
        includeLocation: includeLocation,
        contactPolice: contactPolice,
      );
      log('Emergency alert send result: $result');

      if (result) {
        final alert = EmergencyAlert(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          userId: _userProfile?.id ?? 'unknown',
          type: emergencyType,
          timestamp: DateTime.now(),
          message: _getDefaultMessage(emergencyType),
          status: AlertStatus.sent,
        );
        log('Created emergency alert object: $alert');
        _emergencyAlerts.insert(0, alert);
        log('Created emergency alert: $alert');
        _clearError();
        notifyListeners();
        return alert;
      } else {
        _setError('Failed to send emergency alert');
        return null;
      }
    } catch (e) {
      _setError('Failed to send emergency alert: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// Convert AlertType to EmergencyType
  EmergencyType _convertAlertTypeToEmergencyType(AlertType type) {
    switch (type) {
      case AlertType.general:
        return EmergencyType.general;
      case AlertType.medical:
        return EmergencyType.medical;
      case AlertType.safety:
        return EmergencyType.safety;
      case AlertType.violence:
        // TODO: Handle this case.
        throw UnimplementedError();
      case AlertType.harassment:
        // TODO: Handle this case.
        throw UnimplementedError();
      case AlertType.stalking:
        // TODO: Handle this case.
        throw UnimplementedError();
      case AlertType.accident:
        // TODO: Handle this case.
        throw UnimplementedError();
      case AlertType.fire:
        // TODO: Handle this case.
        throw UnimplementedError();
      case AlertType.naturalDisaster:
        // TODO: Handle this case.
        throw UnimplementedError();
    }
  }

  Future<EmergencyAlert?> sendQuickAlert() async {
    return await sendEmergencyAlert(
      type: AlertType.general,
      includeLocation: true,
    );
  }

  Future<void> testEmergencySystem() async {
    _setLoading(true);
    try {
      await _emergencyService.testEmergencySystem();
      await _loadUserData(); // Reload to get the test alert
      _clearError();
    } catch (e) {
      _setError('Failed to test emergency system: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Onboarding Methods
  Future<void> completeOnboarding() async {
    await _storageService.setOnboardingCompleted(true);
    _isOnboardingCompleted = true;
    notifyListeners();
  }

  Future<void> resetOnboarding() async {
    await _storageService.setOnboardingCompleted(false);
    _isOnboardingCompleted = false;
    notifyListeners();
  }

  // Preferences Methods
  Future<void> updateUserPreferences(UserPreferences preferences) async {
    if (_userProfile != null) {
      final updatedProfile = _userProfile!.copyWith(preferences: preferences);
      await updateUserProfile(updatedProfile);
    }
  }

  Future<void> updateSecuritySettings(SecuritySettings security) async {
    if (_userProfile != null) {
      final updatedProfile = _userProfile!.copyWith(security: security);
      await updateUserProfile(updatedProfile);
    }
  }

  // Utility Methods
  // Profile Picture Methods
  Future<void> updateProfilePicture(String? imageUrl) async {
    if (_userProfile != null) {
      final updatedProfile = _userProfile!.copyWith(profilePicture: imageUrl);
      await updateUserProfile(updatedProfile);
    }
  }

  Future<void> updateUserProfileField(String fieldName, String value) async {
    if (_userProfile == null) return;
    UserProfile updatedProfile;
    switch (fieldName) {
      case 'name':
        updatedProfile = _userProfile!.copyWith(name: value);
        break;
      case 'email':
        updatedProfile = _userProfile!.copyWith(email: value);
        break;
      case 'phoneNumber':
        updatedProfile = _userProfile!.copyWith(phoneNumber: value);
        break;
      default:
        return;
    }
    await updateUserProfile(updatedProfile);
  }

  // Theme management
  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;

  void toggleTheme(bool value) {
    _isDarkMode = value;
    notifyListeners();
  }

  Future<void> logout() async {
    // Implement logout logic here
    await clearAllData();
  }
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> clearAllData() async {
    _setLoading(true);
    try {
      await _storageService.clearAllData();
      _userProfile = null;
      _emergencyContacts.clear();
      _emergencyAlerts.clear();
      _isOnboardingCompleted = false;
      _clearError();
      notifyListeners();
    } catch (e) {
      _setError('Failed to clear data: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Location Methods
  Future<bool> checkLocationPermission() async {
    return await _locationService.hasLocationPermission();
  }

  Future<void> requestLocationPermission() async {
    await _locationService.requestLocationPermission();
  }
}
