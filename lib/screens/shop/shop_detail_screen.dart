import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../../model/shop_model.dart';
import '../../providers/price_provider.dart';
import '../../services/location_service.dart';
import 'package:intl/intl.dart';
import 'report_price_screen.dart';

class ShopDetailScreen extends StatefulWidget {
  final Shop shop;

  const ShopDetailScreen({super.key, required this.shop});

  @override
  State<ShopDetailScreen> createState() => _ShopDetailScreenState();
}

class _ShopDetailScreenState extends State<ShopDetailScreen> {
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _loadLocation();
  }

  void _loadLocation() async {
    try {
      Position? position = await LocationService.getCurrentLocation();
      if (mounted) {
        setState(() {
          _currentPosition = position;
        });
      }
    } catch (e) {
      debugPrint("Could not get location: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final priceProv = Provider.of<PriceProvider>(context);
    final shopPrices = priceProv.prices.where((p) => p.shopId == widget.shop.id).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.shop.name),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          _buildShopHeader(),

          Padding(
            padding: const EdgeInsets.all(15.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Items & Prices",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  "${shopPrices.length} Items",
                  style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),

          Expanded(
            child: shopPrices.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              itemCount: shopPrices.length,
              itemBuilder: (context, index) {
                final price = shopPrices[index];
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.orange.shade100,
                      child: const Icon(Icons.fastfood, color: Colors.orange, size: 20),
                    ),
                    title: Text(price.itemId, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                      "Updated: ${DateFormat('MMM d, yyyy').format(price.updatedAt)}",
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                    trailing: Text(
                      "₦${price.price.toStringAsFixed(0)}",
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ReportPriceScreen(initialShopId: widget.shop.id),
            ),
          );
        },
        label: const Text("Report Price"),
        icon: const Icon(Icons.add_chart),
        backgroundColor: Colors.green,
      ),
    );
  }

  Widget _buildShopHeader() {
    double? distance;
    if (_currentPosition != null && widget.shop.latitude != null && widget.shop.longitude != null) {
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
        color: Colors.green.shade50,
        border: Border(bottom: BorderSide(color: Colors.green.shade100)),
      ),
      child: Column(
        children: [
          const CircleAvatar(
            radius: 35,
            backgroundColor: Colors.white,
            child: Icon(Icons.store, size: 40, color: Colors.green),
          ),
          const SizedBox(height: 12),
          Text(widget.shop.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text("${widget.shop.location} (${widget.shop.campus})", style: TextStyle(color: Colors.grey.shade700)),
          if (distance != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                "${distance.toStringAsFixed(2)} km away",
                style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
              ),
            ),
          const SizedBox(height: 16),
          if (widget.shop.latitude != null)
            ElevatedButton.icon(
              onPressed: () => LocationService.navigateTo(widget.shop.latitude!, widget.shop.longitude!),
              icon: const Icon(Icons.directions),
              label: const Text("GET DIRECTIONS"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[700],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
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
          Icon(Icons.inventory_2_outlined, size: 60, color: Colors.grey.shade300),
          const SizedBox(height: 10),
          const Text("No prices reported for this shop yet."),
        ],
      ),
    );
  }
}
