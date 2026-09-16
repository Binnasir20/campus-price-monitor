import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../services/location_service.dart';

class LocationPickerScreen extends StatefulWidget {
  final double? initialLat;
  final double? initialLng;

  const LocationPickerScreen({super.key, this.initialLat, this.initialLng});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  LatLng? _pickedLocation;
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    if (widget.initialLat != null && widget.initialLng != null) {
      _pickedLocation = LatLng(widget.initialLat!, widget.initialLng!);
    }
  }

  void _onMapTap(LatLng location) {
    setState(() {
      _pickedLocation = location;
    });
  }

  Future<void> _goToCurrentLocation() async {
    try {
      Position? position = await LocationService.getCurrentLocation();
      if (position != null && _mapController != null) {
        final newLocation = LatLng(position.latitude, position.longitude);
        _mapController!.animateCamera(CameraUpdate.newLatLngZoom(newLocation, 16));
        setState(() {
          _pickedLocation = newLocation;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Select Shop Location"),
        actions: [
          if (_pickedLocation != null)
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: () => Navigator.pop(context, _pickedLocation),
            ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _pickedLocation ?? const LatLng(6.5244, 3.3792), // Default to Lagos, Nigeria if no loc
              zoom: 15,
            ),
            onMapCreated: (controller) => _mapController = controller,
            onTap: _onMapTap,
            markers: _pickedLocation == null
                ? {}
                : {
                    Marker(
                      markerId: const MarkerId("picked"),
                      position: _pickedLocation!,
                    ),
                  },
          ),
          Positioned(
            bottom: 20,
            left: 20,
            child: FloatingActionButton(
              heroTag: "current_loc",
              onPressed: _goToCurrentLocation,
              child: const Icon(Icons.my_location),
            ),
          ),
          if (_pickedLocation == null)
            const Positioned(
              top: 20,
              left: 0,
              right: 0,
              child: Center(
                child: Card(
                  color: Colors.black54,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      "Tap on the map to place the shop marker",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
