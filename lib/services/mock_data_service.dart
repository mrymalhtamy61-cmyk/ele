import 'package:flutter/foundation.dart';
import '../models/subscriber.dart';
import '../models/reading.dart';

class MockDataService extends ChangeNotifier {
  // Current logged in user
  Subscriber? currentUser;

  // List of all users in the system
  final List<Subscriber> _users = [
    Subscriber(
      subscriberId: 'user_123',
      subscriberName: 'أحمد محمد',
      phone: '0500000000',
      address: 'الرياض, حي الياسمين',
      email: 'ahmed@example.com',
      meterNumber: 'M-1001',
      role: UserRole.citizen,
    ),
    Subscriber(
      subscriberId: 'emp_001',
      subscriberName: 'سعيد القحطاني',
      phone: '0511111111',
      address: 'الرياض, فرع الشمال',
      email: 'saeed@sec.example.com',
      meterNumber: 'EMP-001', // Using meterNumber as Employee ID
      role: UserRole.employee,
    ),
    Subscriber(
      subscriberId: 'admin_001',
      subscriberName: 'مدير النظام',
      phone: '0599999999',
      address: 'الرياض, المركز الرئيسي',
      email: 'admin@sec.example.com',
      meterNumber: 'ADMIN-001', // Using meterNumber as Admin ID
      role: UserRole.admin,
    ),
    // Extra user for testing
    Subscriber(
      subscriberId: 'user_456',
      subscriberName: 'فاطمة سعد',
      phone: '0522222222',
      address: 'جدة, حي الشاطئ',
      email: 'fatima@example.com',
      meterNumber: 'M-2002',
      role: UserRole.citizen,
    ),
  ];

  // List of all readings
  List<Reading> _readings = [];

  // Get readings for the current citizen, or all if admin/employee (for now just returning citizen's or all)
  List<Reading> get readings {
    if (currentUser?.role == UserRole.citizen) {
      return _readings.where((r) => r.subscriberId == currentUser?.subscriberId).toList();
    }
    return _readings;
  }
  
  // Get all users
  List<Subscriber> get allUsers => _users;
  
  // Get all citizens
  List<Subscriber> get citizens => _users.where((u) => u.role == UserRole.citizen).toList();

  MockDataService() {
    // Initialize with some past readings for Ahmed
    _readings = [
      Reading(
        readingId: 'r1',
        subscriberId: 'user_123',
        month: 3,
        year: 2026,
        previousReading: 1000,
        currentReading: 1250,
        consumption: 250,
        amount: 250 * 0.18,
        paymentStatus: 'مدفوعة',
      ),
      Reading(
        readingId: 'r2',
        subscriberId: 'user_123',
        month: 4,
        year: 2026,
        previousReading: 1250,
        currentReading: 1520,
        consumption: 270,
        amount: 270 * 0.18,
        paymentStatus: 'غير مدفوعة',
      ),
      // Readings for Fatima
      Reading(
        readingId: 'r3',
        subscriberId: 'user_456',
        month: 4,
        year: 2026,
        previousReading: 500,
        currentReading: 800,
        consumption: 300,
        amount: 300 * 0.18,
        paymentStatus: 'مدفوعة',
      ),
    ];
  }

  // Login method
  bool login(String meterOrEmpId, String phone) {
    try {
      final user = _users.firstWhere(
        (u) => u.meterNumber == meterOrEmpId && u.phone == phone,
      );
      currentUser = user;
      notifyListeners();
      return true;
    } catch (e) {
      return false; // User not found
    }
  }

  void logout() {
    currentUser = null;
    notifyListeners();
  }

  // Add new citizen
  void addCitizen({
    required String name,
    required String phone,
    required String address,
    required String email,
    String? meterNumber,
  }) {
    // Generate a random meter number for simulation if not provided
    final String meterNum = (meterNumber != null && meterNumber.isNotEmpty)
        ? meterNumber
        : 'M-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    final newCitizen = Subscriber(
      subscriberId: 'user_${DateTime.now().millisecondsSinceEpoch}',
      subscriberName: name,
      phone: phone,
      address: address,
      email: email,
      meterNumber: meterNum,
      role: UserRole.citizen,
    );
    _users.add(newCitizen);
    notifyListeners();
  }

  // Add new employee
  void addEmployee({
    required String name,
    required String phone,
    required String address,
    required String email,
    String? empId,
  }) {
    final String employeeId = (empId != null && empId.isNotEmpty)
        ? empId
        : 'EMP-${DateTime.now().millisecondsSinceEpoch.toString().substring(9)}';
    final newEmployee = Subscriber(
      subscriberId: 'emp_${DateTime.now().millisecondsSinceEpoch}',
      subscriberName: name,
      phone: phone,
      address: address,
      email: email,
      meterNumber: employeeId, // Using meterNumber field as Employee ID
      role: UserRole.employee,
    );
    _users.add(newEmployee);
    notifyListeners();
  }

  // Calculate bill based on consumption
  double calculateBill(double consumption) {
    const double unitPrice = 0.18;
    return consumption * unitPrice;
  }

  // Add new reading
  void addReadingForUser(String subscriberId, double currentReading, int month, int year) {
    // Get last reading for this specific user
    final userReadings = _readings.where((r) => r.subscriberId == subscriberId).toList();
    
    double previousReading = 0.0;
    if (userReadings.isNotEmpty) {
      final sortedReadings = List<Reading>.from(userReadings)
        ..sort((a, b) {
          if (a.year == b.year) {
            return a.month.compareTo(b.month);
          }
          return a.year.compareTo(b.year);
        });
      previousReading = sortedReadings.last.currentReading;
    }

    if (currentReading <= previousReading) {
      throw Exception('القراءة الحالية يجب أن تكون أكبر من القراءة السابقة ($previousReading)');
    }

    bool exists = userReadings.any((r) => r.month == month && r.year == year);
    if (exists) {
      throw Exception('تم إدخال قراءة لهذا الشهر مسبقاً');
    }

    double consumption = currentReading - previousReading;
    double amount = calculateBill(consumption);

    final newReading = Reading(
      readingId: DateTime.now().millisecondsSinceEpoch.toString(),
      subscriberId: subscriberId,
      month: month,
      year: year,
      previousReading: previousReading,
      currentReading: currentReading,
      consumption: consumption,
      amount: amount,
      paymentStatus: 'غير مدفوعة',
    );

    _readings.add(newReading);
    notifyListeners();
  }

  // Backward compatibility for existing UI temporarily
  void addReading(double currentReading, int month, int year) {
    if (currentUser == null) return;
    addReadingForUser(currentUser!.subscriberId, currentReading, month, year);
  }

  Reading? get latestReading {
    final userReadings = readings;
    if (userReadings.isEmpty) return null;
    final sortedReadings = List<Reading>.from(userReadings)
      ..sort((a, b) {
        if (a.year == b.year) {
          return a.month.compareTo(b.month);
        }
        return a.year.compareTo(b.year);
      });
    return sortedReadings.last;
  }
}
