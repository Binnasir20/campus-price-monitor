import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'package:provider/provider.dart';

import '../../model/item_model.dart';
import '../../model/price_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/item_provider.dart';
import '../../providers/price_provider.dart';
import '../../providers/shop_provider.dart';

class ManageItemsScreen extends StatefulWidget {
  const ManageItemsScreen({super.key});

  @override
  State<ManageItemsScreen> createState() => _ManageItemsScreenState();
}

class _ManageItemsScreenState extends State<ManageItemsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();

  final List<String> _categories = [
    'Food',
    'Stationery',
    'Electronics',
    'Other',
  ];

  String _selectedCategory = 'Food';
  String? _selectedShopId;

  bool _isSaving = false;
  String? _deletingItemId;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ItemProvider>().fetchItems();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  // ============================================================
  // MESSAGES
  // ============================================================

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor:
          isError ? Colors.redAccent : Colors.green,
        ),
      );
  }

  // ============================================================
  // VALIDATION
  // ============================================================

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Enter the item name';
    }

    return null;
  }

  String? _validatePrice(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Enter the price';
    }

    final price = double.tryParse(value.trim());

    if (price == null || !price.isFinite || price <= 0) {
      return 'Enter a valid price greater than zero';
    }

    return null;
  }

  // ============================================================
  // ADD ITEM
  // ============================================================

  void _showAddItemDialog() {
    _nameController.clear();
    _priceController.clear();

    _selectedCategory = 'Food';
    _selectedShopId = null;

    final shops = context.read<ShopProvider>().shops;

    if (shops.isEmpty) {
      _showMessage(
        'Add a shop before adding an item.',
        isError: true,
      );
      return;
    }

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        bool saving = false;

        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: const Text('Add Item & Set Price'),
              content: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: _nameController,
                        textCapitalization:
                        TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Item Name',
                          hintText: 'e.g. Notebook',
                          prefixIcon:
                          Icon(Icons.inventory_2_outlined),
                        ),
                        validator: _validateName,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                          prefixIcon:
                          Icon(Icons.category_outlined),
                        ),
                        items: _categories.map((category) {
                          return DropdownMenuItem(
                            value: category,
                            child: Text(category),
                          );
                        }).toList(),
                        onChanged: saving
                            ? null
                            : (value) {
                          if (value == null) return;

                          setDialogState(() {
                            _selectedCategory = value;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedShopId,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Select Shop',
                          prefixIcon:
                          Icon(Icons.store_outlined),
                        ),
                        items: shops.map((shop) {
                          return DropdownMenuItem(
                            value: shop.id,
                            child: Text(
                              shop.name,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: saving
                            ? null
                            : (value) {
                          setDialogState(() {
                            _selectedShopId = value;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Select a shop';
                          }

                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _priceController,
                        keyboardType:
                        const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Price',
                          prefixText: '₦ ',
                          prefixIcon:
                          Icon(Icons.payments_outlined),
                        ),
                        validator: _validatePrice,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: saving
                      ? null
                      : () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: saving
                      ? null
                      : () async {
                    if (!_formKey.currentState!.validate()) {
                      return;
                    }

                    setDialogState(() => saving = true);

                    final success = await _saveItem();

                    if (!dialogContext.mounted) return;

                    setDialogState(() => saving = false);

                    if (success) {
                      Navigator.pop(dialogContext);
                    }
                  },
                  child: saving
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : const Text('Add Item'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<bool> _saveItem() async {
    if (_isSaving) return false;

    final itemProvider = context.read<ItemProvider>();
    final priceProvider = context.read<PriceProvider>();
    final user = context.read<AuthProvider>().userModel;

    if (user == null) {
      _showMessage('Please sign in first.', isError: true);
      return false;
    }

    final name = _nameController.text.trim();
    final priceValue = double.tryParse(_priceController.text.trim());
    final shopId = _selectedShopId;

    if (priceValue == null ||
        !priceValue.isFinite ||
        priceValue <= 0 ||
        shopId == null) {
      _showMessage('Please enter valid item details.',
          isError: true);
      return false;
    }

    setState(() => _isSaving = true);

    try {
      final normalizedName = name.toLowerCase();

      final existingItems = itemProvider.items.where(
            (item) =>
        item.name.trim().toLowerCase() == normalizedName,
      );

      String itemId;

      if (existingItems.isNotEmpty) {
        final existingItem = existingItems.first;

        if (existingItem.category != _selectedCategory) {
          _showMessage(
            'This item already exists under '
                '${existingItem.category}.',
            isError: true,
          );
          return false;
        }

        itemId = existingItem.id;
      } else {
        final createdId = await itemProvider.addItem(
          Item(
            id: '',
            name: name,
            category: _selectedCategory,
          ),
        );

        if (createdId == null || createdId.trim().isEmpty) {
          _showMessage('Failed to create the item.',
              isError: true);
          return false;
        }

        itemId = createdId;
      }

      final existingPrice = priceProvider.prices.where(
            (price) =>
        price.shopId == shopId && price.itemId == itemId,
      );

      final price = Price(
        id: existingPrice.isEmpty ? '' : existingPrice.first.id,
        itemId: itemId,
        shopId: shopId,
        university: user.university,
        price: priceValue,
        updatedAt: DateTime.now(),
        reportedBy: user.uid,
      );

      final saved = await priceProvider.reportPrice(price);

      if (!saved) {
        _showMessage(
          'The item may have been created, but its price could not '
              'be saved. Check the item before trying again.',
          isError: true,
        );
        return false;
      }

      _showMessage('Item and price saved successfully.');
      return true;
    } catch (error, stackTrace) {
      debugPrint('Error saving item: $error');
      debugPrintStack(stackTrace: stackTrace);

      _showMessage('Failed to save the item and price.',
          isError: true);
      return false;
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ============================================================
  // EDIT ITEM AND PRICE
  // ============================================================

  Future<void> _showEditItemDialog(Item item) async {
    final nameController = TextEditingController(text: item.name);
    final priceController = TextEditingController();

    final shops = context.read<ShopProvider>().shops;
    final itemProvider = context.read<ItemProvider>();
    final priceProvider = context.read<PriceProvider>();
    final user = context.read<AuthProvider>().userModel;

    if (user == null || shops.isEmpty) {
      nameController.dispose();
      priceController.dispose();

      _showMessage(
        user == null
            ? 'Please sign in before editing.'
            : 'Add a shop before editing prices.',
        isError: true,
      );
      return;
    }

    String category = _categories.contains(item.category)
        ? item.category
        : 'Other';

    String? shopId = shops.first.id;
    Price? existingPrice;

    void loadPrice(String? selectedShop) {
      if (selectedShop == null) return;

      final matches = priceProvider.prices.where(
            (price) =>
        price.shopId == selectedShop &&
            price.itemId == item.id,
      );

      existingPrice = matches.isEmpty ? null : matches.first;

      priceController.text =
          existingPrice?.price.toString() ?? '';
    }

    final itemPrices = priceProvider.prices.where(
          (price) => price.itemId == item.id,
    );

    if (itemPrices.isNotEmpty) {
      final existingShopId = itemPrices.first.shopId;

      if (shops.any((shop) => shop.id == existingShopId)) {
        shopId = existingShopId;
      }
    }

    loadPrice(shopId);

    final formKey = GlobalKey<FormState>();

    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          bool saving = false;

          return StatefulBuilder(
            builder: (dialogContext, setDialogState) {
              return AlertDialog(
                title: const Text('Edit Item & Price'),
                content: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: nameController,
                          textCapitalization:
                          TextCapitalization.words,
                          decoration: const InputDecoration(
                            labelText: 'Item Name',
                          ),
                          validator: _validateName,
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: category,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Category',
                          ),
                          items: _categories.map((value) {
                            return DropdownMenuItem(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          onChanged: saving
                              ? null
                              : (value) {
                            if (value == null) return;
                            setDialogState(() => category = value);
                          },
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: shopId,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Shop',
                          ),
                          items: shops.map((shop) {
                            return DropdownMenuItem(
                              value: shop.id,
                              child: Text(
                                shop.name,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: saving
                              ? null
                              : (value) {
                            setDialogState(() {
                              shopId = value;
                              loadPrice(value);
                            });
                          },
                          validator: (value) =>
                          value == null ? 'Select a shop' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: priceController,
                          keyboardType:
                          const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Current Price',
                            prefixText: '₦ ',
                          ),
                          validator: _validatePrice,
                        ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: saving
                        ? null
                        : () => Navigator.pop(dialogContext),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: saving
                        ? null
                        : () async {
                      if (!formKey.currentState!.validate()) {
                        return;
                      }

                      final newName = nameController.text.trim();
                      final newPrice =
                      double.tryParse(priceController.text.trim());

                      if (shopId == null ||
                          newPrice == null ||
                          !newPrice.isFinite ||
                          newPrice <= 0) {
                        return;
                      }

                      final duplicate = itemProvider.items.any(
                            (other) =>
                        other.id != item.id &&
                            other.name.trim().toLowerCase() ==
                                newName.toLowerCase(),
                      );

                      if (duplicate) {
                        _showMessage(
                          'Another item already uses this name.',
                          isError: true,
                        );
                        return;
                      }

                      setDialogState(() => saving = true);

                      try {
                        final updatedItem = Item(
                          id: item.id,
                          name: newName,
                          category: category,
                          imageUrl: item.imageUrl,
                        );

                        final itemSaved =
                        await itemProvider.updateItem(updatedItem);

                        if (!itemSaved) {
                          throw Exception('Could not update the item.');
                        }

                        final updatedPrice = Price(
                          id: existingPrice?.id ?? '',
                          itemId: item.id,
                          shopId: shopId!,
                          university: user.university,
                          price: newPrice,
                          updatedAt: DateTime.now(),
                          reportedBy: user.uid,
                        );

                        final priceSaved = existingPrice == null
                            ? await priceProvider.reportPrice(
                          updatedPrice,
                        )
                            : await priceProvider.updateCurrentPrice(
                          updatedPrice,
                        );

                        if (!priceSaved) {
                          throw Exception(
                            'Item updated, but price saving failed.',
                          );
                        }

                        if (!dialogContext.mounted) return;

                        Navigator.pop(dialogContext);
                        _showMessage('Item and price updated.');
                      } catch (error, stackTrace) {
                        debugPrint('Error editing item: $error');
                        debugPrintStack(stackTrace: stackTrace);

                        _showMessage(
                          error.toString().replaceFirst(
                            'Exception: ',
                            '',
                          ),
                          isError: true,
                        );
                      } finally {
                        if (dialogContext.mounted) {
                          setDialogState(() => saving = false);
                        }
                      }
                    },
                    child: saving
                        ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                        : const Text('Save Changes'),
                  ),
                ],
              );
            },
          );
        },
      );
    } finally {
      nameController.dispose();
      priceController.dispose();
    }
  }

  // ============================================================
  // DELETE ITEM
  // ============================================================

  Future<bool> _confirmDelete(Item item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Item?'),
          content: Text(
            'Delete "${item.name}" and its associated current prices?\n\n'
                'This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    return confirmed ?? false;
  }

  Future<void> _deleteItem(Item item) async {
    debugPrint(
      'DELETE REQUEST: name=${item.name}, '
          'id=${item.id}, category=${item.category}',
    );

    if (_deletingItemId != null || _isSaving) return;

    final confirmed = await _confirmDelete(item);

    if (!confirmed || !mounted) return;

    setState(() => _deletingItemId = item.id);

    try {
      final success = await context.read<ItemProvider>().deleteItem(
        item.id,
        itemName: item.name,
      );

      if (!mounted) return;

      if (success) {
        _showMessage('${item.name} deleted successfully.');
      } else {
        _showMessage(
          'Failed to delete ${item.name}.',
          isError: true,
        );
      }
    } catch (error, stackTrace) {
      debugPrint('Delete error for ${item.name}: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (mounted) {
        _showMessage('An error occurred while deleting the item.',
            isError: true);
      }
    } finally {
      if (mounted) setState(() => _deletingItemId = null);
    }
  }

  // ============================================================
  // CATEGORY ICON
  // ============================================================

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return IconlyLight.activity;
      case 'stationery':
        return IconlyLight.document;
      case 'electronics':
        return IconlyLight.game;
      default:
        return IconlyLight.bag;
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final itemProvider = context.watch<ItemProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Items & Categories'),
        backgroundColor: Colors.blueGrey[900],
        foregroundColor: Colors.white,
      ),
      body: itemProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : itemProvider.items.isEmpty
          ? const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                IconlyLight.bag,
                size: 55,
                color: Colors.grey,
              ),
              SizedBox(height: 12),
              Text(
                'No items added yet.',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Tap the + button to add an item.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(10),
        itemCount: itemProvider.items.length,
        itemBuilder: (context, index) {
          final item = itemProvider.items[index];
          final deleting = _deletingItemId == item.id;

          return Card(
            key: ValueKey(item.id),
            margin: const EdgeInsets.only(bottom: 10),
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 6,
              ),
              leading: CircleAvatar(
                backgroundColor: Colors.blueGrey.shade50,
                child: Icon(
                  _getCategoryIcon(item.category),
                  color: Colors.blueGrey,
                ),
              ),
              title: Text(
                item.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text('Category: ${item.category}'),
              trailing: deleting
                  ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              )
                  : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Edit item and price',
                    icon: const Icon(
                      Icons.edit_outlined,
                      color: Colors.blueGrey,
                    ),
                    onPressed: _deletingItemId != null ||
                        _isSaving
                        ? null
                        : () => _showEditItemDialog(item),
                  ),
                  IconButton(
                    tooltip: 'Delete item',
                    icon: const Icon(
                      IconlyLight.delete,
                      color: Colors.redAccent,
                    ),
                    onPressed: _deletingItemId != null ||
                        _isSaving
                        ? null
                        : () => _deleteItem(item),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isSaving || _deletingItemId != null
            ? null
            : _showAddItemDialog,
        backgroundColor: Colors.blueGrey[900],
        foregroundColor: Colors.white,
        tooltip: 'Add item',
        child: const Icon(IconlyLight.plus),
      ),
    );
  }
}