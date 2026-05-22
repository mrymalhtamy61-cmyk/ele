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
}
