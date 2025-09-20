import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class FirestoreListPage extends StatefulWidget {
  final String collectionName;

  const FirestoreListPage({super.key, required this.collectionName});

  @override
  State<FirestoreListPage> createState() => _FirestoreListPageState();
}

class _FirestoreListPageState extends State<FirestoreListPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.collectionName.toUpperCase())),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection(widget.collectionName)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No records found"));
          }

          final docs = snapshot.data!.docs;

          docs.sort((a, b) {
            final aData = a.data() as Map<String, dynamic>?;
            final bData = b.data() as Map<String, dynamic>?;
            final aTime = (aData?['createdAt'] as Timestamp?)?.toDate();
            final bTime = (bData?['createdAt'] as Timestamp?)?.toDate();
            if (aTime == null && bTime == null) return 0;
            if (aTime == null) return 1;
            if (bTime == null) return -1;
            return bTime.compareTo(aTime);
          });

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final docId = docs[index].id;

              return ListTile(
                title: Text(data['name'] ?? 'Unnamed'),
                subtitle: Text("₹${data['amount'] ?? 0}"),
                onLongPress: () {
                  _showOptions(context, docId, data);
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddDialog(context);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showOptions(BuildContext context, String docId, Map<String, dynamic> data) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Wrap(
        children: [
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text("Edit"),
            onTap: () {
              Navigator.pop(context);
              _showAddDialog(context, docId: docId, existingData: data);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text("Delete"),
            onTap: () async {
              Navigator.pop(context);
              await FirebaseFirestore.instance
                  .collection(widget.collectionName)
                  .doc(docId)
                  .delete();
            },
          ),
        ],
      ),
    );
  }

  void _showAddDialog(BuildContext context,
      {String? docId, Map<String, dynamic>? existingData}) {
    final nameController =
    TextEditingController(text: existingData?['name'] ?? '');
    final amountController = TextEditingController(
        text: existingData?['amount']?.toString() ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(docId == null ? "Add ${widget.collectionName}" : "Edit ${widget.collectionName}"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Name"),
            ),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Amount"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              final data = {
                "name": nameController.text,
                "amount": double.tryParse(amountController.text) ?? 0,
              };

              final ref =
              FirebaseFirestore.instance.collection(widget.collectionName);

              if (docId == null) {
                await ref.add({...data, "createdAt": FieldValue.serverTimestamp()});
              } else {
                await ref.doc(docId).update(data);
              }

              if (!mounted) return;
              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }
}
