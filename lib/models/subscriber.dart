import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { citizen, employee, admin }

class Subscriber {
  final String subscriberId;
  final String subscriberName;
  final String phone;
  final String address;
  final String email;
  final String meterNumber;
  final UserRole role;

  Subscriber({
    required this.subscriberId,
    required this.subscriberName,
    required this.phone,
    required this.address,
    required this.email,
    required this.meterNumber,
    this.role = UserRole.citizen,
  });

  factory Subscriber.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    
    UserRole parsedRole = UserRole.citizen;
    if (data['role'] == 'employee') {
      parsedRole = UserRole.employee;
    } else if (data['role'] == 'admin') {
      parsedRole = UserRole.admin;
    }

    return Subscriber(
      subscriberId: doc.id,
      subscriberName: data['subscriberName'] ?? '',
      phone: data['phone'] ?? '',
      address: data['address'] ?? '',
      email: data['email'] ?? '',
      meterNumber: data['meterNumber'] ?? '',
      role: parsedRole,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'subscriberName': subscriberName,
      'phone': phone,
      'address': address,
      'email': email,
      'meterNumber': meterNumber,
      'role': role.name,
    };
  }
}
