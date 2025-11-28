// this is user.model.dart file
import 'dart:convert';

import 'package:CareAlert/models/contact.model.dart';
import 'package:CareAlert/models/user.model.dart';

class User {
  String? id;
  String? fullName;
  String? email;
  String? phoneNumber;
  String? password;
  String? dateOfBirth;  
  String? emergencyMedicalInfo;
  List<Contact>? trustedContacts;

  User({
    this.id,
    this.fullName,
    this.email,
    this.phoneNumber,
    this.password,
    this.trustedContacts,
    this.dateOfBirth,  
    this.emergencyMedicalInfo,
  });

  // From JSON factory
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'],
      fullName: json['fullName'],
      email: json['email'],
      phoneNumber: json['phoneNumber'],
      dateOfBirth: json['dateOfBirth'],
      emergencyMedicalInfo: json['emergencyMedicalInfo'],
      trustedContacts: List<Contact>.from(
        json['trustedContacts'].map(
          (x) => Contact.fromJson(x),
        ),
      ),
    );
  }

  // Sign up JSON representation
  String toSignUpJson() {
    return jsonEncode({
      'fullName': fullName,
      'email': email,
      'phoneNumber': phoneNumber,
      'password': password,
      'dateOfBirth': dateOfBirth,
      'emergencyMedicalInfo': emergencyMedicalInfo,
    });
  }

  // Sign in JSON representation
  String toSignInJson() {
    return jsonEncode({
      'email': email,
      'password': password,
    });
  }

  // To JSON method
  String toJson() {
    final Map<String, dynamic> data = {
      '_id': id,
      'fullName': fullName,
      'email': email,
      'phoneNumber': phoneNumber,
      'dateOfBirth': dateOfBirth,
      'emergencyMedicalInfo': emergencyMedicalInfo,
      'trustedContacts': trustedContacts?.map((x) => x.toJson()).toList(),
    };
    return jsonEncode(data);
  }
}
