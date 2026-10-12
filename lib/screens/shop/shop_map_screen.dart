import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../model/shop_model.dart';
import '../../providers/shop_provider.dart';
import '../../services/location_service.dart';

class ShopMapScreen extends StatefulWidget {
  const ShopMapScreen({super.key});

  @override
  State<ShopMapScreen> createState() => _ShopMapScreenState();
}

class _ShopMapScreenState extends State<ShopMapScreen> {
  final MapController _mapController = MapController();

  Position? _currentPosition;

  StreamSubscription<Position>? _positionSubscription;

  bool _mapReady = false;
  bool _isGettingLocation = false;
  bool _hasAttemptedLocation = false;

  // Approximate centre of UDUS main campus.
  static const LatLng _campusCenter = LatLng(13.127, 5.205);

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _determinePosition();
      }
    });
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _mapController.dispose();

    super.dispose();
  }

  // Get the user's current location.
  Future<void> _determinePosition() async {
    if (_isGettingLocation) return;

    setState(() {
      _isGettingLocation = true;
    });

    try {
      final position = await LocationService.getCurrentLocation();

      if (!mounted || position == null) return;

      setState(() {
        _currentPosition = position;
        _hasAttemptedLocation = true;
      });

      if (_mapReady) {
        _mapController.move(LatLng(position.latitude, position.longitude), 16);
      }

      _startLocationUpdates();
    } catch (e) {
      debugPrint('Location error: $e');

      if (!mounted) return;

      setState(() {
        _hasAttemptedLocation = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not access your location. '
            'Check location permissions and try again.',
          ),
          action: SnackBarAction(label: 'RETRY', onPressed: _determinePosition),
        ),
      );

      if (_mapReady) {
        _fitShopsInView(showMessage: false);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGettingLocation = false;
        });
      }
    }
  }

  // Keep the user's location updated while moving.
  void _startLocationUpdates() {
    _positionSubscription?.cancel();

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );

    _positionSubscription =
        Geolocator.getPositionStream(locationSettings: locationSettings).listen(
          (Position position) {
            if (!mounted) return;

            setState(() {
              _currentPosition = position;
            });
          },
          onError: (Object error) {
            debugPrint('Location stream error: $error');
          },
        );
  }

  // Return the map to the user's current location.
  void _goToMyLocation() {
    if (_currentPosition == null) {
      _determinePosition();
      return;
    }

    if (!_mapReady) return;

    _mapController.move(
      LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
      16,
    );
  }

  // Show all shops with saved coordinates.
  void _fitShopsInView({bool showMessage = true}) {
    if (!_mapReady) return;

    final shops = context.read<ShopProvider>().shops;

    final locations = shops
        .where((shop) => shop.latitude != null && shop.longitude != null)
        .map((shop) => LatLng(shop.latitude!, shop.longitude!))
        .toList();

    if (locations.isEmpty) {
      if (showMessage && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No shops with saved coordinates were found.'),
          ),
        );
      }

      // Keep the map usable even when no shop coordinates exist.
      _mapController.move(
        _currentPosition == null
            ? _campusCenter
            : LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        14,
      );

      return;
    }

    // Include the user's location when fitting the map.
    if (_currentPosition != null) {
      locations.add(
        LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
      );
    }

    double minLat = locations.first.latitude;
    double maxLat = locations.first.latitude;
    double minLng = locations.first.longitude;
    double maxLng = locations.first.longitude;

    for (final location in locations) {
      if (location.latitude < minLat) {
        minLat = location.latitude;
      }

      if (location.latitude > maxLat) {
        maxLat = location.latitude;
      }

      if (location.longitude < minLng) {
        minLng = location.longitude;
      }

      if (location.longitude > maxLng) {
        maxLng = location.longitude;
      }
    }

    // Avoid invalid bounds when locations overlap.
    if ((maxLat - minLat).abs() < 0.002) {
      minLat -= 0.002;
      maxLat += 0.002;
    }

    if ((maxLng - minLng).abs() < 0.002) {
      minLng -= 0.002;
      maxLng += 0.002;
    }

    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds(LatLng(minLat, minLng), LatLng(maxLat, maxLng)),
        padding: const EdgeInsets.all(60),
      ),
    );
  }

  // Open the shop details.
  void _showShopDetails(Shop shop) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
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

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        shop.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (shop.isVerified)
                      const Icon(Icons.verified, color: Colors.blue, size: 20),
                  ],
                ),
                const SizedBox(height: 8),
                Text(shop.location, style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 4),
                Text('Campus: ${shop.campus}'),
                if (distance != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'Distance: '
                      '${distance.toStringAsFixed(2)} km away',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      if (shop.latitude == null || shop.longitude == null) {
                        return;
                      }

                      try {
                        await LocationService.navigateTo(
                          shop.latitude!,
                          shop.longitude!,
                        );
                      } catch (e) {
                        if (!sheetContext.mounted) return;

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Could not open navigation.'),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.navigation),
                    label: const Text('NAVIGATE'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shop Map'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'My location',
            onPressed: _isGettingLocation ? null : _goToMyLocation,
            icon: _isGettingLocation
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.my_location),
          ),
        ],
      ),
      body: Consumer<ShopProvider>(
        builder: (context, shopProvider, child) {
          final markers = <Marker>[];

          // Add markers for shops with saved coordinates.
          for (final shop in shopProvider.shops) {
            if (shop.latitude == null || shop.longitude == null) {
              continue;
            }

            markers.add(
              Marker(
                point: LatLng(shop.latitude!, shop.longitude!),
                width: 45,
                height: 55,
                child: GestureDetector(
                  onTap: () => _showShopDetails(shop),
                  child: const Icon(
                    Icons.location_on,
                    color: Colors.red,
                    size: 45,
                  ),
                ),
              ),
            );
          }

          // Add the user's current location marker.
          if (_currentPosition != null) {
            markers.add(
              Marker(
                point: LatLng(
                  _currentPosition!.latitude,
                  _currentPosition!.longitude,
                ),
                width: 50,
                height: 50,
                child: const Icon(
                  Icons.my_location,
                  color: Colors.blue,
                  size: 35,
                ),
              ),
            );
          }

          return Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _campusCenter,
                  initialZoom: 14,
                  onMapReady: () {
                    _mapReady = true;

                    if (_currentPosition != null) {
                      _mapController.move(
                        LatLng(
                          _currentPosition!.latitude,
                          _currentPosition!.longitude,
                        ),
                        16,
                      );
                    } else if (_hasAttemptedLocation) {
                      _fitShopsInView(showMessage: false);
                    }
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.campus_price_monitor',
                  ),
                  MarkerLayer(markers: markers),
                  RichAttributionWidget(
                    attributions: [
                      TextSourceAttribution(
                        'OpenStreetMap contributors',
                        onTap: () {
                          launchUrl(
                            Uri.parse(
                              'https://www.openstreetmap.org/copyright',
                            ),
                            mode: LaunchMode.externalApplication,
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),

              // Show a useful message while obtaining location.
              if (_isGettingLocation)
                Positioned(
                  top: 12,
                  left: 12,
                  right: 12,
                  child: IgnorePointer(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [
                          BoxShadow(color: Colors.black12, blurRadius: 6),
                        ],
                      ),
                      child: const Row(
                        children: [
                          SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text('Finding your current location...'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // Explain why the location marker is unavailable.
              if (_hasAttemptedLocation && _currentPosition == null)
                Positioned(
                  top: 12,
                  left: 12,
                  right: 12,
                  child: Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.location_disabled,
                            color: Colors.orange,
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              'Your location is unavailable. '
                              'Shop markers can still be viewed.',
                            ),
                          ),
                          TextButton(
                            onPressed: _determinePosition,
                            child: const Text('RETRY'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.small(
            heroTag: 'my_location_button',
            onPressed: _goToMyLocation,
            backgroundColor: Colors.white,
            foregroundColor: Colors.green,
            tooltip: 'My location',
            child: const Icon(Icons.my_location),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'all_shops_button',
            onPressed: () => _fitShopsInView(),
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            tooltip: 'Show all shops',
            child: const Icon(Icons.store),
          ),
        ],
      ),
    );
  }
}
