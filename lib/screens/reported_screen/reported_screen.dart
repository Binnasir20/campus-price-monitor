import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/price_provider.dart';
import '../../providers/shop_provider.dart';
import '../../services/firestore_service.dart';

class ReportedScreen extends StatefulWidget {
  const ReportedScreen({super.key});

  @override
  State<ReportedScreen> createState() => _ReportedScreenState();
}

class _ReportedScreenState extends State<ReportedScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  Map<String, String> _userNames = {};

  bool _isLoadingUsers = true;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final auth = Provider.of<AuthProvider>(
      context,
      listen: false,
    );

    final priceProvider = Provider.of<PriceProvider>(
      context,
      listen: false,
    );

    final user = auth.userModel;

    if (user == null) {
      return;
    }

    // Load reports
    priceProvider.fetchPriceReportsByUniversity(
      user.university,
    );

    // Load users once
    try {
      final names = await _firestoreService.getUserNames();

      if (!mounted) return;

      setState(() {
        _userNames = names;
        _isLoadingUsers = false;
      });
    } catch (e) {
      print("Error loading users: $e");

      if (!mounted) return;

      setState(() {
        _isLoadingUsers = false;
      });
    }
  }

  Future<void> _updateStatus(
      String reportId,
      String status,
      ) async {
    final priceProvider = Provider.of<PriceProvider>(
      context,
      listen: false,
    );

    final success = await priceProvider.updatePriceReportStatus(
      reportId,
      status,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            status == 'approved'
                ? 'Report approved'
                : 'Report rejected',
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update report'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final shopProvider = Provider.of<ShopProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Reported Prices',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: Consumer<PriceProvider>(
        builder: (context, priceProvider, child) {
          final reports = priceProvider.priceReports;

          if (_isLoadingUsers) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (reports.isEmpty) {
            return const Center(
              child: Text(
                'No price reports yet',
                style: TextStyle(fontSize: 16),
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

              final userName =
                  _userNames[report.reportedBy] ?? 'Unknown user';

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
                        'Reported by: $userName',
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
                              fontWeight: FontWeight.bold,
                              color: report.status == 'approved'
                                  ? Colors.green
                                  : report.status == 'rejected'
                                  ? Colors.red
                                  : Colors.orange,
                            ),
                          ),
                        ],
                      ),

                      if (report.status == 'pending') ...[
                        const SizedBox(height: 15),

                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  _updateStatus(
                                    report.id,
                                    'approved',
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Approve'),
                              ),
                            ),

                            const SizedBox(width: 10),

                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  _updateStatus(
                                    report.id,
                                    'rejected',
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Reject'),
                              ),
                            ),
                          ],
                        ),
                      ],
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