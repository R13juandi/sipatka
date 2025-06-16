enum PaymentStatus { paid, pending, unpaid, overdue }

class Payment {
  final String id;
  final String studentId;
  final String month;
  final int year;
  final double amount;
  final DateTime dueDate;
  final DateTime? paidDate;
  final String? proofUrl;
  final PaymentStatus status;

  // Data tambahan dari join
  final String? studentName;
  final String? parentName;

  Payment({
    required this.id,
    required this.studentId,
    required this.month,
    required this.year,
    required this.amount,
    required this.dueDate,
    this.paidDate,
    this.proofUrl,
    required this.status,
    this.studentName,
    this.parentName,
  });

  factory Payment.fromMap(Map<String, dynamic> map) {
    PaymentStatus currentStatus;
    String statusString = map['status'] ?? 'unpaid';

    if (statusString == 'paid') {
      currentStatus = PaymentStatus.paid;
    } else if (statusString == 'pending') {
      currentStatus = PaymentStatus.pending;
    } else { // unpaid
      if (DateTime.parse(map['due_date']).isBefore(DateTime.now().subtract(const Duration(days: 1)))) {
        currentStatus = PaymentStatus.overdue;
      } else {
        currentStatus = PaymentStatus.unpaid;
      }
    }

    // Mengambil data siswa jika ada (dari join)
    final profileData = map['students']?['profiles'];

    return Payment(
      id: map['id'],
      studentId: map['student_id'],
      month: map['month'],
      year: map['year'],
      amount: (map['amount'] as num).toDouble(),
      dueDate: DateTime.parse(map['due_date']),
      paidDate: map['paid_date'] != null ? DateTime.parse(map['paid_date']) : null,
      proofUrl: map['proof_of_payment_url'],
      status: currentStatus,
      studentName: map['students']?['full_name'],
      parentName: profileData?['full_name'],
    );
  }
}