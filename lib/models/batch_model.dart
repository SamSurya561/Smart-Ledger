import 'package:cloud_firestore/cloud_firestore.dart';

class Batch {
  final String id;
  final String ownerUid;
  final String receivedFromName;
  final double receivedAmount;
  final Timestamp? receivedDate;
  final String referenceNote;
  final int transactionCount;

  Batch({
    required this.id,
    required this.ownerUid,
    required this.receivedFromName,
    required this.receivedAmount,
    this.receivedDate,
    required this.referenceNote,
    required this.transactionCount,
  });

  // This factory is now corrected to accept the document ID
  factory Batch.fromFirestore(DocumentSnapshot doc, String docId) {
    Map data = doc.data() as Map<String, dynamic>;
    return Batch(
      id: docId, // Use the passed document ID
      ownerUid: data['ownerUid'] ?? '',
      receivedFromName: data['receivedFromName'] ?? '',
      receivedAmount: (data['receivedAmount'] ?? 0.0).toDouble(),
      receivedDate: data['receivedDate'] as Timestamp?,
      referenceNote: data['referenceNote'] ?? '',
      transactionCount: data['transactionCount'] ?? 0,
    );
  }
}

