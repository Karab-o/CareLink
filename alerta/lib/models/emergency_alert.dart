import 'package:uuid/uuid.dart';

/// Model representing an emergency alert sent by the user
class EmergencyAlertss {
  final String id;
  final AlertType type;
  final String? message;
  final AlertLocation? location;
  final List<String> contactIds; // IDs of contacts notified
  final AlertStatus status;
  final DateTime createdAt;
  final DateTime? acknowledgedAt;
  final Map<String, dynamic>? metadata;

  EmergencyAlertss({
    String? id,
    required this.type,
    this.message,
    this.location,
    this.contactIds = const [],
    this.status = AlertStatus.pending,
    DateTime? createdAt,
    this.acknowledgedAt,
    this.metadata,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  EmergencyAlertss copyWith({
    AlertType? type,
    String? message,
    AlertLocation? location,
    List<String>? contactIds,
    AlertStatus? status,
    DateTime? acknowledgedAt,
    Map<String, dynamic>? metadata,
  }) {
    return EmergencyAlertss(
      id: id,
      type: type ?? this.type,
      message: message ?? this.message,
      location: location ?? this.location,
      contactIds: contactIds ?? this.contactIds,
      status: status ?? this.status,
      createdAt: createdAt,
      acknowledgedAt: acknowledgedAt ?? this.acknowledgedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'message': message,
      'location': location?.toJson(),
      'contactIds': contactIds,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'acknowledgedAt': acknowledgedAt?.toIso8601String(),
      'metadata': metadata,
    };
  }

  factory EmergencyAlertss.fromJson(Map<String, dynamic> json) {
    return EmergencyAlertss(
      id: json['id'],
      type: AlertType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => AlertType.general,
      ),
      message: json['message'],
      location: json['location'] != null
          ? AlertLocation.fromJson(json['location'])
          : null,
      contactIds: List<String>.from(json['contactIds'] ?? []),
      status: AlertStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => AlertStatus.pending,
      ),
      createdAt: DateTime.parse(json['createdAt']),
      acknowledgedAt: json['acknowledgedAt'] != null
          ? DateTime.parse(json['acknowledgedAt'])
          : null,
      metadata: json['metadata'],
    );
  }

  @override
  String toString() {
    return 'EmergencyAlert(id: $id, type: $type, status: $status, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EmergencyAlertss && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Types of emergency alerts
enum AlertType {
  general('General Emergency'),
  medical('Medical Emergency'),
  violence('Violence/Assault'),
  harassment('Harassment'),
  stalking('Stalking'),
  accident('Accident'),
  safety('Safety Concern'),
  fire('Fire'),
  naturalDisaster('Natural Disaster');

  const AlertType(this.displayName);
  final String displayName;
}

/// Status of an emergency alert
enum AlertStatus {
  pending('Pending'),
  sent('Sent'),
  delivered('Delivered'),
  acknowledged('Acknowledged'),
  resolved('Resolved'),
  failed('Failed');

  const AlertStatus(this.displayName);
  final String displayName;
}

/// Location information for an emergency alert
class AlertLocation {
  final double latitude;
  final double longitude;
  final String? address;
  final double? accuracy;
  final DateTime timestamp;

  AlertLocation({
    required this.latitude,
    required this.longitude,
    this.address,
    this.accuracy,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'accuracy': accuracy,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory AlertLocation.fromJson(Map<String, dynamic> json) {
    return AlertLocation(
      latitude: json['latitude'].toDouble(),
      longitude: json['longitude'].toDouble(),
      address: json['address'],
      accuracy: json['accuracy']?.toDouble(),
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  @override
  String toString() {
    return 'AlertLocation(lat: $latitude, lng: $longitude, address: $address)';
  }
}