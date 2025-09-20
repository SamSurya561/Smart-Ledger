import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/batch_model.dart';
import '../../../services/firestore_service.dart';
import '../pages/payouts_page.dart';

class BatchesPage extends StatelessWidget {
  const BatchesPage({super.key});

  void _showBatchDialog(BuildContext context,
      {Batch? existingBatch, String? batchId}) {
    final formKey = GlobalKey<FormState>();
    final nameController =
    TextEditingController(text: existingBatch?.receivedFromName ?? '');
    final amountController = TextEditingController(
        text: existingBatch?.receivedAmount.toString() ?? '');
    final noteController =
    TextEditingController(text: existingBatch?.referenceNote ?? '');

    final firestoreService =
    Provider.of<FirestoreService>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) {
        bool saving = false;
        return StatefulBuilder(builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(existingBatch == null ? "Add Batch" : "Edit Batch"),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: "From Name"),
                    validator: (v) =>
                    v == null || v.isEmpty ? "Enter name" : null,
                  ),
                  TextFormField(
                    controller: amountController,
                    decoration: const InputDecoration(labelText: "Amount"),
                    keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) =>
                    double.tryParse(v ?? '') == null ? "Enter amount" : null,
                  ),
                  TextFormField(
                    controller: noteController,
                    decoration: const InputDecoration(labelText: "Reference Note"),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: saving
                    ? null
                    : () async {
                  if (!formKey.currentState!.validate()) return;
                  setDialogState(() => saving = true);

                  final data = {
                    "receivedFromName": nameController.text.trim(),
                    "receivedAmount":
                    double.parse(amountController.text.trim()),
                    "referenceNote": noteController.text.trim(),
                  };

                  if (batchId == null) {
                    await firestoreService.addBatch(data);
                  } else {
                    await firestoreService.updateBatch(batchId, data);
                  }

                  if (context.mounted) Navigator.pop(context);
                },
                child: saving
                    ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text("Save"),
              ),
            ],
          );
        });
      },
    );
  }

  void _showBatchOptions(BuildContext context, Batch batch) {
    final firestoreService =
    Provider.of<FirestoreService>(context, listen: false);
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Wrap(
        children: [
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text("Edit"),
            onTap: () {
              Navigator.pop(ctx);
              _showBatchDialog(context,
                  existingBatch: batch, batchId: batch.id);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text("Delete"),
            onTap: () async {
              Navigator.pop(ctx);
              await firestoreService.deleteBatch(batch.id);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final firestoreService =
    Provider.of<FirestoreService>(context, listen: false);

    return StreamBuilder<List<Batch>>(
        stream: firestoreService.getBatches(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No batches found"));
          }

          final batches = snapshot.data!;
          return ListView.builder(
            itemCount: batches.length,
            itemBuilder: (context, index) {
              final batch = batches[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: ListTile(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PayoutsPage(
                          batchId: batch.id,
                          ownerUid: batch.ownerUid,
                        ),
                      ),
                    );
                  },
                  onLongPress: () => _showBatchOptions(context, batch),
                  leading: const Icon(Icons.folder),
                  title: Text(batch.receivedFromName),
                  subtitle: Text(batch.receivedDate != null
                      ? batch.receivedDate!.toDate().toString()
                      : ''),
                  trailing: Text(
                    "₹${batch.receivedAmount.toStringAsFixed(2)}",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              );
            },
          );
        },
      );
  }
}
