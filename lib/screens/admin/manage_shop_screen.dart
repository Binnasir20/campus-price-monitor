import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../model/shop_model.dart';
import '../../providers/shop_provider.dart';

class ManageShopsScreen extends StatelessWidget {
  const ManageShopsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // We listen to the shops already being fetched by the ShopProvider
    final shopProvider = Provider.of<ShopProvider>(context);
    final shops = shopProvider.shops;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Manage Shops"),
        backgroundColor: Colors.blueGrey[900],
        foregroundColor: Colors.white,
      ),
      body: shops.isEmpty
          ? const Center(child: Text("No shops found."))
          : ListView.builder(
        padding: const EdgeInsets.all(10),
        itemCount: shops.length,
        itemBuilder: (context, index) {
          final shop = shops[index];
          return _buildShopAdminCard(context, shop, shopProvider);
        },
      ),
    );
  }

  Widget _buildShopAdminCard(BuildContext context, Shop shop, ShopProvider provider) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(
          shop.isVerified ? Icons.verified : Icons.help_outline,
          color: shop.isVerified ? Colors.blue : Colors.orange,
        ),
        title: Text(shop.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("${shop.campus} - ${shop.location}"),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Only show Verify button if shop is NOT yet verified
            if (!shop.isVerified)
              IconButton(
                icon: const Icon(Icons.check_circle, color: Colors.green),
                onPressed: () => _confirmVerify(context, shop, provider),
              ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _confirmDelete(context, shop, provider),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmVerify(BuildContext context, Shop shop, ShopProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Verify Shop?"),
        content: Text("Do you want to mark '${shop.name}' as an official shop?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCEL")),
          ElevatedButton(
            onPressed: () async {
              await provider.verifyShop(shop.id);
              if (context.mounted) Navigator.pop(ctx);
            },
            child: const Text("VERIFY"),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, Shop shop, ShopProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Shop?"),
        content: Text("This will permanently remove '${shop.name}'. All prices linked to this shop might become invisible."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCEL")),
          TextButton(
            onPressed: () async {
              await provider.deleteShop(shop.id);
              if (context.mounted) Navigator.pop(ctx);
            },
            child: const Text("DELETE", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}