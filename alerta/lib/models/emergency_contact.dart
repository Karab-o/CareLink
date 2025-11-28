import 'package:uuid/uuid.dart';

/// Model representing an emergency contact
class EmergencyContact {
  final String id;
  final String name;
  final String phoneNumber;
  final String? email;
  final ContactRelationship relationship;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  EmergencyContact({
    String? id,
    required this.name,
    required this.phoneNumber,
    this.email,
    required this.relationship,
    this.isActive = true,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  EmergencyContact copyWith({
    String? name,
    String? phoneNumber,
    String? email,
    ContactRelationship? relationship,
    bool? isActive,
    DateTime? updatedAt,
  }) {
    return EmergencyContact(
      id: id,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      relationship: relationship ?? this.relationship,
      isActive: isActive ?? this.isActive,
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
      'relationship': relationship.name,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    return EmergencyContact(
      id: json['id'],
      name: json['name'],
      phoneNumber: json['phoneNumber'],
      email: json['email'],
      relationship: ContactRelationship.values.firstWhere(
        (e) => e.name == json['relationship'],
        orElse: () => ContactRelationship.other,
      ),
      isActive: json['isActive'] ?? true,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  @override
  String toString() {
    return 'EmergencyContact(id: $id, name: $name, phoneNumber: $phoneNumber, relationship: $relationship)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EmergencyContact && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

enum ContactRelationship {
  family('Family'),
  friend('Friend'),
  colleague('Colleague'),
  neighbor('Neighbor'),
  other('Other');

  const ContactRelationship(this.displayName);
  final String displayName;
}