import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../../model/shop_model.dart';
import '../../providers/shop_provider.dart';
import '../../services/location_service.dart';

class ShopMapScreen extends StatefulWidget {
  const ShopMapScreen({super.key});

  @override
  State<ShopMapScreen> createState() => _ShopMapScreenState();
}

class _ShopMapScreenState extends State<ShopMapScreen> {
  GoogleMapController? _mapController;
  Position? _currentPosition;
  final Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  Future<void> _determinePosition() async {
    try {
      Position? position = await LocationService.getCurrentLocation();
      if (mounted) {
        setState(() {
          _currentPosition = position;
        });
      }
      if (position != null && _mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(
            LatLng(position.latitude, position.longitude),
            14,
          ),
        );
      } else if (position == null && _mapController != null) {
        _fitShopsInView();
      }
    } catch (e) {
      debugPrint("Location error: $e");
      _fitShopsInView();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not access your location. Showing all shops.")),
        );
      }
    }
  }

  void _fitShopsInView() {
    if (_markers.isEmpty || _mapController == null) return;

    double minLat = 90, maxLat = -90, minLng = 180, maxLng = -180;
    for (var m in _markers) {
      if (m.position.latitude < minLat) minLat = m.position.latitude;
      if (m.position.latitude > maxLat) maxLat = m.position.latitude;
      if (m.position.longitude < minLng) minLng = m.position.longitude;
      if (m.position.longitude > maxLng) maxLng = m.position.longitude;
    }

    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat - 0.01, minLng - 0.01),
          northeast: LatLng(maxLat + 0.01, maxLng + 0.01),
        ),
        50,
      ),
    );
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    _updateMarkers();
    // After markers are updated, if we don't have position, fit them
    if (_currentPosition == null) {
      _fitShopsInView();
    }
  }

  void _updateMarkers() {
    final shopProvider = Provider.of<ShopProvider>(context, listen: false);
    final shops = shopProvider.shops;

    setState(() {
      _markers.clear();
      for (var shop in shops) {
        if (shop.latitude != null && shop.longitude != null) {
          _markers.add(
            Marker(
              markerId: MarkerId(shop.id),
              position: LatLng(shop.latitude!, shop.longitude!),
              infoWindow: InfoWindow(
                title: shop.name,
                snippet: shop.location,
                onTap: () => _showShopDetails(shop),
              ),
            ),
          );
        }
      }
    });
  }

  void _showShopDetails(Shop shop) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        double? distance;
        if (_currentPosition != null && shop.latitude != null && shop.longitude != null) {
          distance = LocationService.calculateDistance(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
            shop.latitude!,
            shop.longitude!,
          );
        }

        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      shop.name,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  if (shop.isVerified)
                    const Icon(Icons.verified, color: Colors.blue, size: 20),
                ],
              ),
              const SizedBox(height: 8),
              Text(shop.location, style: const TextStyle(color: Colors.grey)),
              Text("Campus: ${shop.campus}"),
              if (distance != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    "Distance: ${distance.toStringAsFixed(2)} km away",
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                  ),
                ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        if (shop.latitude != null && shop.longitude != null) {
                          LocationService.navigateTo(shop.latitude!, shop.longitude!);
                        }
                      },
                      icon: const Icon(Icons.navigation),
                      label: const Text("NAVIGATE"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[700],
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Shop Map"),
        backgroundColor: Colors.green[800],
        foregroundColor: Colors.white,
      ),
      body: GoogleMap(
        initialCameraPosition: const CameraPosition(
          target: LatLng(6.5244, 3.3792), // Default center
          zoom: 12,
        ),
        onMapCreated: _onMapCreated,
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
        markers: _markers,
      ),
    );
  }
}
