import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

// Project Imports
import '../../model/price_model.dart';
import '../../model/shop_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/price_provider.dart';
import '../../providers/shop_provider.dart';
import '../shop/report_price_screen.dart';
import '../complaints/complaint_form_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  /// Triggered once when screen opens to fill the lists
  void _loadInitialData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final user = auth.userModel;

      if (user != null) {
        // Fetch Prices and Shops for the specific university
        Provider.of<PriceProvider>(context, listen: false)
            .fetchPricesByUniversity(user.university);

        Provider.of<ShopProvider>(context, listen: false)
            .fetchShopsByUniversity(user.university, user.uid, isAdmin: user.isAdmin);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final priceProvider = Provider.of<PriceProvider>(context);
    final user = Provider.of<AuthProvider>(context).userModel;

    return Scaffold(
      appBar: AppBar(
        title: Text(user != null ? "${user.university} Monitor" : "Campus Prices"),
        backgroundColor: Colors.green[800],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _handleLogout(context),
          ),
        ],
      ),

      body: priceProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : priceProvider.prices.isEmpty
          ? _buildEmptyState(user?.university ?? "campus")
          : RefreshIndicator(
        onRefresh: () async => _loadInitialData(),
        child: ListView.builder(
          padding: const EdgeInsets.all(10),
          itemCount: priceProvider.prices.length,
          itemBuilder: (context, index) => _buildPriceCard(context, priceProvider.prices[index]),
        ),
      ),

      // Logic: Show different buttons for Admin vs Student
      floatingActionButton: _buildContextualButtons(user),
    );
  }

  /// Separates Admin tools from Student tools
  Widget _buildContextualButtons(user) {
    final bool isAdmin = user?.isAdmin ?? false;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (isAdmin) ...[
          // --- ADMIN ONLY SECTION ---
          FloatingActionButton.extended(
            heroTag: "admin_manage",
            onPressed: () => Navigator.pushNamed(context, '/manage_shops'),
            label: const Text("Manage Shops"),
            icon: const Icon(Icons.store_mall_directory),
            backgroundColor: Colors.blueGrey[800],
          ),
        ] else ...[
          // --- STUDENT ONLY SECTION ---
          FloatingActionButton.extended(
            heroTag: "report",
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ReportPriceScreen())),
            label: const Text("Report Price"),
            icon: const Icon(Icons.add_shopping_cart),
            backgroundColor: Colors.green[700],
          ),
          const SizedBox(height: 10),
          FloatingActionButton.extended(
            heroTag: "complain",
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ComplaintFormScreen())),
            label: const Text("Complain"),
            icon: const Icon(Icons.warning_amber_rounded),
            backgroundColor: Colors.redAccent,
          ),
        ],
      ],
    );
  }

  Widget _buildPriceCard(BuildContext context, Price price) {
    final shopProvider = Provider.of<ShopProvider>(context, listen: false);
    final shop = shopProvider.shops.cast<Shop?>().firstWhere((s) => s?.id == price.shopId, orElse: () => null);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.green.shade50,
          child: const Icon(Icons.shopping_bag_outlined, color: Colors.green),
        ),
        title: Text(price.itemId, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("At: ${shop?.name ?? 'Unknown Shop'}\nUpdated: ${DateFormat('MMM d').format(price.updatedAt)}"),
        trailing: Text("₦${price.price.toStringAsFixed(0)}",
            style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 18)),
      ),
    );
  }

  Widget _buildEmptyState(String uni) {
    return Center(child: Text("No prices reported for $uni yet.", style: const TextStyle(color: Colors.grey)));
  }

  void _handleLogout(BuildContext context) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    Provider.of<PriceProvider>(context, listen: false).clearPrices();
    Provider.of<ShopProvider>(context, listen: false).clearShops();
    await auth.logout();
    if (context.mounted) Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }
}