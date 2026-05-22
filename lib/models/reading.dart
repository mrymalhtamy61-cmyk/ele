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
}
