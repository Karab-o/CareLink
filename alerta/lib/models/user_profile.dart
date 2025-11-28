import 'package:uuid/uuid.dart';

/// Model representing the user's profile and preferences
class UserProfile {
  final String id;
  final String? name;
  final String? phoneNumber;
  final String? email;
  final String? profilePicture; // ✅ ADD THIS LINE
  final DateTime? dateOfBirth;
  final String? emergencyMedicalInfo;
  final UserPreferences preferences;
  final SecuritySettings security;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserProfile({
    String? id,
    this.name,
    this.phoneNumber,
    this.email,
    this.profilePicture, // ✅ ADD THIS LINE
    this.dateOfBirth,
    this.emergencyMedicalInfo,
    UserPreferences? preferences,
    SecuritySettings? security,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        preferences = preferences ?? UserPreferences(),
        security = security ?? SecuritySettings(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  UserProfile copyWith({
    String? name,
    String? phoneNumber,
    String? email,
    String? profilePicture, // ✅ ADD THIS LINE
    DateTime? dateOfBirth,
    String? emergencyMedicalInfo,
    UserPreferences? preferences,
    SecuritySettings? security,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      profilePicture: profilePicture ?? this.profilePicture, // ✅ ADD THIS LINE
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      emergencyMedicalInfo: emergencyMedicalInfo ?? this.emergencyMedicalInfo,
      preferences: preferences ?? this.preferences,
      security: security ?? this.security,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phoneNumber': phoneNumber,
      'email': email,
      'profilePicture': profilePicture, // ✅ ADD THIS LINE
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'emergencyMedicalInfo': emergencyMedicalInfo,
      'preferences': preferences.toJson(),
      'security': security.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      name: json['name'],
      phoneNumber: json['phoneNumber'],
      email: json['email'],
      profilePicture: json['profilePicture'], // ✅ ADD THIS LINE
      dateOfBirth: json['dateOfBirth'] != null
          ? DateTime.parse(json['dateOfBirth'])
          : null,
      emergencyMedicalInfo: json['emergencyMedicalInfo'],
      preferences: UserPreferences.fromJson(json['preferences'] ?? {}),
      security: SecuritySettings.fromJson(json['security'] ?? {}),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}

/// User preferences for notifications and app behavior
class UserPreferences {
  final bool enableLocationSharing;
  final bool autoContactPolice;
  final bool enableVibration;
  final bool enableSoundAlerts;
  final bool enablePushNotifications;
  final int alertDelaySeconds;
  final bool shareLocationWithContacts;
  final bool enableQuickDial;

  UserPreferences({
    this.enableLocationSharing = true,
    this.autoContactPolice = false,
    this.enableVibration = true,
    this.enableSoundAlerts = true,
    this.enablePushNotifications = true,
    this.alertDelaySeconds = 10,
    this.shareLocationWithContacts = true,
    this.enableQuickDial = true,
  });

  UserPreferences copyWith({
    bool? enableLocationSharing,
    bool? autoContactPolice,
    bool? enableVibration,
    bool? enableSoundAlerts,
    bool? enablePushNotifications,
    int? alertDelaySeconds,
    bool? shareLocationWithContacts,
    bool? enableQuickDial,
  }) {
    return UserPreferences(
      enableLocationSharing: enableLocationSharing ?? this.enableLocationSharing,
      autoContactPolice: autoContactPolice ?? this.autoContactPolice,
      enableVibration: enableVibration ?? this.enableVibration,
      enableSoundAlerts: enableSoundAlerts ?? this.enableSoundAlerts,
      enablePushNotifications: enablePushNotifications ?? this.enablePushNotifications,
      alertDelaySeconds: alertDelaySeconds ?? this.alertDelaySeconds,
      shareLocationWithContacts: shareLocationWithContacts ?? this.shareLocationWithContacts,
      enableQuickDial: enableQuickDial ?? this.enableQuickDial,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enableLocationSharing': enableLocationSharing,
      'autoContactPolice': autoContactPolice,
      'enableVibration': enableVibration,
      'enableSoundAlerts': enableSoundAlerts,
      'enablePushNotifications': enablePushNotifications,
      'alertDelaySeconds': alertDelaySeconds,
      'shareLocationWithContacts': shareLocationWithContacts,
      'enableQuickDial': enableQuickDial,
    };
  }

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      enableLocationSharing: json['enableLocationSharing'] ?? true,
      autoContactPolice: json['autoContactPolice'] ?? false,
      enableVibration: json['enableVibration'] ?? true,
      enableSoundAlerts: json['enableSoundAlerts'] ?? true,
      enablePushNotifications: json['enablePushNotifications'] ?? true,
      alertDelaySeconds: json['alertDelaySeconds'] ?? 10,
      shareLocationWithContacts: json['shareLocationWithContacts'] ?? true,
      enableQuickDial: json['enableQuickDial'] ?? true,
    );
  }
}

/// Security settings for app access
class SecuritySettings {
  final bool requirePinOnStartup;
  final bool enableBiometricAuth;
  final String? pinHash;
  final bool enableStealthMode;
  final bool enableFakeCallFeature;
  final int autoLockMinutes;

  SecuritySettings({
    this.requirePinOnStartup = false,
    this.enableBiometricAuth = false,
    this.pinHash,
    this.enableStealthMode = false,
    this.enableFakeCallFeature = false,
    this.autoLockMinutes = 5,
  });

  SecuritySettings copyWith({
    bool? requirePinOnStartup,
    bool? enableBiometricAuth,
    String? pinHash,
    bool? enableStealthMode,
    bool? enableFakeCallFeature,
    int? autoLockMinutes,
  }) {
    return SecuritySettings(
      requirePinOnStartup: requirePinOnStartup ?? this.requirePinOnStartup,
      enableBiometricAuth: enableBiometricAuth ?? this.enableBiometricAuth,
      pinHash: pinHash ?? this.pinHash,
      enableStealthMode: enableStealthMode ?? this.enableStealthMode,
      enableFakeCallFeature: enableFakeCallFeature ?? this.enableFakeCallFeature,
      autoLockMinutes: autoLockMinutes ?? this.autoLockMinutes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'requirePinOnStartup': requirePinOnStartup,
      'enableBiometricAuth': enableBiometricAuth,
      'pinHash': pinHash,
      'enableStealthMode': enableStealthMode,
      'enableFakeCallFeature': enableFakeCallFeature,
      'autoLockMinutes': autoLockMinutes,
    };
  }

  factory SecuritySettings.fromJson(Map<String, dynamic> json) {
    return SecuritySettings(
      requirePinOnStartup: json['requirePinOnStartup'] ?? false,
      enableBiometricAuth: json['enableBiometricAuth'] ?? false,
      pinHash: json['pinHash'],
      enableStealthMode: json['enableStealthMode'] ?? false,
      enableFakeCallFeature: json['enableFakeCallFeature'] ?? false,
      autoLockMinutes: json['autoLockMinutes'] ?? 5,
    );
  }
}