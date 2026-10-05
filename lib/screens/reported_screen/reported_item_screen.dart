import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/price_provider.dart';
import '../../providers/shop_provider.dart';

class ReportedItemsScreen extends StatefulWidget {
  const ReportedItemsScreen({super.key});

  @override
  State<ReportedItemsScreen> createState() => _ReportedItemsScreenState();
}

class _ReportedItemsScreenState extends State<ReportedItemsScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(
        context,
        listen: false,
      );

      final priceProvider = Provider.of<PriceProvider>(
        context,
        listen: false,
      );

      final user = auth.userModel;

      if (user != null) {
        priceProvider.fetchMyPriceReports(user.uid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final shopProvider = Provider.of<ShopProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Reports',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Consumer<PriceProvider>(
        builder: (context, priceProvider, child) {
          final reports = priceProvider.myPriceReports;

          if (reports.isEmpty) {
            return const Center(
              child: Text(
                'You have not reported any prices yet.',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: reports.length,
            itemBuilder: (context, index) {
              final report = reports[index];

              String shopName = 'Unknown shop';

              for (final shop in shopProvider.shops) {
                if (shop.id == report.shopId) {
                  shopName = shop.name;
                  break;
                }
              }

              Color statusColor;

              if (report.status == 'approved') {
                statusColor = Colors.green;
              } else if (report.status == 'rejected') {
                statusColor = Colors.red;
              } else {
                statusColor = Colors.orange;
              }

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        report.itemId,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        'Shop: $shopName',
                      ),

                      const SizedBox(height: 4),

                      Text(
                        'Price: ₦${report.price.toStringAsFixed(2)}',
                      ),

                      const SizedBox(height: 4),

                      Text(
                        'Date: ${report.reportedAt.toLocal()}',
                      ),

                      const SizedBox(height: 10),

                      Row(
                        children: [
                          const Text(
                            'Status: ',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            report.status.toUpperCase(),
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}