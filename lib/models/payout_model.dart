import 'package:cloud_firestore/cloud_firestore.dart';

class Payout {
  final String id;
  final String ownerUid;
  final String paidToName;
  final double paidAmount;
  final Timestamp? paidDate;
  final String referenceNote;

  Payout({
    required this.id,
    required this.ownerUid,
    required this.paidToName,
    required this.paidAmount,
    this.paidDate,
    required this.referenceNote,
  });

  factory Payout.fromFirestore(DocumentSnapshot doc, String docId) {
    final data = doc.data() as Map<String, dynamic>;
    return Payout(
      id: docId,
      ownerUid: data['ownerUid'] ?? '',
      paidToName: data['paidToName'] ?? '',
      paidAmount: (data['paidAmount'] ?? 0.0).toDouble(),
      paidDate: data['paidDate'] as Timestamp?,
      referenceNote: data['referenceNote'] ?? '',
    );
  }
}
