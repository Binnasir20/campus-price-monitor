import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../model/item_model.dart';
import '../../model/shop_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/item_provider.dart';
import '../../providers/shop_provider.dart';
import '../../providers/price_provider.dart';
import '../../providers/purchase_provider.dart';

import 'purchase_history_screen.dart';
import 'price_alert_screen.dart';

class PurchaseScreen extends StatefulWidget {
  const PurchaseScreen({super.key});

  @override
  State<PurchaseScreen> createState() => _PurchaseScreenState();
}

class _PurchaseScreenState extends State<PurchaseScreen> {
  final _formKey = GlobalKey<FormState>();

  final _itemNameController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  final _priceController = TextEditingController();

  Shop? _selectedShop;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadData();
      }
    });
  }

  @override
  void dispose() {
    _itemNameController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final authProvider = context.read<AuthProvider>();
    final itemProvider = context.read<ItemProvider>();
    final shopProvider = context.read<ShopProvider>();
    final priceProvider = context.read<PriceProvider>();
    final purchaseProvider = context.read<PurchaseProvider>();

    final user = authProvider.userModel;

    if (user == null) return;

    try {
      await itemProvider.fetchItems();

      if (!mounted) return;

      await shopProvider.fetchShopsByUniversity(
        user.university,
        user.uid,
        isAdmin: user.isAdmin,
      );

      if (!mounted) return;

      await priceProvider.fetchPricesByUniversity(user.university);

      if (!mounted) return;

      if (user.isAdmin) {
        await purchaseProvider.fetchUniversityPurchases(user.university);

        if (!mounted) return;
      }

      setState(() {});
    } catch (e) {
      debugPrint('Could not load purchase data: $e');

      if (mounted) {
        _showMessage('Could not load purchase data. Please try again.');
      }
    }
  }

  double get _quantity {
    return double.tryParse(_quantityController.text.trim()) ?? 0;
  }

  double get _unitPrice {
    return double.tryParse(_priceController.text.trim()) ?? 0;
  }

  double get _totalAmount => _quantity * _unitPrice;

  String _formatCurrency(double amount) {
    return '₦${amount.toStringAsFixed(2)}';
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _makePurchase() async {
    if (_isProcessing) return;

    if (!_formKey.currentState!.validate()) return;

    final user = context.read<AuthProvider>().userModel;
    final shop = _selectedShop;

    if (user == null || shop == null) {
      _showMessage('Please select a shop and log in.');
      return;
    }

    final itemName = _itemNameController.text.trim();
    final quantity = _quantity;
    final unitPrice = _unitPrice;

    // Use an existing admin-listed item's ID only when its name matches.
    // Otherwise, the purchase receives a custom ID.
    final items = context.read<ItemProvider>().items;

    final matchingItems = items.where(
          (item) => item.name.trim().toLowerCase() == itemName.toLowerCase(),
    );

    final String itemId = matchingItems.isNotEmpty
        ? matchingItems.first.id
        : 'custom_${DateTime.now().microsecondsSinceEpoch}';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Confirm Demo Purchase'),
          content: Text(
            'Item: $itemName\n'
                'Shop: ${shop.name}\n'
                'Quantity: $quantity\n'
                'Unit price: ${_formatCurrency(unitPrice)}\n'
                'Total: ${_formatCurrency(quantity * unitPrice)}\n\n'
                'This is a demo transaction. No real money will be transferred.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );

    if (!mounted || confirmed != true) return;

    setState(() {
      _isProcessing = true;
    });

    final purchaseProvider = context.read<PurchaseProvider>();
    final availablePrices = context.read<PriceProvider>().prices;

    try {
      final success = await purchaseProvider.makeDemoPurchase(
        studentId: user.uid,
        studentName: user.name,
        university: user.university,
        campus: user.campus,
        itemId: itemId,
        itemName: itemName,
        shopId: shop.id,
        shopName: shop.name,
        quantity: quantity,
        unit: 'unit',
        unitPrice: unitPrice,
        availablePrices: availablePrices,
      );

      if (!mounted) return;

      if (success) {
        _itemNameController.clear();
        _quantityController.text = '1';
        _priceController.clear();

        setState(() {});

        _showMessage('Demo purchase saved successfully.');
      } else {
        _showMessage(
          purchaseProvider.errorMessage ?? 'Could not save the purchase.',
        );
      }
    } catch (e) {
      debugPrint('Purchase error: $e');

      if (mounted) {
        _showMessage('Purchase failed. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().userModel;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in to continue.')),
      );
    }

    if (user.isAdmin) {
      return _buildAdminScreen();
    }

    return _buildStudentScreen();
  }

  // ============================================================
  // STUDENT SCREEN
  // ============================================================

  Widget _buildStudentScreen() {
    final shops = context.watch<ShopProvider>().shops;

    return Scaffold(
      appBar: AppBar(title: const Text('Demo Purchase')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Record a demo purchase. No real payment is made.',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _itemNameController,
                decoration: const InputDecoration(
                  labelText: 'Item name',
                  hintText: 'e.g. Rice, Beans, Exercise Book',
                  prefixIcon: Icon(Icons.shopping_bag_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter an item name.';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 16),

              DropdownButtonFormField<Shop>(
                initialValue: _selectedShop,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Select shop',
                  prefixIcon: Icon(Icons.store_outlined),
                  border: OutlineInputBorder(),
                ),
                items: shops.map((shop) {
                  return DropdownMenuItem<Shop>(
                    value: shop,
                    child: Text(
                      shop.name,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (shop) {
                  setState(() {
                    _selectedShop = shop;
                  });
                },
                validator: (shop) {
                  if (shop == null) {
                    return 'Select a shop.';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _quantityController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Quantity',
                  prefixIcon: Icon(Icons.numbers),
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => setState(() {}),
                validator: (value) {
                  final quantity = double.tryParse(value ?? '');

                  if (quantity == null ||
                      !quantity.isFinite ||
                      quantity <= 0) {
                    return 'Enter a valid quantity.';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _priceController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Unit price (₦)',
                  prefixIcon: Icon(Icons.payments_outlined),
                  border: OutlineInputBorder(),
                  helperText: 'Enter the price paid per unit.',
                ),
                onChanged: (_) => setState(() {}),
                validator: (value) {
                  final price = double.tryParse(value ?? '');

                  if (price == null ||
                      !price.isFinite ||
                      price <= 0) {
                    return 'Enter a valid price.';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 24),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _summaryRow(
                        'Unit price',
                        _formatCurrency(_unitPrice),
                      ),
                      const SizedBox(height: 12),
                      _summaryRow('Quantity', _quantity.toString()),
                      const Divider(height: 24),
                      _summaryRow(
                        'Total',
                        _formatCurrency(_totalAmount),
                        bold: true,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              SizedBox(
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isProcessing ? null : _makePurchase,
                  icon: _isProcessing
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : const Icon(Icons.shopping_cart_outlined),
                  label: Text(
                    _isProcessing
                        ? 'Processing...'
                        : 'Record Demo Purchase',
                  ),
                ),
              ),

              const SizedBox(height: 12),

              OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PurchaseHistoryScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.receipt_long_outlined),
                label: const Text('My Purchase History'),
              ),

              OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PriceAlertScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.notifications_active_outlined),
                label: const Text('Price Alerts'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _summaryRow(
      String label,
      String value, {
        bool bold = false,
      }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: bold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            fontSize: bold ? 17 : 14,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // ADMIN SCREEN
  // ============================================================

  Widget _buildAdminScreen() {
    final purchases =
        context.watch<PurchaseProvider>().universityPurchases;

    final items = context.watch<ItemProvider>().items;
    final prices = context.watch<PriceProvider>().prices;
    final user = context.watch<AuthProvider>().userModel;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Purchase Monitoring'),
        actions: [
          IconButton(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh purchases',
          ),
        ],
      ),
      body: Column(
        children: [
          // Total purchases counter.
          Card(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: ListTile(
              leading: const Icon(Icons.receipt_long_outlined),
              title: const Text('Total Purchases'),
              trailing: Text(
                '${purchases.length}',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // Purchase list.
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadData,
              child: purchases.isEmpty
                  ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 100),
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 56,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Center(
                    child: Text('No purchases recorded yet.'),
                  ),
                ],
              )
                  : ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                itemCount: purchases.length,
                itemBuilder: (context, index) {
                  final purchase = purchases[index];

                  // Check whether this item actually exists in the
                  // admin's item list. Custom IDs are ignored.
                  final isAdminListed = items.any(
                        (item) => item.id == purchase.itemId,
                  );

                  // Find reference prices for the same item, shop,
                  // and university.
                  final matchingPrices = prices.where(
                        (price) =>
                    price.itemId == purchase.itemId &&
                        price.shopId == purchase.shopId &&
                        price.university == user?.university &&
                        price.price > 0,
                  ).toList();

                  // Use the most recently updated matching price.
                  matchingPrices.sort(
                        (a, b) => b.updatedAt.compareTo(a.updatedAt),
                  );

                  final double? referencePrice =
                  isAdminListed && matchingPrices.isNotEmpty
                      ? matchingPrices.first.price
                      : null;

                  // Compare unit price, not total purchase amount.
                  final isOverpriced = referencePrice != null &&
                      purchase.unitPrice > referencePrice;

                  final cardColor = isOverpriced
                      ? Colors.red.withValues(alpha: 0.10)
                      : null;

                  final borderColor = isOverpriced
                      ? Colors.red
                      : Colors.transparent;

                  return Card(
                    color: cardColor,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: borderColor,
                        width: isOverpriced ? 1.5 : 0,
                      ),
                    ),
                    child: ListTile(
                      leading: Icon(
                        isOverpriced
                            ? Icons.warning_amber_rounded
                            : Icons.shopping_bag_outlined,
                        color: isOverpriced ? Colors.red : null,
                      ),
                      title: Text(
                        purchase.itemName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isOverpriced ? Colors.red : null,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Student: ${purchase.studentName}'),
                          Text('Shop: ${purchase.shopName}'),
                          Text('Quantity: ${purchase.quantity}'),
                          Text(
                            'Unit price: '
                                '${_formatCurrency(purchase.unitPrice)}',
                          ),
                          Text(
                            'Date: ${purchase.purchasedAt.toLocal()}',
                          ),

                          if (isOverpriced) ...[
                            const SizedBox(height: 6),
                            Text(
                              'PRICE EXCEEDED ADMIN SET PRICE',
                              style: const TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Reference price: '
                                  '${_formatCurrency(referencePrice!)}',
                              style: const TextStyle(
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ],
                      ),
                      isThreeLine: true,
                      trailing: Text(
                        _formatCurrency(purchase.totalAmount),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isOverpriced ? Colors.red : null,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}