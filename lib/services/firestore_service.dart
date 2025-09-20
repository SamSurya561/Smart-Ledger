import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/batch_model.dart';
import '../models/payout_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ------------------ BATCHES ------------------

  // Get a stream of batches for the current user
  Stream<List<Batch>> getBatches() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value([]); // Return empty stream if user is not logged in
    }

    return _db
        .collection('users')
        .doc(user.uid)
        .collection('batches')
        .orderBy('receivedDate', descending: true)
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => Batch.fromFirestore(doc, doc.id)).toList());
  }

  // Add a new batch
  Future<void> addBatch(Map<String, dynamic> batchData) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final dataToSave = {
      ...batchData,
      'ownerUid': user.uid,
      'receivedDate': FieldValue.serverTimestamp(),
    };

    await _db.collection('users').doc(user.uid).collection('batches').add(dataToSave);
  }

  // ✅ Update existing batch
  Future<void> updateBatch(String batchId, Map<String, dynamic> batchData) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _db
        .collection('users')
        .doc(user.uid)
        .collection('batches')
        .doc(batchId)
        .update(batchData);
  }

  // ✅ Delete batch
  Future<void> deleteBatch(String batchId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _db
        .collection('users')
        .doc(user.uid)
        .collection('batches')
        .doc(batchId)
        .delete();
  }

  // ------------------ PAYOUTS ------------------

  // Get live payouts (global for now, not batch-scoped)
  Stream<List<Payout>> getPayouts() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _db
        .collection('users')
        .doc(user.uid)
        .collection('payouts')
        .orderBy('paidDate', descending: true)
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => Payout.fromFirestore(doc, doc.id)).toList());
  }

  // Add payout
  Future<void> addPayout(Map<String, dynamic> payoutData) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final dataToSave = {
      ...payoutData,
      'ownerUid': user.uid,
      'paidDate': FieldValue.serverTimestamp(),
    };

    await _db.collection('users').doc(user.uid).collection('payouts').add(dataToSave);
  }
}
