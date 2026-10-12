
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';

import '../../model/shop_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/price_provider.dart';
import '../../services/location_service.dart';
import 'report_price_screen.dart';

class ShopDetailScreen extends StatefulWidget {
final Shop shop;

const ShopDetailScreen({
super.key,
required this.shop,
});

@override
State<ShopDetailScreen> createState() => _ShopDetailScreenState();
}

class _ShopDetailScreenState extends State<ShopDetailScreen> {
Position? _currentPosition;

// Distance from the right and bottom edges of the screen.
double _right = 16;
double _bottom = 24;

static const double _buttonHeight = 56;
static const double _buttonWidth = 165;
static const double _edgePadding = 8;

@override
void initState() {
super.initState();
_loadLocation();
}

Future<void> _loadLocation() async {
try {
final position = await LocationService.getCurrentLocation();

if (!mounted) return;

setState(() {
_currentPosition = position;
});
} catch (e) {
debugPrint('Could not get location: $e');
}
}

void _onButtonDragged(
DragUpdateDetails details,
Size screenSize,
) {
setState(() {
// Dragging right decreases the right-edge distance.
_right = (_right - details.delta.dx).clamp(
_edgePadding,
screenSize.width - _buttonWidth - _edgePadding,
);

// Dragging down decreases the bottom-edge distance.
_bottom = (_bottom - details.delta.dy).clamp(
_edgePadding,
screenSize.height - _buttonHeight - kToolbarHeight - 40,
);
});
}

@override
Widget build(BuildContext context) {
final priceProvider = context.watch<PriceProvider>();

final shopPrices = priceProvider.prices
    .where((price) => price.shopId == widget.shop.id)
    .toList()
..sort((a, b) => a.price.compareTo(b.price));

final user = context.watch<AuthProvider>().userModel;

return Scaffold(
appBar: AppBar(
title: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
const Text(
'Welcome to',
style: TextStyle(
fontSize: 11,
fontStyle: FontStyle.italic,
fontWeight: FontWeight.w300,
),
),
Text(
"${widget.shop.name}'s shop",
style: const TextStyle(
fontSize: 14,
fontWeight: FontWeight.bold,
),
),
],
),
backgroundColor: Colors.teal,
foregroundColor: Colors.white,
),

body: LayoutBuilder(
builder: (context, constraints) {
final screenSize = MediaQuery.of(context).size;

// Keep the button within the available screen bounds.
final maxRight = (constraints.maxWidth -
_buttonWidth -
_edgePadding)
    .clamp(0.0, double.infinity);

final maxBottom = (constraints.maxHeight -
_buttonHeight -
_edgePadding)
    .clamp(0.0, double.infinity);

_right = _right.clamp(_edgePadding, maxRight);
_bottom = _bottom.clamp(_edgePadding, maxBottom);

return Stack(
children: [
// Main shop content.
Column(
children: [
_buildShopHeader(),

Padding(
padding: const EdgeInsets.all(15),
child: Row(
mainAxisAlignment:
MainAxisAlignment.spaceBetween,
children: [
const Text(
'Items & Prices',
style: TextStyle(
fontSize: 14,
fontWeight: FontWeight.bold,
),
),
Text(
'${shopPrices.length} Items',
style: const TextStyle(
color: Colors.teal,
fontWeight: FontWeight.bold,
fontSize: 12,
),
),
],
),
),

Expanded(
child: shopPrices.isEmpty
? _buildEmptyState()
    : ListView.builder(
// Extra space lets users scroll the final
// item clear of the floating button.
padding: const EdgeInsets.fromLTRB(
15,
0,
15,
100,
),
itemCount: shopPrices.length,
itemBuilder: (context, index) {
final price = shopPrices[index];

return Card(
elevation: 2,
margin: const EdgeInsets.only(
bottom: 12,
),
shape: RoundedRectangleBorder(
borderRadius:
BorderRadius.circular(12),
),
child: ListTile(
leading: CircleAvatar(
backgroundColor:
Colors.orange.shade100,
child: const Icon(
Icons.fastfood,
color: Colors.teal,
size: 20,
),
),
title: Text(
price.itemId,
style: const TextStyle(
fontWeight: FontWeight.bold,
fontSize: 15,
),
),
subtitle: Text(
'Updated: ${DateFormat('MMM d, yyyy').format(price.updatedAt)}',
style: TextStyle(
fontSize: 11,
color: Colors.grey.shade600,
),
),
trailing: Text(
'₦${price.price.toStringAsFixed(0)}',
style: const TextStyle(
fontSize: 20,
fontWeight: FontWeight.bold,
color: Colors.teal,
),
),
),
);
},
),
),
],
),

// Draggable Report Price button.
if (user?.isAdmin == false)
Positioned(
right: _right,
bottom: _bottom,
child: GestureDetector(
onPanUpdate: (details) {
_onButtonDragged(details, screenSize);
},
child: Material(
color: Colors.teal,
elevation: 6,
borderRadius: BorderRadius.circular(30),
child: InkWell(
borderRadius: BorderRadius.circular(30),
onTap: () {
Navigator.push(
context,
MaterialPageRoute(
builder: (_) => ReportPriceScreen(
initialShopId: widget.shop.id,
),
),
);
},
child: const SizedBox(
width: _buttonWidth,
height: _buttonHeight,
child: Row(
mainAxisAlignment: MainAxisAlignment.center,
children: [
Icon(
Icons.add_chart,
color: Colors.white,
),
SizedBox(width: 8),
Text(
'Report Price',
style: TextStyle(
color: Colors.white,
fontWeight: FontWeight.bold,
),
),
],
),
),
),
),
),
),
],
);
},
),
);
}

