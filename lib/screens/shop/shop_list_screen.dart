
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';

import '../../constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/shop_provider.dart';
import '../../services/location_service.dart';
import 'shop_detail_screen.dart';
import 'add_shop_screen.dart';

class ShopListScreen extends StatefulWidget {
const ShopListScreen({super.key});

@override
State<ShopListScreen> createState() => _ShopListScreenState();
}

class _ShopListScreenState extends State<ShopListScreen> {
Position? _currentPosition;

StreamSubscription<Position>? _positionSubscription;

@override
void initState() {
super.initState();

WidgetsBinding.instance.addPostFrameCallback((_) {
_initData();
});
}

// Fetch shops and listen for the user's location updates.
Future<void> _initData() async {
if (!mounted) return;

final user = context.read<AuthProvider>().userModel;

if (user != null) {
await context.read<ShopProvider>().fetchShopsByUniversity(
user.university,
user.uid,
isAdmin: user.isAdmin,
);
}

if (!mounted) return;

try {
// Get the user's initial location.
final position = await LocationService.getCurrentLocation();

if (!mounted) return;

if (position != null) {
setState(() {
_currentPosition = position;
});
}

// Listen for subsequent location updates.
await _positionSubscription?.cancel();

_positionSubscription = Geolocator.getPositionStream(
locationSettings: const LocationSettings(
accuracy: LocationAccuracy.high,
distanceFilter: 10,
),
).listen(
(Position position) {
if (!mounted) return;

setState(() {
_currentPosition = position;
});
},
onError: (error) {
debugPrint('Location stream error: $error');
},
);
} catch (e) {
debugPrint('Could not get current location: $e');
}
}

// Open navigation to a shop.
Future<void> _navigateToShop(
double? latitude,
double? longitude,
) async {
if (latitude == null || longitude == null) {
ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(
content: Text('This shop has no saved coordinates.'),
),
);
return;
}

try {
await LocationService.navigateTo(latitude, longitude);
} catch (e) {
debugPrint('Navigation error: $e');

if (!mounted) return;

ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(
content: Text('Could not open navigation.'),
),
);
}
}

@override
void dispose() {
_positionSubscription?.cancel();
super.dispose();
}

@override
Widget build(BuildContext context) {
final shopProv = context.watch<ShopProvider>();
final user = context.watch<AuthProvider>().userModel;

return Scaffold(
backgroundColor: AppColors.background,
appBar: AppBar(
automaticallyImplyLeading: false,
title: Text(
'${user?.university ?? 'University'} Shops',
style: const TextStyle(
fontSize: 15,
fontWeight: FontWeight.bold,
),
),
backgroundColor: AppColors.primary,
foregroundColor: Colors.white,
),
body: shopProv.isLoading
? const Center(
child: CircularProgressIndicator(),
)
    : shopProv.shops.isEmpty
? _buildEmptyState()
    : ListView.builder(
padding: const EdgeInsets.all(12),
itemCount: shopProv.shops.length,
itemBuilder: (context, index) {
final shop = shopProv.shops[index];
final isPending = !shop.isVerified;

double? distance;

if (_currentPosition != null &&
shop.latitude != null &&
shop.longitude != null) {
distance = LocationService.calculateDistance(
_currentPosition!.latitude,
_currentPosition!.longitude,
shop.latitude!,
shop.longitude!,
);
}

return Card(
elevation: 2,
margin: const EdgeInsets.only(bottom: 12),
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(12),
),
child: ListTile(
contentPadding: const EdgeInsets.symmetric(
horizontal: 16,
vertical: 8,
),
leading: CircleAvatar(
backgroundColor: isPending
? AppColors.primary
    : Colors.white.withOpacity(0.1),
child: Icon(
isPending
? Icons.hourglass_top
    : IconlyLight.buy,
color: isPending
? AppColors.accent
    : AppColors.primary,
),
),
title: Text(
shop.name,
style: const TextStyle(
fontWeight: FontWeight.bold,
fontSize: 14,
),
),
subtitle: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Row(
children: [
const Text(
'Campus: ',
style: TextStyle(
fontSize: 13,
fontWeight: FontWeight.bold,
),
),
Expanded(
child: Text(
shop.campus,
style: TextStyle(
color: AppColors.accent,
fontWeight: FontWeight.w500,
fontSize: 12,
fontStyle: FontStyle.italic,
),
),
),
],
),
Row(
children: [
const Icon(
IconlyLight.location,
size: 15,
),
const SizedBox(width: 5),
Expanded(
child: Text(
shop.location,
style: const TextStyle(
fontSize: 12,
fontWeight: FontWeight.w500,
color: Colors.grey,
),
),
),
],
),

// Distance updates when the user's location changes.
if (distance != null)
Padding(
padding: const EdgeInsets.only(top: 4),
child: Row(
children: [
const Icon(
IconlyLight.location,
size: 14,
color: Colors.green,
),
const SizedBox(width: 4),
Text(
'${(distance / 1000).toStringAsFixed(2)} km away',
style: const TextStyle(
color: Colors.green,
fontWeight: FontWeight.bold,
fontSize: 12,
),
),
],
),
),

if (isPending)
const Padding(
padding: EdgeInsets.only(top: 4),
child: Text(
'Waiting for approval...',
style: TextStyle(
color: Colors.teal,
fontWeight: FontWeight.bold,
fontSize: 12,
),
),
),
],
),
trailing: Row(
mainAxisSize: MainAxisSize.min,
children: [
if (shop.latitude != null &&
shop.longitude != null)
IconButton(
tooltip: 'Get directions',
icon: const Icon(
Icons.directions,
color: Colors.blue,
),
onPressed: () => _navigateToShop(
shop.latitude,
shop.longitude,
),
),
const Icon(
Icons.arrow_forward_ios,
size: 16,
color: Colors.grey,
),
],
),
onTap: () {
Navigator.push(
context,
MaterialPageRoute(
builder: (_) => ShopDetailScreen(shop: shop),
),
);
},
),
);
},
),
floatingActionButton: FloatingActionButton.extended(
onPressed: () {
Navigator.push(
context,
MaterialPageRoute(
builder: (_) => const AddShopScreen(),
),
);
},
backgroundColor: AppColors.primary,
icon: const Icon(
IconlyLight.edit_square,
color: Colors.white,
),
label: const Text(
'Add Shop',
style: TextStyle(color: Colors.white),
),
),
);
}

Widget _buildEmptyState() {
return Center(
child: Column(
mainAxisAlignment: MainAxisAlignment.center,
children: [
Icon(
Icons.storefront_outlined,
size: 80,
color: Colors.grey[400],
),
const SizedBox(height: 16),
const Text(
'No shops found for your university',
style: TextStyle(
fontWeight: FontWeight.bold,
fontSize: 16,
),
),
const SizedBox(height: 8),
const Text('Be the first to add a shop!'),
],
),
);
}
}
