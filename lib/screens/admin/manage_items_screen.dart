import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'package:provider/provider.dart';

import '../../model/item_model.dart';
import '../../model/price_model.dart';
import '../../providers/item_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/shop_provider.dart';
import '../../providers/price_provider.dart';

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

  bool _isSaving = false;
  String? _deletingItemId;

  final List<String> _categories = [
    'Food',
    'Stationery',
    'Electronics',
    'Other',
  ];

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
  // SHOW MESSAGE
  // ============================================================

  void _showMessage(
      String message, {
        bool isError = false,
      }) {
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
  // ADD ITEM DIALOG
  // ============================================================

  void _showAddItemDialog() {
    _nameController.clear();
    _priceController.clear();

    _selectedCategory = 'Food';
    _selectedShopId = null;

    final shops = context.read<ShopProvider>().shops;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
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
                          prefixIcon: Icon(Icons.inventory_2_outlined),
                        ),
                        validator: (value) {
                          if (value == null ||
                              value.trim().isEmpty) {
                            return 'Enter the item name';
                          }
                          return null;
                        },
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
                          return DropdownMenuItem<String>(
                            value: category,
                            child: Text(category),
                          );
                        }).toList(),
                        onChanged: (value) {
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
                          prefixIcon: Icon(Icons.store_outlined),
                        ),
                        items: shops.map((shop) {
                          return DropdownMenuItem<String>(
                            value: shop.id,
                            child: Text(
                              shop.name,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setDialogState(() {
                            _selectedShopId = value;
                          });
                        },
                        validator: (value) {
                          if (value == null) {
                            return 'Select a shop';
                          }
                          return null;
                        },
                      ),

                      if (shops.isEmpty)
                        const Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'No shops available. Add a shop first.',
                              style: TextStyle(
                                color: Colors.redAccent,
                                fontSize: 12,
                              ),
                            ),
                          ),
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
                          hintText: 'Enter amount',
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
                  onPressed: _isSaving
                      ? null
                      : () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: _isSaving || shops.isEmpty
                      ? null
                      : () async {
                    await _saveItem(
                      dialogContext,
                      setDialogState,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueGrey[900],
                    foregroundColor: Colors.white,
                  ),
                  child: _isSaving
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

  // ============================================================
  // PRICE VALIDATION
  // ============================================================

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
  // SAVE NEW ITEM AND PRICE
  // ============================================================

  Future<void> _saveItem(
      BuildContext dialogContext,
      StateSetter setDialogState,
      ) async {
    if (_isSaving) return;
    if (!_formKey.currentState!.validate()) return;

    final itemProvider = context.read<ItemProvider>();
    final priceProvider = context.read<PriceProvider>();
    final authProvider = context.read<AuthProvider>();

    final user = authProvider.userModel;

    if (user == null) {
      _showMessage(
        'Please sign in before adding an item.',
        isError: true,
      );
      return;
    }

    final itemName = _nameController.text.trim();
    final priceValue =
    double.tryParse(_priceController.text.trim());
    final shopId = _selectedShopId;

    if (priceValue == null ||
        !priceValue.isFinite ||
        priceValue <= 0 ||
        shopId == null) {
      return;
    }

    setDialogState(() => _isSaving = true);

    try {
      final normalizedName = itemName.toLowerCase();

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
                '${existingItem.category}. '
                'Edit the existing item instead.',
            isError: true,
          );
          return;
        }

        itemId = existingItem.id;
      } else {
        final newItem = Item(
          id: '',
          name: itemName,
          category: _selectedCategory,
        );

        final createdItemId =
        await itemProvider.addItem(newItem);

        if (createdItemId == null ||
            createdItemId.trim().isEmpty) {
          _showMessage(
            'Failed to create the item. Please try again.',
            isError: true,
          );
          return;
        }

        itemId = createdItemId;
      }

      // Find an existing price for this item and shop.
      final existingPrice = priceProvider.prices.where(
            (price) =>
        price.shopId == shopId &&
            (price.itemId == itemId ||
                price.itemId == itemName),
      );

      final newPrice = Price(
        id: existingPrice.isEmpty
            ? ''
            : existingPrice.first.id,
        itemId: itemId,
        shopId: shopId,
        university: user.university,
        price: priceValue,
        updatedAt: DateTime.now(),
        reportedBy: user.uid,
      );

      final priceSuccess =
      await priceProvider.reportPrice(newPrice);

      if (!mounted || !dialogContext.mounted) return;

      if (!priceSuccess) {
        _showMessage(
          'The item may have been created, but its price '
              'could not be saved. Please check and try again.',
          isError: true,
        );
        return;
      }

      Navigator.pop(dialogContext);

      _showMessage('Item and price saved successfully.');
    } catch (error, stackTrace) {
      debugPrint('Error saving item and price: $error');
      debugPrintStack(stackTrace: stackTrace);

      _showMessage(
        'Something went wrong while saving the item.',
        isError: true,
      );
    } finally {
      if (mounted) {
        setDialogState(() => _isSaving = false);
      }
    }
  }

  // ============================================================
  // EDIT ITEM AND CURRENT PRICE
  // ============================================================

  Future<void> _showEditItemDialog(Item item) async {
    final nameController =
    TextEditingController(text: item.name);
    final priceController = TextEditingController();

    String selectedCategory = _categories.contains(item.category)
        ? item.category
        : 'Other';

    final shops = context.read<ShopProvider>().shops;
    final priceProvider = context.read<PriceProvider>();
    final authProvider = context.read<AuthProvider>();

    final user = authProvider.userModel;

    if (user == null) {
      nameController.dispose();
      priceController.dispose();

      _showMessage(
        'Please sign in before editing an item.',
        isError: true,
      );
      return;
    }

    if (shops.isEmpty) {
      nameController.dispose();
      priceController.dispose();

      _showMessage(
        'No shops are available. Add a shop first.',
        isError: true,
      );
      return;
    }

    String? selectedShopId = shops.first.id;
    Price? existingPrice;

    void loadPriceForShop(String? shopId) {
      if (shopId == null) return;

      final matches = priceProvider.prices.where(
            (price) =>
        price.shopId == shopId &&
            (price.itemId == item.id ||
                price.itemId == item.name),
      );

      if (matches.isNotEmpty) {
        existingPrice = matches.first;
        priceController.text =
            existingPrice!.price.toString();
      } else {
        existingPrice = null;
        priceController.clear();
      }
    }

    // Prefer a shop that already has a price for this item.
    final existingPrices = priceProvider.prices.where(
          (price) =>
      price.itemId == item.id ||
          price.itemId == item.name,
    );

    if (existingPrices.isNotEmpty &&
        shops.any(
              (shop) => shop.id == existingPrices.first.shopId,
        )) {
      selectedShopId = existingPrices.first.shopId;
    }

    loadPriceForShop(selectedShopId);

    final editFormKey = GlobalKey<FormState>();
    bool isSaving = false;

    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (dialogContext, setDialogState) {
              return AlertDialog(
                title: const Text('Edit Item & Price'),
                content: SingleChildScrollView(
                  child: Form(
                    key: editFormKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: nameController,
                          textCapitalization:
                          TextCapitalization.words,
                          decoration: const InputDecoration(
                            labelText: 'Item Name',
                            prefixIcon: Icon(
                              Icons.inventory_2_outlined,
                            ),
                          ),
                          validator: (value) {
                            if (value == null ||
                                value.trim().isEmpty) {
                              return 'Enter the item name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        DropdownButtonFormField<String>(
                          value: selectedCategory,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Category',
                            prefixIcon:
                            Icon(Icons.category_outlined),
                          ),
                          items: _categories.map((category) {
                            return DropdownMenuItem<String>(
                              value: category,
                              child: Text(category),
                            );
                          }).toList(),
                          onChanged: isSaving
                              ? null
                              : (value) {
                            if (value == null) return;
                            setDialogState(() {
                              selectedCategory = value;
                            });
                          },
                        ),
                        const SizedBox(height: 16),

                        DropdownButtonFormField<String>(
                          value: selectedShopId,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Shop',
                            prefixIcon:
                            Icon(Icons.store_outlined),
                          ),
                          items: shops.map((shop) {
                            return DropdownMenuItem<String>(
                              value: shop.id,
                              child: Text(
                                shop.name,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: isSaving
                              ? null
                              : (value) {
                            setDialogState(() {
                              selectedShopId = value;
                              loadPriceForShop(value);
                            });
                          },
                          validator: (value) {
                            if (value == null) {
                              return 'Select a shop';
                            }
                            return null;
                          },
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
                            prefixIcon:
                            Icon(Icons.payments_outlined),
                          ),
                          validator: _validatePrice,
                        ),
                        const SizedBox(height: 8),

                        const Text(
                          'Only the selected shop’s current price '
                              'will be updated.',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: isSaving
                        ? null
                        : () => Navigator.pop(dialogContext),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: isSaving
                        ? null
                        : () async {
                      if (!editFormKey.currentState!
                          .validate()) {
                        return;
                      }

                      final newName =
                      nameController.text.trim();
                      final newPriceValue = double.tryParse(
                        priceController.text.trim(),
                      );
                      final shopId = selectedShopId;

                      if (newPriceValue == null ||
                          !newPriceValue.isFinite ||
                          newPriceValue <= 0 ||
                          shopId == null) {
                        return;
                      }

                      final itemProvider =
                      context.read<ItemProvider>();

                      final duplicate =
                      itemProvider.items.any(
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

                      setDialogState(() {
                        isSaving = true;
                      });

                      try {
                        // Update the existing item document.
                        final updatedItem = Item(
                          id: item.id,
                          name: newName,
                          category: selectedCategory,
                        );

                        final itemUpdated =
                        await itemProvider.updateItem(
                          updatedItem,
                        );

                        if (!itemUpdated) {
                          throw Exception(
                            'Could not update the item.',
                          );
                        }

                        // Update the selected shop's current price.
                        final updatedPrice = Price(
                          id: existingPrice?.id ?? '',
                          itemId: item.id,
                          shopId: shopId,
                          university: user.university,
                          price: newPriceValue,
                          updatedAt: DateTime.now(),
                          reportedBy: user.uid,
                        );

                        final priceUpdated =
                        await priceProvider.updateCurrentPrice(
                          updatedPrice,
                        );

                        if (!priceUpdated) {
                          throw Exception(
                            'The item was updated, but its price '
                                'could not be saved.',
                          );
                        }

                        if (!dialogContext.mounted) return;

                        Navigator.pop(dialogContext);

                        _showMessage(
                          'Item and current price updated successfully.',
                        );
                      } catch (error, stackTrace) {
                        debugPrint(
                          'Error editing item: $error',
                        );
                        debugPrintStack(
                          stackTrace: stackTrace,
                        );

                        if (dialogContext.mounted) {
                          setDialogState(() {
                            isSaving = false;
                          });
                        }

                        _showMessage(
                          error.toString().replaceFirst(
                            'Exception: ',
                            '',
                          ),
                          isError: true,
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueGrey[900],
                      foregroundColor: Colors.white,
                    ),
                    child: isSaving
                        ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
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
  // CONFIRM ITEM DELETION
  // ============================================================

  Future<bool> _confirmDelete(Item item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Item?'),
          content: Text(
            'Are you sure you want to delete "${item.name}" '
                'and its associated current prices?\n\n'
                'This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
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

  // ============================================================
  // DELETE ITEM
  // ============================================================

  Future<void> _deleteItem(Item item) async {
    if (_deletingItemId != null || _isSaving) return;

    final confirmed = await _confirmDelete(item);

    if (!confirmed || !mounted) return;

    setState(() {
      _deletingItemId = item.id;
    });

    try {
      final success = await context.read<ItemProvider>().deleteItem(
        item.id,
        itemName: item.name,
      );

      if (!mounted) return;

      if (success) {
        _showMessage(
          '${item.name} and its associated prices were deleted.',
        );
      } else {
        _showMessage(
          'Failed to delete ${item.name}. Please try again.',
          isError: true,
        );
      }
    } catch (error, stackTrace) {
      debugPrint('Error deleting ${item.name}: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (mounted) {
        _showMessage(
          'An error occurred while deleting ${item.name}.',
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _deletingItemId = null;
        });
      }
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
  // BUILD SCREEN
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
          ? const Center(
        child: CircularProgressIndicator(),
      )
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
                style: TextStyle(
                  color: Colors.grey,
                ),
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
          final isDeleting =
              _deletingItemId == item.id;

          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              contentPadding:
              const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 6,
              ),
              leading: CircleAvatar(
                backgroundColor:
                Colors.blueGrey.shade50,
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
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Category: ${item.category}',
                ),
              ),
              trailing: isDeleting
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
                    onPressed:
                    _deletingItemId != null ||
                        _isSaving
                        ? null
                        : () => _showEditItemDialog(
                      item,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Delete item',
                    icon: const Icon(
                      IconlyLight.delete,
                      color: Colors.redAccent,
                    ),
                    onPressed:
                    _deletingItemId != null ||
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
        onPressed:
        _isSaving || _deletingItemId != null
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