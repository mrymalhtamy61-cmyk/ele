import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/subscriber.dart';
import '../models/reading.dart';

class AppNotification {
  final String title;
  final String body;
  final DateTime time;
  bool isRead;

  AppNotification({
    required this.title,
    required this.body,
    required this.time,
    this.isRead = false,
  });
}

class FirestoreService extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Subscriber? currentUser;

  List<Subscriber> _users = [];
  List<Reading> _readings = [];
  bool _isFirstReadingsLoad = true;

  // In-app notifications
  final List<AppNotification> _notifications = [];
  List<AppNotification> get notifications => _notifications;
  int get unreadNotificationsCount => _notifications.where((n) => !n.isRead).length;

  void markAllNotificationsRead() {
    for (var n in _notifications) {
      n.isRead = true;
    }
    notifyListeners();
  }

  void clearNotifications() {
    _notifications.clear();
    notifyListeners();
  }

  FirestoreService() {
    _listenToUsers();
    _listenToReadings();
  }

  void _listenToUsers() {
    _db.collection('users').snapshots().listen((snapshot) {
      _users = snapshot.docs.map((doc) => Subscriber.fromFirestore(doc)).toList();
      notifyListeners();
    }, onError: (e) {
      debugPrint("Error listening to users: $e");
    });
  }

  void _listenToReadings() {
    _db.collection('readings').snapshots().listen((snapshot) {
      final newReadings = snapshot.docs.map((doc) => Reading.fromFirestore(doc)).toList();
      
      if (!_isFirstReadingsLoad && currentUser != null) {
        _checkForNewNotifications(newReadings);
      }
      
      _readings = newReadings;
      _isFirstReadingsLoad = false;
      notifyListeners();
    }, onError: (e) {
      debugPrint("Error listening to readings: $e");
    });
  }

  void _checkForNewNotifications(List<Reading> newReadings) {
    if (currentUser == null) return;

    // Check for new readings added for this citizen
    if (currentUser!.role == UserRole.citizen) {
      for (var newR in newReadings) {
        if (newR.subscriberId != currentUser!.subscriberId) continue;
        
        final existsInOld = _readings.any((old) => old.readingId == newR.readingId);
        if (!existsInOld) {
          _notifications.insert(0, AppNotification(
            title: '📄 فاتورة جديدة',
            body: 'تم تسجيل قراءة جديدة لشهر ${newR.month}/${newR.year}. المبلغ المستحق: ${newR.amount.toStringAsFixed(0)} ر.ي. يرجى السداد خلال ٢٤ ساعة لتجنب قطع التيار.',
            time: DateTime.now(),
          ));
        }

        // Check for payment status change
        final oldReading = _readings.where((old) => old.readingId == newR.readingId).firstOrNull;
        if (oldReading != null && oldReading.paymentStatus != newR.paymentStatus) {
          if (newR.paymentStatus == 'مدفوعة') {
            _notifications.insert(0, AppNotification(
              title: '✅ تم السداد',
              body: 'تم تأكيد سداد فاتورة شهر ${newR.month}/${newR.year} بمبلغ ${newR.amount.toStringAsFixed(0)} ر.ي بنجاح. شكراً لك.',
              time: DateTime.now(),
            ));
          }
        }
      }
    }
  }

  List<Reading> get readings {
    if (currentUser?.role == UserRole.citizen) {
      return _readings.where((r) => r.subscriberId == currentUser?.subscriberId).toList();
    }
    return _readings;
  }
  
  List<Subscriber> get allUsers => _users;
  List<Subscriber> get citizens => _users.where((u) => u.role == UserRole.citizen).toList();
  List<Subscriber> get employees => _users.where((u) => u.role == UserRole.employee).toList();
  List<Subscriber> get admins => _users.where((u) => u.role == UserRole.admin).toList();

  Future<bool> login(String meterOrEmpId, String phone) async {
    try {
      final user = _users.firstWhere(
        (u) => u.meterNumber == meterOrEmpId && u.phone == phone,
      );
      currentUser = user;
      _isFirstReadingsLoad = true;
      _notifications.clear();
      notifyListeners();
      // Mark as loaded after a short delay so first snapshot doesn't trigger notifications
      Future.delayed(const Duration(seconds: 2), () {
        _isFirstReadingsLoad = false;
      });
      return true;
    } catch (e) {
      // Fallback: check firestore directly if not cached yet
      try {
        final querySnapshot = await _db.collection('users')
            .where('meterNumber', isEqualTo: meterOrEmpId)
            .where('phone', isEqualTo: phone)
            .get();
        if (querySnapshot.docs.isNotEmpty) {
          currentUser = Subscriber.fromFirestore(querySnapshot.docs.first);
          _isFirstReadingsLoad = true;
          _notifications.clear();
          notifyListeners();
          Future.delayed(const Duration(seconds: 2), () {
            _isFirstReadingsLoad = false;
          });
          return true;
        }
      } catch (e) {
        debugPrint("Login error: $e");
      }
      return false; 
    }
  }

  void logout() {
    currentUser = null;
    _notifications.clear();
    _isFirstReadingsLoad = true;
    notifyListeners();
  }

  Future<void> addCitizen({
    required String name,
    required String phone,
    required String address,
    required String email,
    String? meterNumber,
  }) async {
    final String meterNum = (meterNumber != null && meterNumber.isNotEmpty)
        ? meterNumber
        : 'M-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    
    final newCitizen = Subscriber(
      subscriberId: '', // Handled by firestore
      subscriberName: name,
      phone: phone,
      address: address,
      email: email,
      meterNumber: meterNum,
      role: UserRole.citizen,
    );

    await _db.collection('users').add(newCitizen.toFirestore());
  }

  Future<void> addEmployee({
    required String name,
    required String phone,
    required String address,
    required String email,
    String? empId,
  }) async {
    final String employeeId = (empId != null && empId.isNotEmpty)
        ? empId
        : 'EMP-${DateTime.now().millisecondsSinceEpoch.toString().substring(9)}';
        
    final newEmployee = Subscriber(
      subscriberId: '', 
      subscriberName: name,
      phone: phone,
      address: address,
      email: email,
      meterNumber: employeeId,
      role: UserRole.employee,
    );

    await _db.collection('users').add(newEmployee.toFirestore());
  }

  double calculateBill(double consumption) {
    const double unitPrice = 100.0;
    return consumption * unitPrice;
  }

  Future<void> addReadingForUser(String subscriberId, double currentReading, int month, int year) async {
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
      readingId: '',
      subscriberId: subscriberId,
      month: month,
      year: year,
      previousReading: previousReading,
      currentReading: currentReading,
      consumption: consumption,
      amount: amount,
      paymentStatus: 'غير مدفوعة',
    );

    await _db.collection('readings').add(newReading.toFirestore());
  }

  Future<void> addReading(double currentReading, int month, int year) async {
    if (currentUser == null) return;
    await addReadingForUser(currentUser!.subscriberId, currentReading, month, year);
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

  Future<void> updatePaymentStatus(String readingId, String newStatus) async {
    await _db.collection('readings').doc(readingId).update({
      'paymentStatus': newStatus,
    });
  }
}
