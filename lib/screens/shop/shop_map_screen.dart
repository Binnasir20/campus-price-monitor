import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../model/shop_model.dart';
import '../../providers/shop_provider.dart';
import '../../services/location_service.dart';

class ShopMapScreen extends StatefulWidget {
  final Shop? initialShop;

  const ShopMapScreen({
    super.key,
    this.initialShop,
  });

  @override
  State<ShopMapScreen> createState() => _ShopMapScreenState();
}

class _ShopMapScreenState extends State<ShopMapScreen> {
  final MapController _mapController = MapController();

  Position? _currentPosition;
  StreamSubscription<Position>? _positionSubscription;

  Shop? _selectedShop;
  NavigationRoute? _navigationRoute;

  bool _mapReady = false;
  bool _isGettingLocation = false;
  bool _hasAttemptedLocation = false;
  bool _isCalculatingRoute = false;

  static const LatLng _campusCenter = LatLng(13.127, 5.205);

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      await _determinePosition();

      if (!mounted) return;

      final shop = widget.initialShop;

      if (shop != null) {
        await _startNavigation(shop);
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

      if (!mounted) return;

      setState(() {
        _currentPosition = position;
        _hasAttemptedLocation = true;
      });

      if (position != null) {
        if (_mapReady && _navigationRoute == null) {
          _mapController.move(
            LatLng(position.latitude, position.longitude),
            16,
          );
        }

        _startLocationUpdates();
      } else {
        _showMessage(
          'Your location is unavailable. Check your location settings.',
        );

        if (_mapReady) {
          _fitShopsInView(showMessage: false);
        }
      }
    } catch (e) {
      debugPrint('Location error: $e');

      if (!mounted) return;

      setState(() {
        _hasAttemptedLocation = true;
      });

      _showMessage(
        'Could not access your location. Check permissions and try again.',
        retry: _determinePosition,
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

  // Keep the user's location updated while the screen is open.
  void _startLocationUpdates() {
    _positionSubscription?.cancel();

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

        if (_selectedShop != null &&
            _navigationRoute != null &&
            !_isCalculatingRoute) {
          _updateRoute(position);
        }
      },
      onError: (Object error) {
        debugPrint('Location stream error: $error');
      },
    );
  }

