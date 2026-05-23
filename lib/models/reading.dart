import 'package:cloud_firestore/cloud_firestore.dart';

class Reading {
  final String readingId;
  final String subscriberId;
  final int month;
  final int year;
  final double previousReading;
  final double currentReading;
  final double consumption;
  final double amount;
  final String paymentStatus;

  Reading({
    required this.readingId,
    required this.subscriberId,
    required this.month,
    required this.year,
    required this.previousReading,
    required this.currentReading,
    required this.consumption,
    required this.amount,
    required this.paymentStatus,
  });

  factory Reading.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return Reading(
      readingId: doc.id,
      subscriberId: data['subscriberId'] ?? '',
      month: data['month'] ?? 1,
      year: data['year'] ?? 2026,
      previousReading: (data['previousReading'] ?? 0).toDouble(),
      currentReading: (data['currentReading'] ?? 0).toDouble(),
      consumption: (data['consumption'] ?? 0).toDouble(),
      amount: (data['amount'] ?? 0).toDouble(),
      paymentStatus: data['paymentStatus'] ?? 'غير مدفوعة',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'subscriberId': subscriberId,
      'month': month,
      'year': year,
      'previousReading': previousReading,
      'currentReading': currentReading,
      'consumption': consumption,
      'amount': amount,
      'paymentStatus': paymentStatus,
    };
  }
}
