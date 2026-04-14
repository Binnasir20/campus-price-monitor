import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/shop_provider.dart';
import 'shop_detail_screen.dart';
import 'add_shop_screen.dart';

class ShopListScreen extends StatefulWidget {
  const ShopListScreen({super.key});

  @override
  State<ShopListScreen> createState() => _ShopListScreenState();
}

class _ShopListScreenState extends State<ShopListScreen> {
  @override
  void initState() {
    super.initState();
    // 1. Tell the app to fetch shops as soon as this screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = Provider.of<AuthProvider>(context, listen: false).userModel;
      if (user != null) {
        // We pass the university AND the user's ID to see their own pending shops
        Provider.of<ShopProvider>(context, listen: false)
            .fetchShopsByUniversity(user.university, user.uid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final shopProv = Provider.of<ShopProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Campus Shops"),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
      ),
      body: shopProv.isLoading
          ? const Center(child: CircularProgressIndicator())
          : shopProv.shops.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: shopProv.shops.length,
        itemBuilder: (context, index) {
          final shop = shopProv.shops[index];

          // 2. Check if the shop is waiting for Admin approval
          final bool isPending = !shop.isVerified;

          return Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: CircleAvatar(
                // Orange for pending, Green for verified
                backgroundColor: isPending ? Colors.orange.shade100 : Colors.green.shade100,
                child: Icon(
                    isPending ? Icons.hourglass_top : Icons.store,
                    color: isPending ? Colors.orange : Colors.green
                ),
              ),
              title: Text(
                shop.name,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Campus: ${shop.campus}"),
                  Text(shop.location, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  // 3. Show "Waiting for Approval" text if needed
                  if (isPending)
                    const Padding(
                      padding: EdgeInsets.only(top: 4.0),
                      child: Text(
                        "Waiting for approval...",
                        style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                ],
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ShopDetailScreen(shop: shop),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddShopScreen()),
          );
        },
        backgroundColor: Colors.green[700],
        icon: const Icon(Icons.add_business, color: Colors.white),
        label: const Text("Add Shop", style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.storefront_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text(
            "No shops found for your university",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          const Text("Be the first to add a shop!"),
        ],
      ),
    );
  }
}