  // Recalculate the route when the user moves significantly.
  Future<void> _updateRoute(Position position) async {
    final shop = _selectedShop;

    if (shop == null ||
        shop.latitude == null ||
        shop.longitude == null ||
        _isCalculatingRoute) {
      return;
    }

    final route = _navigationRoute;

    if (route != null && route.points.isNotEmpty) {
      final distanceMoved = Geolocator.distanceBetween(
        route.points.first.latitude,
        route.points.first.longitude,
        position.latitude,
        position.longitude,
      );

      if (distanceMoved < 50) return;
    }

    try {
      setState(() {
        _isCalculatingRoute = true;
      });

      final updatedRoute = await LocationService.getRoute(
        startLat: position.latitude,
        startLng: position.longitude,
        endLat: shop.latitude!,
        endLng: shop.longitude!,
      );

      if (!mounted || _selectedShop?.id != shop.id) return;

      setState(() {
        _navigationRoute = updatedRoute;
      });
    } catch (e) {
      debugPrint('Route update failed: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isCalculatingRoute = false;
        });
      }
    }
  }

  // Move the map to the user's current location.
  void _goToMyLocation() {
    if (_currentPosition == null) {
      _determinePosition();
      return;
    }

    if (!_mapReady) return;

    _mapController.move(
      LatLng(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      ),
      16,
    );
  }

  // Show all shops with saved coordinates.
  void _fitShopsInView({bool showMessage = true}) {
    if (!_mapReady) return;

    final shops = context.read<ShopProvider>().shops;

    final locations = shops
        .where(
          (shop) =>
      shop.latitude != null && shop.longitude != null,
    )
        .map(
          (shop) => LatLng(shop.latitude!, shop.longitude!),
    )
        .toList();

    if (locations.isEmpty) {
      if (showMessage && mounted) {
        _showMessage('No shops with saved coordinates were found.');
      }

      _mapController.move(
        _currentPosition == null
            ? _campusCenter
            : LatLng(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
        ),
        14,
      );

      return;
    }

    if (_currentPosition != null) {
      locations.add(
        LatLng(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
        ),
      );
    }

    double minLat = locations.first.latitude;
    double maxLat = locations.first.latitude;
    double minLng = locations.first.longitude;
    double maxLng = locations.first.longitude;

    for (final location in locations) {
      if (location.latitude < minLat) minLat = location.latitude;
      if (location.latitude > maxLat) maxLat = location.latitude;
      if (location.longitude < minLng) minLng = location.longitude;
      if (location.longitude > maxLng) maxLng = location.longitude;
    }

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
        bounds: LatLngBounds(
          LatLng(minLat, minLng),
          LatLng(maxLat, maxLng),
        ),
        padding: const EdgeInsets.all(60),
      ),
    );
  }

  // Calculate and display a route to a selected shop.
  Future<void> _startNavigation(Shop shop) async {
    if (shop.latitude == null || shop.longitude == null) {
      _showMessage('This shop has no saved coordinates.');
      return;
    }

    if (_isCalculatingRoute) return;

    setState(() {
      _selectedShop = shop;
      _navigationRoute = null;
      _isCalculatingRoute = true;
    });

    try {
      Position? position = _currentPosition;

      if (position == null) {
        position = await LocationService.getCurrentLocation();
      }

      if (!mounted) return;

      if (position == null) {
        throw Exception(
          'Your current location is unavailable. Enable location services and try again.',
        );
      }

      final route = await LocationService.getRoute(
        startLat: position.latitude,
        startLng: position.longitude,
        endLat: shop.latitude!,
        endLng: shop.longitude!,
      );

      if (!mounted) return;

      setState(() {
        _currentPosition = position;
        _navigationRoute = route;
      });

      if (_mapReady && route.points.isNotEmpty) {
        _mapController.fitCamera(
          CameraFit.coordinates(
            coordinates: route.points,
            padding: const EdgeInsets.fromLTRB(40, 100, 40, 220),
          ),
        );
      }

      _startLocationUpdates();
    } catch (e) {
      debugPrint('Navigation error: $e');

      if (!mounted) return;

      setState(() {
        _selectedShop = null;
        _navigationRoute = null;
      });

      _showMessage(
        'Could not calculate route. Check your internet connection and shop coordinates.',
        retry: () => _startNavigation(shop),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isCalculatingRoute = false;
        });
      }
    }
  }

  // Stop in-app navigation.
  void _stopNavigation() {
    setState(() {
      _selectedShop = null;
      _navigationRoute = null;
    });
  }

  // Display information about a shop.
  void _showShopDetails(Shop shop) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
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
                      const Icon(
                        Icons.verified,
                        color: Colors.blue,
                        size: 20,
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  shop.location,
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Text('Campus: ${shop.campus}'),
                if (distance != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'Distance: ${distance.toStringAsFixed(2)} km away',
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
                    onPressed: _isCalculatingRoute
                        ? null
                        : () {
                      Navigator.pop(sheetContext);
                      _startNavigation(shop);
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

  void _showMessage(String message, {VoidCallback? retry}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        action: retry == null
            ? null
            : SnackBarAction(
          label: 'RETRY',
          onPressed: retry,
        ),
      ),
    );
  }

  // Small reusable message card.
  Widget _messageCard(Widget leading, String message) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            SizedBox(
              width: 22,
              height: 22,
              child: Center(child: leading),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
      ),
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

          // Shop markers.
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
                  child: Icon(
                    Icons.location_on,
                    color: _selectedShop?.id == shop.id
                        ? Colors.green
                        : Colors.red,
                    size: 45,
                  ),
                ),
              ),
            );
          }

          // Current location marker.
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

                    if (_navigationRoute != null &&
                        _navigationRoute!.points.isNotEmpty) {
                      _mapController.fitCamera(
                        CameraFit.coordinates(
                          coordinates: _navigationRoute!.points,
                          padding: const EdgeInsets.fromLTRB(
                            40,
                            100,
                            40,
                            220,
                          ),
                        ),
                      );
                    } else if (_currentPosition != null) {
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
                    userAgentPackageName:
                    'com.example.campus_price_monitor',
                  ),

                  // Draw the calculated route.
                  if (_navigationRoute != null)
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: _navigationRoute!.points,
                          strokeWidth: 6,
                          color: Colors.blue,
                          borderStrokeWidth: 2,
                          borderColor: Colors.white,
                        ),
                      ],
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

              // Navigation information.
              if (_navigationRoute != null)
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 12,
                  child: Card(
                    elevation: 6,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Navigating to ${_selectedShop?.name ?? 'shop'}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(
                                Icons.route,
                                color: Colors.blue,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${_navigationRoute!.distanceInKilometres.toStringAsFixed(2)} km',
                                ),
                              ),
                              const Icon(
                                Icons.schedule,
                                color: Colors.blue,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${_navigationRoute!.estimatedMinutes} min',
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _stopNavigation,
                              icon: const Icon(Icons.close),
                              label: const Text('Stop Navigation'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // Location loading message.
              if (_isGettingLocation)
                Positioned(
                  top: 12,
                  left: 12,
                  right: 12,
                  child: _messageCard(
                    const CircularProgressIndicator(strokeWidth: 2),
                    'Finding your current location...',
                  ),
                ),

              // Route calculation message.
              if (_isCalculatingRoute)
                Positioned(
                  top: 75,
                  left: 12,
                  right: 12,
                  child: _messageCard(
                    const CircularProgressIndicator(strokeWidth: 2),
                    'Calculating route...',
                  ),
                ),

              // Location error message.
              if (_hasAttemptedLocation && _currentPosition == null)
                Positioned(
                  top: 12,
                  left: 12,
                  right: 12,
                  child: Card(
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