Widget _buildShopHeader() {
double? distance;

if (_currentPosition != null &&
widget.shop.latitude != null &&
widget.shop.longitude != null) {
distance = LocationService.calculateDistance(
_currentPosition!.latitude,
_currentPosition!.longitude,
widget.shop.latitude!,
widget.shop.longitude!,
);
}

return Container(
padding: const EdgeInsets.all(20),
width: double.infinity,
decoration: BoxDecoration(
color: Colors.teal.withOpacity(0.1),
border: Border(
bottom: BorderSide(
color: Colors.green.shade100,
),
),
),
child: Column(
children: [
const CircleAvatar(
radius: 35,
backgroundColor: Colors.white,
child: Icon(
Icons.store,
size: 40,
color: Colors.teal,
),
),
const SizedBox(height: 12),
Text(
widget.shop.name,
style: const TextStyle(
fontSize: 22,
fontWeight: FontWeight.bold,
),
),
const SizedBox(height: 4),
Text(
'${widget.shop.location} (${widget.shop.campus})',
style: TextStyle(
color: Colors.grey.shade700,
),
),
if (distance != null)
Padding(
padding: const EdgeInsets.only(top: 8),
child: Text(
'${distance.toStringAsFixed(2)} km away',
style: const TextStyle(
color: Colors.green,
fontWeight: FontWeight.bold,
),
),
),
const SizedBox(height: 16),
if (widget.shop.latitude != null &&
widget.shop.longitude != null)
ElevatedButton.icon(
onPressed: () => LocationService.navigateTo(
widget.shop.latitude!,
widget.shop.longitude!,
),
icon: const Icon(Icons.directions),
label: const Text('GET DIRECTIONS'),
style: ElevatedButton.styleFrom(
backgroundColor: Colors.green,
foregroundColor: Colors.white,
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(30),
),
),
),
],
),
);
}

Widget _buildEmptyState() {
return Center(
child: Column(
mainAxisAlignment: MainAxisAlignment.center,
children: [
Icon(
Icons.inventory_2_outlined,
size: 60,
color: Colors.grey.shade300,
),
const SizedBox(height: 10),
const Text('No prices reported for this shop yet.'),
],
),
);
}
}
