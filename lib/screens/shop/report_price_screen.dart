import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../model/price_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/shop_provider.dart';
import '../../providers/price_provider.dart';

class ReportPriceScreen extends StatefulWidget {
  final String? initialShopId; // To pre-select if coming from ShopDetail

  const ReportPriceScreen({super.key, this.initialShopId});

  @override
  State<ReportPriceScreen> createState() => _ReportPriceScreenState();
}

class _ReportPriceScreenState extends State<ReportPriceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _itemController = TextEditingController();
  final _priceController = TextEditingController();
  String? _selectedShopId;

  @override
  void initState() {
    super.initState();
    _selectedShopId = widget.initialShopId;
  }

  @override
  void dispose() {
    _itemController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _submitPrice() async {
    if (!_formKey.currentState!.validate() || _selectedShopId == null) {
      _showSnackBar("Please fill all fields", Colors.orange);
      return;
    }

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final priceProv = Provider.of<PriceProvider>(context, listen: false);
    final user = auth.userModel; // Get the user object

    // Check if user is null before proceeding
    if (user == null) {
      _showSnackBar("Session expired. Please log in again.", Colors.red);
      return;
    }

    final newPrice = Price(
      id: '',
      itemId: _itemController.text.trim(),
      shopId: _selectedShopId!,
      university: user.university, // Make sure this is "UDUS"
      price: double.parse(_priceController.text),
      updatedAt: DateTime.now(),
      reportedBy: user.uid,
    );

    try {
      // We add a print here to see if it even starts
      print("Attempting to report price for ${user.university}...");

      bool success = await priceProv.reportPrice(newPrice);

      if (mounted) {
        if (success) {
          _showSnackBar("Price reported successfully!", Colors.green);
          Navigator.pop(context);
        } else {
          _showSnackBar("Failed to report: Check your connection", Colors.red);
        }
      }
    } catch (e) {
      print("CRITICAL ERROR: $e");
      _showSnackBar("Error: $e", Colors.red);
    }
  }

  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    final shops = Provider.of<ShopProvider>(context).shops;

    return Scaffold(
      appBar: AppBar(title: const Text("Report a Price")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Select the shop where you found this price:"),
              const SizedBox(height: 10),

              // 1. SHOP SELECTOR
              DropdownButtonFormField<String>(
                value: _selectedShopId,
                decoration: const InputDecoration(
                  labelText: "Shop",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.store),
                ),
                items: shops.map((s) {
                  return DropdownMenuItem(value: s.id, child: Text(s.name));
                }).toList(),
                onChanged: (val) => setState(() => _selectedShopId = val),
                validator: (val) => val == null ? "Please select a shop" : null,
              ),
              const SizedBox(height: 20),

              // 2. ITEM NAME
              TextFormField(
                controller: _itemController,
                decoration: const InputDecoration(
                  labelText: "What are you reporting? (e.g. Bread)",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.shopping_basket),
                ),
                validator: (val) => val!.isEmpty ? "Enter item name" : null,
              ),
              const SizedBox(height: 20),

              // 3. PRICE
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: "Price (₦)",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.payments),
                ),
                keyboardType: TextInputType.number,
                validator: (val) {
                  if (val!.isEmpty) return "Enter price";
                  if (double.tryParse(val) == null) return "Enter a valid number";
                  return null;
                },
              ),
              const SizedBox(height: 30),

              // 4. SUBMIT BUTTON
              Consumer<PriceProvider>(
                builder: (context, prov, _) {
                  return prov.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(55),
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _submitPrice,
                    child: const Text("SUBMIT PRICE REPORT"),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}