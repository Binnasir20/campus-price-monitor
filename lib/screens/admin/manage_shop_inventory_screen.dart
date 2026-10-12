
import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'package:provider/provider.dart';

import '../../model/item_model.dart';
import '../../model/price_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/item_provider.dart';
import '../../providers/price_provider.dart';
import '../../providers/shop_provider.dart';

class ManageShopInventoryScreen extends StatefulWidget {
const ManageShopInventoryScreen({super.key});

@override
State<ManageShopInventoryScreen> createState() =>
_ManageShopInventoryScreenState();
}

class _ManageShopInventoryScreenState
extends State<ManageShopInventoryScreen> {
String? _selectedShopId;
bool _isSaving = false;

static const Color _primaryColor = Color(0xFF00897B);

@override
void initState() {
super.initState();

WidgetsBinding.instance.addPostFrameCallback((_) {
if (!mounted) return;

final user = context.read<AuthProvider>().userModel;

if (user == null) return;

context.read<ItemProvider>().fetchItems();

context.read<PriceProvider>().fetchPricesByUniversity(
user.university,
);

context.read<ShopProvider>().fetchShopsByUniversity(
user.university,
user.uid,
isAdmin: user.isAdmin,
);
});
}

@override
Widget build(BuildContext context) {
final user = context.watch<AuthProvider>().userModel;
final shops = context.watch<ShopProvider>().shops;
final items = context.watch<ItemProvider>().items;
final prices = context.watch<PriceProvider>().prices;

if (user == null || !user.isAdmin) {
return Scaffold(
appBar: AppBar(title: const Text('Shop Inventory')),
body: const Center(
child: Text('You are not authorized to access this screen.'),
),
);
}

final selectedShopExists =
shops.any((shop) => shop.id == _selectedShopId);

final selectedShopId = selectedShopExists ? _selectedShopId : null;

// Match each item ID to its catalogue item.
final itemMap = {
for (final item in items) item.id: item,
};

// Show only current prices belonging to existing items
// in the selected shop and university.
final shopPrices = selectedShopId == null
? <Price>[]
    : prices.where((price) {
return price.shopId == selectedShopId &&
price.university == user.university &&
itemMap.containsKey(price.itemId);
}).toList()
..sort((a, b) => a.price.compareTo(b.price));

return Scaffold(
appBar: AppBar(
title: const Text('Shop Inventory'),
backgroundColor: _primaryColor,
foregroundColor: Colors.white,
),
body: Column(
children: [
Padding(
padding: const EdgeInsets.all(16),
child: DropdownButtonFormField<String>(
value: selectedShopId,
isExpanded: true,
decoration: InputDecoration(
labelText: 'Select Shop',
prefixIcon: const Icon(IconlyLight.home),
border: OutlineInputBorder(
borderRadius: BorderRadius.circular(12),
),
),
hint: const Text('Choose a shop'),
items: shops.map((shop) {
return DropdownMenuItem<String>(
value: shop.id,
child: Text(
shop.name,
overflow: TextOverflow.ellipsis,
),
);
}).toList(),
onChanged: _isSaving
? null
    : (shopId) {
setState(() => _selectedShopId = shopId);
},
),
),
if (selectedShopId != null)
Padding(
padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
child: Row(
children: [
const Icon(
IconlyLight.bag,
color: _primaryColor,
),
const SizedBox(width: 8),
Text(
'${shopPrices.length} items in this shop',
style: const TextStyle(
fontWeight: FontWeight.w600,
),
),
],
),
),
Expanded(
child: selectedShopId == null
? const Center(
child: Text('Select a shop to manage its inventory.'),
)
    : shopPrices.isEmpty
? const Center(
child: Column(
mainAxisSize: MainAxisSize.min,
children: [
Icon(
IconlyLight.bag,
size: 48,
color: Colors.grey,
),
SizedBox(height: 12),
Text('No items found in this shop.'),
],
),
)
    : RefreshIndicator(
onRefresh: () async {
await context
    .read<PriceProvider>()
    .fetchPricesByUniversity(user.university);

await context.read<ItemProvider>().fetchItems();
},
child: ListView.builder(
padding: const EdgeInsets.fromLTRB(
16,
0,
16,
16,
),
itemCount: shopPrices.length,
itemBuilder: (context, index) {
final price = shopPrices[index];
final item = itemMap[price.itemId]!;

return Card(
margin: const EdgeInsets.only(bottom: 12),
elevation: 1,
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(12),
),
child: ListTile(
contentPadding: const EdgeInsets.all(12),
leading: CircleAvatar(
backgroundColor:
_primaryColor.withValues(alpha: 0.12),
child: const Icon(
IconlyLight.bag,
color: _primaryColor,
),
),
title: Text(
item.name,
style: const TextStyle(
fontWeight: FontWeight.w600,
),
),
subtitle: Padding(
padding: const EdgeInsets.only(top: 6),
child: Text(
'₦${price.price.toStringAsFixed(2)}',
style: const TextStyle(
color: _primaryColor,
fontWeight: FontWeight.bold,
fontSize: 16,
),
),
),
trailing: PopupMenuButton<String>(
enabled: !_isSaving,
onSelected: (action) {
if (action == 'edit') {
_editPrice(price, item);
} else if (action == 'remove') {
_removeItem(price, item);
}
},
itemBuilder: (context) => const [
PopupMenuItem(
value: 'edit',
child: Row(
children: [
Icon(IconlyLight.edit),
SizedBox(width: 8),
Text('Edit Price'),
],
),
),
PopupMenuItem(
value: 'remove',
child: Row(
children: [
Icon(
IconlyLight.delete,
color: Colors.red,
),
SizedBox(width: 8),
Text('Remove from Shop'),
],
),
),
],
),
),
);
},
),
),
),
if (_isSaving) const LinearProgressIndicator(),
],
),
);
}

