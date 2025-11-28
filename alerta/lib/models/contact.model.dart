class Contact {
  String? name;
  String? email;
  String? phone;
  String? relationship;

  Contact({this.name, this.email, this.phone, this.relationship});

  factory Contact.fromJson(Map<String, dynamic> json) {
    return Contact(
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
      relationship: json['relationship'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'relationship': relationship,
    };
  }
}
