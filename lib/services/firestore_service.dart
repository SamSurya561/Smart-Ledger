import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:smartledger/models/batch_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get _currentUser => _auth.currentUser;

  /// Returns the current user's UID.
  String? get _uid => _currentUser?.uid;

  /// Firestore collection reference for the user's batches.
  CollectionReference<Batch> get _batchesRef {
    if (_uid == null) throw Exception("User not logged in");
    return _db
        .collection('users')
        .doc(_uid)
        .collection('batches')
        .withConverter<Batch>(
          fromFirestore: (snapshot, _) => Batch.fromFirestore(snapshot),
          toFirestore: (batch, _) => batch.toFirestore(),
        );
  }

  // --- Batch Operations ---

  /// Adds a new batch to Firestore.
  Future<void> addBatch(Map<String, dynamic> data) async {
    if (_uid == null) return;

    // Add server timestamp for receivedDate and associate with user.
    final batchData = {
      ...data,
      'receivedDate': FieldValue.serverTimestamp(), // Use server-side timestamp.
      'ownerUid': _uid,
    };

    await _batchesRef.add(Batch.fromMap(batchData));
  }

  /// Retrieves a real-time stream of the user's batches.
  Stream<List<Batch>> getBatches() {
    return _batchesRef
        .orderBy('receivedDate', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => doc.data()).toList());
  }

  /// Updates an existing batch.
  Future<void> updateBatch(String batchId, Map<String, dynamic> data) async {
    await _batchesRef.doc(batchId).update(data);
  }

  /// Deletes a batch.
  Future<void> deleteBatch(String batchId) async {
    await _batchesRef.doc(batchId).delete();
  }
}
