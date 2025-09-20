import 'package:flutter/material.dart';
import '../services/firestore_service.dart';

void showAddBatchDialog(BuildContext context) {
  // Keys and controllers to manage the form state and input
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final amountController = TextEditingController();
  final noteController = TextEditingController();
  final firestoreService = FirestoreService();

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Add New Batch'),
        // Use a Form widget for input validation
        content: Form(
          key: formKey,
          child: SingleChildScrollView( // Prevents overflow if keyboard appears
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Sender Name'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a name';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: amountController,
                  decoration: const InputDecoration(labelText: 'Amount Received'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter an amount';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: noteController,
                  decoration: const InputDecoration(labelText: 'Reference Note (Optional)'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          // Cancel button dismisses the dialog
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          // Save button validates and saves the data
          FilledButton(
            onPressed: () {
              // Check if all form fields are valid
              if (formKey.currentState!.validate()) {
                // Create a Map object with the data
                final batchData = {
                  'receivedFromName': nameController.text,
                  'receivedAmount': double.tryParse(amountController.text) ?? 0.0,
                  'referenceNote': noteController.text,
                  'transactionCount': 0, // A default value for our new field
                };
                // Call the service to add the data to Firestore
                firestoreService.addBatch(batchData);
                // Close the dialog
                Navigator.of(context).pop();
              }
            },
            child: const Text('Save'),
          ),
        ],
      );
    },
  );
}

