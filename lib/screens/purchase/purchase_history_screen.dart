import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../model/purchase_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/purchase_provider.dart';

class PurchaseHistoryScreen extends StatefulWidget {
  const PurchaseHistoryScreen({super.key});

  @override
  State<PurchaseHistoryScreen> createState() =>
      _PurchaseHistoryScreenState();
}

class _PurchaseHistoryScreenState extends State<PurchaseHistoryScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().userModel;

      if (user != null) {
        context.read<PurchaseProvider>().fetchMyPurchases(user.uid);
      }
    });
  }

  String _formatDate(DateTime date) {
    final localDate = date.toLocal();

    return '${localDate.day.toString().padLeft(2, '0')}/'
        '${localDate.month.toString().padLeft(2, '0')}/'
        '${localDate.year} '
        '${localDate.hour.toString().padLeft(2, '0')}:'
        '${localDate.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PurchaseProvider>();
    final purchases = provider.myPurchases;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Purchase History'),
      ),
      body: provider.isLoading && purchases.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : provider.errorMessage != null && purchases.isEmpty
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 48,
                color: Colors.red,
              ),
              const SizedBox(height: 12),
              Text(
                provider.errorMessage!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  final user =
                      context.read<AuthProvider>().userModel;

                  if (user != null) {
                    context
                        .read<PurchaseProvider>()
                        .fetchMyPurchases(user.uid);
                  }
                },
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
      )
          : purchases.isEmpty
          ? const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.receipt_long_outlined,
                size: 64,
                color: Colors.grey,
              ),
              SizedBox(height: 12),
              Text(
                'No purchases yet',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Your completed demo purchases will appear here.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: purchases.length,
        itemBuilder: (context, index) {
          final purchase = purchases[index];

          return _PurchaseCard(
            purchase: purchase,
            formattedDate: _formatDate(
              purchase.purchasedAt,
            ),
          );
        },
      ),
    );
  }
}

class _PurchaseCard extends StatelessWidget {
  final Purchase purchase;
  final String formattedDate;

  const _PurchaseCard({
    required this.purchase,
    required this.formattedDate,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  child: Icon(Icons.shopping_bag_outlined),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    purchase.itemName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 20,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _DetailRow(
              label: 'Shop',
              value: purchase.shopName,
            ),
            _DetailRow(
              label: 'Quantity',
              value: '${purchase.quantity} ${purchase.unit}',
            ),
            _DetailRow(
              label: 'Unit price',
              value: '₦${purchase.unitPrice.toStringAsFixed(2)}',
            ),
            const Divider(height: 24),
            _DetailRow(
              label: 'Total',
              value: '₦${purchase.totalAmount.toStringAsFixed(2)}',
              isBold: true,
            ),
            const SizedBox(height: 8),
            _DetailRow(
              label: 'Payment',
              value: 'Demo payment',
            ),
            _DetailRow(
              label: 'Date',
              value: formattedDate,
            ),
            const SizedBox(height: 8),
            Text(
              'Reference: ${purchase.paymentReference}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;

  const _DetailRow({
    required this.label,
    required this.value,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}