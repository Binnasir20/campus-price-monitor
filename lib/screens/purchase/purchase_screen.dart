import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../model/item_model.dart';
import '../../model/shop_model.dart';
import '../../model/price_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/item_provider.dart';
import '../../providers/shop_provider.dart';
import '../../providers/price_provider.dart';
import '../../providers/purchase_provider.dart';

class PurchaseScreen extends StatefulWidget {
  const PurchaseScreen({super.key});

  @override
  State<PurchaseScreen> createState() => _PurchaseScreenState();
}

class _PurchaseScreenState extends State<PurchaseScreen> {
  Item? _selectedItem;
  Shop? _selectedShop;

  final TextEditingController _quantityController =
  TextEditingController(text: '1');

  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    if (!mounted) return;

    final auth = context.read<AuthProvider>();
    final user = auth.userModel;

    if (user == null) return;

    context.read<ItemProvider>().fetchItems();

    context.read<ShopProvider>().fetchShopsByUniversity(
      user.university,
      user.uid,
    );

    context.read<PriceProvider>().fetchPricesByUniversity(
      user.university,
    );
  }

  double get _quantity {
    return double.tryParse(_quantityController.text.trim()) ?? 0;
  }

  Price? get _selectedPrice {
    if (_selectedItem == null || _selectedShop == null) {
      return null;
    }

    final prices = context.read<PriceProvider>().prices;

    try {
      return prices.firstWhere(
            (price) =>
        price.itemId == _selectedItem!.id &&
            price.shopId == _selectedShop!.id,
      );
    } catch (_) {
      return null;
    }
  }

  double get _totalAmount {
    final price = _selectedPrice;
    if (price == null || _quantity <= 0) return 0;

    return price.price * _quantity;
  }

  Future<void> _makePurchase() async {
    if (_isProcessing) return;

    final auth = context.read<AuthProvider>();
    final user = auth.userModel;

    if (user == null) {
      _showMessage('Please log in before making a purchase.');
      return;
    }

    if (_selectedItem == null || _selectedShop == null) {
      _showMessage('Please select an item and a shop.');
      return;
    }

    if (_quantity <= 0) {
      _showMessage('Enter a valid quantity.');
      return;
    }

    final price = _selectedPrice;

    if (price == null || price.price <= 0) {
      _showMessage('No valid recorded price is available for this shop.');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Confirm demo purchase'),
          content: Text(
            'Item: ${_selectedItem!.name}\n'
                'Shop: ${_selectedShop!.name}\n'
                'Quantity: ${_quantity.toStringAsFixed(2)}\n'
                'Total: ₦${_totalAmount.toStringAsFixed(2)}\n\n'
                'This is a simulation. No real money will be charged.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Simulate payment'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isProcessing = true);

    try {
      final purchaseProvider = context.read<PurchaseProvider>();

      final success = await purchaseProvider.makeDemoPurchase(
        studentId: user.uid,
        studentName: user.name,
        university: user.university,
        campus: user.campus,
        itemId: _selectedItem!.id,
        itemName: _selectedItem!.name,
        shopId: _selectedShop!.id,
        shopName: _selectedShop!.name,
        quantity: _quantity,
        unit: 'unit',
        unitPrice: price.price,
        availablePrices: context.read<PriceProvider>().prices,
      );

      if (!mounted) return;

      if (success) {
        _quantityController.text = '1';

        _showMessage(
          'Demo purchase saved successfully.',
        );
      } else {
        _showMessage(
          'Purchase could not be completed. Please try again.',
        );
      }
    } catch (e) {
      if (mounted) {
        _showMessage('Purchase failed: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = context.watch<ItemProvider>().items;
    final shops = context.watch<ShopProvider>().shops;
    final prices = context.watch<PriceProvider>().prices;

    final availableShops = _selectedItem == null
        ? <Shop>[]
        : shops.where((shop) {
      return prices.any(
            (price) =>
        price.itemId == _selectedItem!.id &&
            price.shopId == shop.id &&
            price.price > 0,
      );
    }).toList();

    if (_selectedShop != null &&
        !availableShops.any((shop) => shop.id == _selectedShop!.id)) {
      _selectedShop = null;
    }

    final selectedPrice = _selectedPrice;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Demo Purchase'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.teal.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Test a purchase',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'This demonstration records a simulated purchase '
                        'and checks whether the price may be unusually high. '
                        'No real payment will be made.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              'Select item',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            DropdownButtonFormField<Item>(
              value: _selectedItem,
              isExpanded: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Choose an item',
              ),
              items: items.map((item) {
                return DropdownMenuItem(
                  value: item,
                  child: Text(item.name),
                );
              }).toList(),
              onChanged: (item) {
                setState(() {
                  _selectedItem = item;
                  _selectedShop = null;
                });
              },
            ),

            const SizedBox(height: 20),

            const Text(
              'Select shop',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            DropdownButtonFormField<Shop>(
              value: _selectedShop,
              isExpanded: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Choose a shop',
              ),
              items: availableShops.map((shop) {
                return DropdownMenuItem(
                  value: shop,
                  child: Text(shop.name),
                );
              }).toList(),
              onChanged: _selectedItem == null
                  ? null
                  : (shop) {
                setState(() => _selectedShop = shop);
              },
            ),

            if (_selectedItem != null && availableShops.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'No recorded prices are available for this item.',
                  style: TextStyle(color: Colors.red),
                ),
              ),

            const SizedBox(height: 20),

            const Text(
              'Quantity',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            TextField(
              controller: _quantityController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Enter quantity',
              ),
              onChanged: (_) => setState(() {}),
            ),

            const SizedBox(height: 20),

            if (selectedPrice != null) ...[
              _PriceRow(
                label: 'Recorded unit price',
                value: '₦${selectedPrice.price.toStringAsFixed(2)}',
              ),
              const SizedBox(height: 8),
              _PriceRow(
                label: 'Total amount',
                value: '₦${_totalAmount.toStringAsFixed(2)}',
                isTotal: true,
              ),
              const SizedBox(height: 8),
              Text(
                'Last updated: ${selectedPrice.updatedAt.toLocal()}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],

            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isProcessing ? null : _makePurchase,
                icon: _isProcessing
                    ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                )
                    : const Icon(Icons.payment),
                label: Text(
                  _isProcessing
                      ? 'Processing...'
                      : 'Simulate Purchase',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isTotal;

  const _PriceRow({
    required this.label,
    required this.value,
    this.isTotal = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 18 : 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}