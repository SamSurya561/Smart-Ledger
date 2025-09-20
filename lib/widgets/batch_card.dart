import 'package:flutter/material.dart';
import '../models/batch_model.dart';

class BatchCard extends StatelessWidget {
  final Batch batch;
  final int batchNumber;

  const BatchCard({
    super.key,
    required this.batch,
    required this.batchNumber,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Batch $batchNumber',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    batch.receivedFromName,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${batch.transactionCount} transactions',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            // Placeholder for the image
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                // Use a subtle color from the theme
                color: Theme.of(context).colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              // Use a relevant icon
              child: Icon(
                Icons.receipt_long,
                color: Theme.of(context).colorScheme.onSecondaryContainer,
              ),
            )
          ],
        ),
      ),
    );
  }
}

