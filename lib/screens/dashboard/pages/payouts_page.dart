import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

class PayoutsPage extends StatefulWidget {
  final String batchId;
  final String ownerUid;

  const PayoutsPage({
    super.key,
    required this.batchId,
    required this.ownerUid,
  });

  @override
  State<PayoutsPage> createState() => _PayoutsPageState();
}

class _PayoutsPageState extends State<PayoutsPage> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  CollectionReference<Map<String, dynamic>> get _payoutsRef {
    return _db
        .collection('users')
        .doc(widget.ownerUid)
        .collection('batches')
        .doc(widget.batchId)
        .collection('payouts');
  }

  DocumentReference<Map<String, dynamic>> get _batchRef {
    return _db
        .collection('users')
        .doc(widget.ownerUid)
        .collection('batches')
        .doc(widget.batchId);
  }

  /// Minimal UPI link launcher
  Future<void> _launchUpi(String upiId) async {
    final uri = Uri.parse('upi://pay?pa=$upiId&pn=${Uri.encodeComponent("Receiver")}&cu=INR');

    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No UPI app found or failed to open')),
      );
    }
  }

  /// Upload proof image
  Future<String?> _uploadProof(String payoutId) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return null;

    final file = File(picked.path);
    final ref = _storage
        .ref()
        .child("payout_proofs/${widget.ownerUid}/${widget.batchId}/$payoutId.jpg");

    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

  /// Method to delete the screenshot proof
  Future<void> _deleteProof(String payoutId) async {
    try {
      final ref = _storage
          .ref()
          .child("payout_proofs/${widget.ownerUid}/${widget.batchId}/$payoutId.jpg");
      await ref.delete();

    } on FirebaseException catch (e) {
      if (e.code == 'object-not-found') {
        debugPrint("File not found in Storage, proceeding to clear Firestore link.");
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting image: ${e.message}')),
        );
        return;
      }
    }
    await _payoutsRef.doc(payoutId).update({'proofUrl': ''});
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Screenshot deleted successfully.')),
    );
  }

  /// Toggle status
  Future<void> _togglePaid(String payoutId, bool paid) async {
    await _payoutsRef.doc(payoutId).update({'status': paid ? 'paid' : 'pending'});
  }

  /// Dialog for both adding and editing a payout
  void _showPayoutDialog({QueryDocumentSnapshot<Map<String, dynamic>>? doc}) {
    final isEditing = doc != null;
    final docData = doc?.data();

    final formKey = GlobalKey<FormState>();

    final amountController = TextEditingController();
    final upiController = TextEditingController();
    final noteController = TextEditingController();
    // ✨ New controllers for bank details
    final accountNumberController = TextEditingController();
    final ifscController = TextEditingController();

    if (isEditing) {
      amountController.text = docData?['amount']?.toString() ?? '';
      upiController.text = docData?['upiId'] as String? ?? '';
      noteController.text = docData?['note'] as String? ?? '';
      // ✨ Pre-fill bank details if editing
      accountNumberController.text = docData?['accountNumber'] as String? ?? '';
      ifscController.text = docData?['ifsc'] as String? ?? '';
    }

    showDialog(
      context: context,
      builder: (context) {
        bool saving = false;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(isEditing ? 'Edit Payout' : 'Create Payout'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: amountController,
                        keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'Amount*'),
                        validator: (v) {
                          final val = double.tryParse(v ?? '');
                          if (val == null || val <= 0) {
                            return 'Enter valid amount';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: upiController,
                        decoration: const InputDecoration(labelText: 'UPI ID (Optional)'),
                        validator: (_) { // ✨ Custom validation
                          if (upiController.text.trim().isEmpty &&
                              accountNumberController.text.trim().isEmpty) {
                            return 'Provide UPI or Bank Account';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: accountNumberController,
                        keyboardType: TextInputType.number,
                        decoration:
                        const InputDecoration(labelText: 'A/C Number (Optional)'),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: ifscController,
                        textCapitalization: TextCapitalization.characters,
                        decoration: const InputDecoration(labelText: 'IFSC Code (Optional)'),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: noteController,
                        decoration: const InputDecoration(labelText: 'Note (Optional)'),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: saving
                      ? null
                      : () async {
                    if (!formKey.currentState!.validate()) return;

                    final amt = double.parse(amountController.text.trim());
                    final upi = upiController.text.trim();
                    final note = noteController.text.trim();
                    // ✨ Get new bank details
                    final accNum = accountNumberController.text.trim();
                    final ifsc = ifscController.text.trim();

                    final currentUid = _auth.currentUser?.uid;
                    if (currentUid == null) return;

                    final payload = {
                      'amount': amt,
                      'upiId': upi,
                      'note': note,
                      // ✨ Add new fields to payload
                      'accountNumber': accNum,
                      'ifsc': ifsc,
                    };

                    try {
                      setDialogState(() => saving = true);
                      if (isEditing) {
                        await _payoutsRef.doc(doc.id).update(payload);
                      } else {
                        payload.addAll({
                          'status': 'pending',
                          'proofUrl': '',
                          'createdAt': FieldValue.serverTimestamp(),
                          'createdBy': currentUid,
                        });
                        await _payoutsRef.add(payload);
                      }
                      if (!mounted) return;
                      Navigator.pop(context);
                    } finally {
                      if (mounted) setDialogState(() => saving = false);
                    }
                  },
                  child: saving
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payouts')),
      body: Column(
        children: [
          StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: _batchRef.snapshots(),
            builder: (context, snap) {
              if (!snap.hasData || !snap.data!.exists) return const SizedBox.shrink();
              final data = snap.data!.data()!;
              final name = data['receivedFromName'] ?? 'Unnamed';
              final amt = (data['receivedAmount'] ?? 0).toString();
              final note = data['referenceNote'] ?? '';
              return Card(
                margin: const EdgeInsets.all(12),
                child: ListTile(
                  leading: const Icon(Icons.folder),
                  title: Text(name),
                  subtitle: Text(note),
                  trailing: Text("₹$amt",
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              );
            },
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _payoutsRef.orderBy('createdAt', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No payouts yet'));
                }
                final docs = snapshot.data!.docs;
                return ListView.separated(
                  padding: const EdgeInsets.only(bottom: 16),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data();
                    final payoutId = doc.id;
                    final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
                    final upi = data['upiId'] as String? ?? '';
                    final note = data['note'] as String? ?? '';
                    final status = data['status'] as String? ?? 'pending';
                    final proofUrl = data['proofUrl'] as String? ?? '';
                    final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
                    // ✨ Get new bank fields from Firestore
                    final accountNumber = data['accountNumber'] as String? ?? '';
                    final ifsc = data['ifsc'] as String? ?? '';
                    final isPaid = status == 'paid';
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                      child: InkWell(
                        onLongPress: () => _showPayoutDialog(doc: doc),
                        child: ListTile(
                          leading: Icon(
                            isPaid ? Icons.check_circle : Icons.hourglass_top,
                            color: isPaid ? Colors.green : Colors.orange,
                          ),
                          title: Text("₹${amount.toStringAsFixed(2)}"),
                          subtitle: Column( // ✨ Subtitle updated to show new details
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (upi.isNotEmpty) Text('UPI: $upi'),
                              if (accountNumber.isNotEmpty) Text('A/C: $accountNumber'),
                              if (ifsc.isNotEmpty) Text('IFSC: $ifsc'),
                              if (note.isNotEmpty) Text('Note: $note'),
                              if (createdAt != null)
                                Text(createdAt.toLocal().toString().substring(0, 16),
                                    style: const TextStyle(
                                        fontSize: 12, color: Colors.grey)),
                              if (proofUrl.isNotEmpty)
                                Stack(
                                  alignment: Alignment.topRight,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8, right: 8),
                                      child: GestureDetector(
                                        onTap: () => Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) => FullScreenImageViewer(imageUrl: proofUrl),
                                          ),
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(8.0),
                                          child: Image.network(proofUrl, height: 80, width: 80, fit: BoxFit.cover),
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      width: 28, height: 28,
                                      child: IconButton(
                                        splashRadius: 14,
                                        padding: EdgeInsets.zero,
                                        iconSize: 20,
                                        icon: const Icon(Icons.cancel, color: Colors.redAccent),
                                        tooltip: 'Delete Screenshot',
                                        onPressed: () => _deleteProof(payoutId),
                                      ),
                                    )
                                  ],
                                ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.send, color: Colors.blue),
                                tooltip: 'Pay via UPI',
                                // ✨ Pay button is disabled if there's no UPI ID
                                onPressed: upi.isEmpty ? null : () => _launchUpi(upi),
                              ),
                              IconButton(
                                icon: const Icon(Icons.image, color: Colors.white70),
                                tooltip: 'Upload Proof',
                                onPressed: () async {
                                  final url = await _uploadProof(payoutId);
                                  if (url != null) {
                                    await _payoutsRef.doc(payoutId).update({'proofUrl': url});
                                  }
                                },
                              ),
                              Switch(
                                value: isPaid,
                                onChanged: (val) => _togglePaid(payoutId, val),
                                activeColor: Colors.green,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showPayoutDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}

/// Widget to display the image in full screen with zoom
class FullScreenImageViewer extends StatelessWidget {
  final String imageUrl;
  const FullScreenImageViewer({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: InteractiveViewer(
          panEnabled: false,
          boundaryMargin: const EdgeInsets.all(20),
          minScale: 0.5,
          maxScale: 4,
          child: Image.network(imageUrl),
        ),
      ),
    );
  }
}