Future<void> _editPrice(Price price, Item item) async {
if (_isSaving) return;

final controller = TextEditingController(
text: price.price.toStringAsFixed(2),
);

final formKey = GlobalKey<FormState>();

final newPrice = await showDialog<double>(
context: context,
builder: (dialogContext) {
return AlertDialog(
title: Text('Edit ${item.name} Price'),
content: Form(
key: formKey,
child: TextFormField(
controller: controller,
autofocus: true,
keyboardType: const TextInputType.numberWithOptions(
decimal: true,
),
decoration: const InputDecoration(
labelText: 'New Price',
prefixText: '₦ ',
border: OutlineInputBorder(),
),
validator: (value) {
final amount = double.tryParse(value?.trim() ?? '');

if (amount == null ||
!amount.isFinite ||
amount <= 0) {
return 'Enter a valid price greater than zero.';
}

return null;
},
),
),
actions: [
TextButton(
onPressed: () => Navigator.pop(dialogContext),
child: const Text('Cancel'),
),
FilledButton(
onPressed: () {
if (!formKey.currentState!.validate()) return;

final amount = double.parse(controller.text.trim());
Navigator.pop(dialogContext, amount);
},
child: const Text('Save'),
),
],
);
},
);

controller.dispose();

if (newPrice == null || !mounted) return;

setState(() => _isSaving = true);

try {
final updatedPrice = Price(
id: price.id,
itemId: price.itemId,
shopId: price.shopId,
university: price.university,
price: newPrice,
updatedAt: DateTime.now(),
reportedBy: price.reportedBy,
);

final success = await context
    .read<PriceProvider>()
    .updateCurrentPrice(updatedPrice);

if (!mounted) return;

ScaffoldMessenger.of(context).showSnackBar(
SnackBar(
content: Text(
success
? '${item.name} price updated successfully.'
    : context.read<PriceProvider>().errorMessage ??
'Failed to update price.',
),
),
);
} catch (e) {
if (!mounted) return;

ScaffoldMessenger.of(context).showSnackBar(
SnackBar(content: Text('Failed to update price: $e')),
);
} finally {
if (mounted) setState(() => _isSaving = false);
}
}

Future<void> _removeItem(Price price, Item item) async {
if (_isSaving) return;

final confirmed = await showDialog<bool>(
context: context,
builder: (dialogContext) {
return AlertDialog(
title: const Text('Remove Item from Shop?'),
content: Text(
'Remove "${item.name}" from this shop?\n\n'
'Only its current price record for this shop will be removed. '
'The catalogue item, other shops, and historical reports '
'will remain unchanged.',
),
actions: [
TextButton(
onPressed: () => Navigator.pop(dialogContext, false),
child: const Text('Cancel'),
),
FilledButton(
style: FilledButton.styleFrom(
backgroundColor: Colors.red,
),
onPressed: () => Navigator.pop(dialogContext, true),
child: const Text('Remove'),
),
],
);
},
);

if (confirmed != true || !mounted) return;

setState(() => _isSaving = true);

try {
final success =
await context.read<PriceProvider>().removeItemFromShop(
itemId: price.itemId,
shopId: price.shopId,
);

if (!mounted) return;

ScaffoldMessenger.of(context).showSnackBar(
SnackBar(
content: Text(
success
? '${item.name} removed from this shop.'
    : context.read<PriceProvider>().errorMessage ??
'Failed to remove item.',
),
),
);
} catch (e) {
if (!mounted) return;

ScaffoldMessenger.of(context).showSnackBar(
SnackBar(content: Text('Failed to remove item: $e')),
);
} finally {
if (mounted) setState(() => _isSaving = false);
}
}
}
