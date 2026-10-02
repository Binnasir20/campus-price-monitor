import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'package:provider/provider.dart';
import '../../model/item_model.dart';
import '../../providers/item_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/shop_provider.dart';
import '../../providers/price_provider.dart';
import '../../model/price_model.dart';

class ManageItemsScreen extends StatefulWidget {
  const ManageItemsScreen({super.key});

  @override
  State<ManageItemsScreen> createState() => _ManageItemsScreenState();
}

class _ManageItemsScreenState extends State<ManageItemsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  String _selectedCategory = 'Food';
  String? _selectedShopId;

  final List<String> _categories = ['Food', 'Stationery', 'Electronics', 'Other'];

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      Provider.of<ItemProvider>(context, listen: false).fetchItems();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _showAddItemDialog() {
    _nameController.clear();
    _priceController.clear();
    _selectedCategory = 'Food';
    _selectedShopId = null;

    final shops = Provider.of<ShopProvider>(context, listen: false).shops;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Add Item & Set Price"),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: "Item Name (e.g. Notebook)"),
                    validator: (val) => val!.isEmpty ? "Enter item name" : null,
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: const InputDecoration(labelText: "Category"),
                    items: _categories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() {
                          _selectedCategory = val;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: _selectedShopId,
                    decoration: const InputDecoration(labelText: "Select Shop"),
                    items: shops.map((shop) => DropdownMenuItem(value: shop.id, child: Text(shop.name))).toList(),
                    onChanged: (val) {
                      setDialogState(() {
                        _selectedShopId = val;
                      });
                    },
                    validator: (val) => val == null ? "Select a shop" : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _priceController,
                    decoration: const InputDecoration(labelText: "Price (₦)"),
                    keyboardType: TextInputType.number,
                    validator: (val) => val!.isEmpty ? "Enter price" : null,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  final itemProvider = Provider.of<ItemProvider>(context, listen: false);
                  final priceProvider = Provider.of<PriceProvider>(context, listen: false);
                  final authProvider = Provider.of<AuthProvider>(context, listen: false);
                  final user = authProvider.userModel;

                  if (user == null) return;

                  // 1. Create the item definition if it doesn't exist
                  final newItem = Item(
                    id: '',
                    name: _nameController.text.trim(),
                    category: _selectedCategory,
                  );

                  await itemProvider.addItem(newItem);

                  // 2. Set the base/official price in the selected shop
                  final newPrice = Price(
                    id: '',
                    itemId: _nameController.text.trim(),
                    shopId: _selectedShopId!,
                    university: user.university,
                    price: double.parse(_priceController.text.trim()),
                    updatedAt: DateTime.now(),
                    reportedBy: user.uid,
                  );

                  await priceProvider.reportPrice(newPrice);

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Item added and price set successfully!"), backgroundColor: Colors.green),
                    );
                    Navigator.pop(context);
                  }
                }
              },
              child: const Text("Add"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final itemProvider = Provider.of<ItemProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Manage Items & Categories"),
        backgroundColor: Colors.blueGrey[900],
        foregroundColor: Colors.white,
      ),
      body: itemProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : itemProvider.items.isEmpty
              ? const Center(child: Text("No items added yet. Click '+' to add."))
              : ListView.builder(
                  padding: const EdgeInsets.all(10),
                  itemCount: itemProvider.items.length,
                  itemBuilder: (context, index) {
                    final item = itemProvider.items[index];
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blueGrey.shade50,
                          child: Icon(
                            item.category == 'Food'
                                ? IconlyLight.activity
                                : item.category == 'Stationery'
                                    ? IconlyLight.document
                                    : item.category == 'Electronics'
                                        ? IconlyLight.game
                                        : IconlyLight.bag,
                            color: Colors.blueGrey,
                          ),
                        ),
                        title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("Category: ${item.category}"),
                        trailing: IconButton(
                          icon: const Icon(IconlyLight.delete, color: Colors.redAccent),
                          onPressed: () async {
                            bool success = await itemProvider.deleteItem(item.id);
                            if (success && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Item deleted")),
                              );
                            }
                          },
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddItemDialog,
        backgroundColor: Colors.blueGrey[900],
        foregroundColor: Colors.white,
        child: const Icon(IconlyLight.plus),
      ),
    );
  }
}