import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../model/shop_model.dart';
import '../../providers/price_provider.dart';
import 'package:intl/intl.dart';
import 'report_price_screen.dart'; // 1. IMPORT THE REPORT SCREEN

class ShopDetailScreen extends StatelessWidget {
  final Shop shop;

  const ShopDetailScreen({super.key, required this.shop});

  @override
  Widget build(BuildContext context) {
    final priceProv = Provider.of<PriceProvider>(context);

    // Filter prices belonging to THIS shop using the shop.id
    final shopPrices = priceProv.prices.where((p) => p.shopId == shop.id).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(shop.name),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // --- SHOP INFO HEADER ---
          _buildShopHeader(),

          // --- SECTION TITLE ---
          Padding(
            padding: const EdgeInsets.all(15.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Items & Prices",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  "${shopPrices.length} Items",
                  style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),

          // --- LIST OF PRICES ---
          Expanded(
            child: shopPrices.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              itemCount: shopPrices.length,
              itemBuilder: (context, index) {
                final price = shopPrices[index];

                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.orange.shade100,
                      child: const Icon(Icons.fastfood, color: Colors.orange, size: 20),
                    ),
                    title: Text(
                      price.itemId, // The Item Name
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      "Updated: ${DateFormat('MMM d, yyyy').format(price.updatedAt)}",
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                    trailing: Text(
                      "₦${price.price.toStringAsFixed(0)}",
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.green),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),

      // 2. UPDATED FLOATING ACTION BUTTON
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Navigate and pre-select this specific shop
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ReportPriceScreen(initialShopId: shop.id),
            ),
          );
        },
        label: const Text("Report Price"),
        icon: const Icon(Icons.add_chart),
        backgroundColor: Colors.green,
      ),
    );
  }

  Widget _buildShopHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        border: Border(bottom: BorderSide(color: Colors.green.shade100)),
      ),
      child: Column(
        children: [
          const CircleAvatar(
            radius: 35,
            backgroundColor: Colors.white,
            child: Icon(Icons.store, size: 40, color: Colors.green),
          ),
          const SizedBox(height: 12),
          Text(
            shop.name,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.location_on, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                "${shop.location} (${shop.campus})",
                style: TextStyle(color: Colors.grey.shade700),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 60, color: Colors.grey.shade300),
          const SizedBox(height: 10),
          const Text("No prices reported for this shop yet."),
        ],
      ),
    );
  }
}