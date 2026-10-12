
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../services/location_service.dart';

class LocationPickerScreen extends StatefulWidget {
final double? initialLat;
final double? initialLng;

const LocationPickerScreen({
super.key,
this.initialLat,
this.initialLng,
});

@override
State<LocationPickerScreen> createState() =>
_LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
final MapController _mapController = MapController();

// Approximate reference point for UDUS main campus.
static const LatLng _campusCenter = LatLng(
13.127,
5.205,
);

// Maximum permitted distance from the campus centre.
static const double _allowedRadiusKm = 5.0;

// Approximate rectangular camera boundaries around the campus.
// The circular distance check below enforces the actual 5 km limit.
static final LatLngBounds _mapBounds = LatLngBounds(
const LatLng(13.075, 5.150),
const LatLng(13.179, 5.260),
);

late LatLng _mapCenter;

LatLng? _selectedLocation;

bool _isGettingLocation = false;
bool _mapReady = false;

double? _selectedDistanceKm;

@override
void initState() {
super.initState();

final hasInitialLocation =
widget.initialLat != null && widget.initialLng != null;

if (hasInitialLocation) {
final existingLocation = LatLng(
widget.initialLat!,
widget.initialLng!,
);

final distance = _distanceFromCampus(existingLocation);

if (distance <= _allowedRadiusKm) {
// Reopen the existing shop location when it is permitted.
_mapCenter = existingLocation;
_selectedLocation = existingLocation;
_selectedDistanceKm = distance;
} else {
// Do not silently accept a previously saved location
// outside the permitted radius.
_mapCenter = _campusCenter;
}
} else {
_mapCenter = _campusCenter;
}
}

double _distanceFromCampus(LatLng location) {
return const Distance().as(
LengthUnit.Kilometer,
_campusCenter,
location,
);
}

bool _isInsideAllowedArea(LatLng location) {
return _distanceFromCampus(location) <= _allowedRadiusKm;
}

// Move the map to the campus centre.
void _goToCampus() {
_mapController.move(_campusCenter, 14);
}

// Get the device's current location.
Future<void> _useCurrentLocation() async {
if (_isGettingLocation) return;

setState(() {
_isGettingLocation = true;
});

try {
final position = await LocationService.getCurrentLocation();

if (!mounted) return;

if (position == null) {
_showMessage(
'Could not determine your location. '
'You can select a shop manually on the map.',
);
return;
}

final location = LatLng(
position.latitude,
position.longitude,
);

if (!_isInsideAllowedArea(location)) {
_showMessage(
'Your current location is outside the permitted '
'5 km area around UDUS main campus. '
'Select the shop location manually instead.',
);

return;
}

setState(() {
_mapCenter = location;
_selectedLocation = location;
_selectedDistanceKm = _distanceFromCampus(location);
});

_mapController.move(location, 17);
} catch (e) {
debugPrint('Could not get current location: $e');

if (mounted) {
_showMessage(
'Could not get your location. '
'Check your device location permissions.',
);
}
} finally {
if (mounted) {
setState(() {
_isGettingLocation = false;
});
}
}
}

// Select a shop location by tapping the map.
void _selectLocation(
TapPosition tapPosition,
LatLng point,
) {
if (!_isInsideAllowedArea(point)) {
_showMessage(
'This location is outside the permitted area. '
'Choose a point within the 5 km circle around UDUS.',
);
return;
}

setState(() {
_selectedLocation = point;
_mapCenter = point;
_selectedDistanceKm = _distanceFromCampus(point);
});
}

// Confirm the selected coordinates.
void _confirmLocation() {
if (_selectedLocation == null) {
_showMessage(
'Select a shop location within the permitted area first.',
);
return;
}

if (!_isInsideAllowedArea(_selectedLocation!)) {
_showMessage(
'The selected location is outside the permitted area.',
);
return;
}

Navigator.pop(context, _selectedLocation);
}

void _showMessage(String message) {
if (!mounted) return;

ScaffoldMessenger.of(context)
..hideCurrentSnackBar()
..showSnackBar(
SnackBar(
content: Text(message),
behavior: SnackBarBehavior.floating,
),
);
}

@override
Widget build(BuildContext context) {
return Scaffold(
appBar: AppBar(
title: const Text(
'Select Shop Location',
style: TextStyle(fontSize: 17),
),
backgroundColor: Colors.teal,
foregroundColor: Colors.white,
actions: [
IconButton(
tooltip: 'Return to UDUS campus centre',
onPressed: _mapReady ? _goToCampus : null,
icon: const Icon(Icons.school_outlined),
),
],
),
body: Stack(
children: [
// Interactive OpenStreetMap.
FlutterMap(
mapController: _mapController,
options: MapOptions(
initialCenter: _mapCenter,
initialZoom: _selectedLocation == null ? 14 : 16,
cameraConstraint: CameraConstraint.contain(
bounds: _mapBounds,
),
onMapReady: () {
_mapReady = true;
},
onTap: _selectLocation,
),
children: [
TileLayer(
urlTemplate:
'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
userAgentPackageName:
'com.example.campus_price_monitor',
),

// Visually show the permitted 5 km radius.
CircleLayer(
circles: [
CircleMarker(
point: _campusCenter,
radius: _allowedRadiusKm * 1000,
useRadiusInMeter: true,
color: Colors.teal.withOpacity(0.12),
borderColor: Colors.teal,
borderStrokeWidth: 2,
),
],
),

// Campus reference point and selected shop location.
MarkerLayer(
markers: [
Marker(
point: _campusCenter,
width: 100,
height: 65,
child: const Column(
mainAxisSize: MainAxisSize.min,
children: [
Icon(
Icons.school,
color: Colors.teal,
size: 30,
),
Flexible(
child: Text(
'UDUS Campus',
textAlign: TextAlign.center,
maxLines: 1,
overflow: TextOverflow.ellipsis,
style: TextStyle(
fontSize: 10,
fontWeight: FontWeight.bold,
color: Colors.black,
backgroundColor: Colors.white,
),
),
),
],
),
),

if (_selectedLocation != null)
Marker(
point: _selectedLocation!,
width: 50,
height: 55,
child: const Icon(
Icons.location_pin,
color: Colors.red,
size: 45,
),
),
],
),

const RichAttributionWidget(
attributions: [
TextSourceAttribution(
'OpenStreetMap contributors',
),
],
),
],
),

// Instructions at the top.
Positioned(
top: 12,
left: 12,
right: 12,
child: Card(
elevation: 3,
child: Padding(
padding: const EdgeInsets.all(14),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
mainAxisSize: MainAxisSize.min,
children: [
const Row(
children: [
Icon(
Icons.touch_app,
color: Colors.teal,
),
SizedBox(width: 8),
Expanded(
child: Text(
'Choose the shop location',
style: TextStyle(
fontWeight: FontWeight.bold,
fontSize: 14,
),
),
),
],
),
const SizedBox(height: 6),
const Text(
'Move around the map and tap the exact '
'shop location. You can zoom in for accuracy.',
style: TextStyle(
fontSize: 12,
height: 1.4,
),
),
const SizedBox(height: 10),
Row(
children: [
Container(
width: 12,
height: 12,
decoration: const BoxDecoration(
color: Colors.teal,
shape: BoxShape.circle,
),
),
const SizedBox(width: 6),
const Expanded(
child: Text(
'UDUS campus centre',
style: TextStyle(fontSize: 11),
),
),
Container(
width: 12,
height: 12,
decoration: const BoxDecoration(
color: Colors.red,
shape: BoxShape.circle,
),
),
const SizedBox(width: 6),
const Expanded(
child: Text(
'Selected shop',
style: TextStyle(fontSize: 11),
),
),
],
),
],
),
),
),
),

// Distance and selection information.
Positioned(
left: 12,
right: 12,
bottom: 100,
child: Card(
elevation: 3,
child: Padding(
padding: const EdgeInsets.all(12),
child: Row(
children: [
Icon(
_selectedLocation == null
? Icons.info_outline
    : Icons.check_circle_outline,
color: _selectedLocation == null
? Colors.blueGrey
    : Colors.teal,
size: 28,
),
const SizedBox(width: 10),
Expanded(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
mainAxisSize: MainAxisSize.min,
children: [
Text(
_selectedLocation == null
? 'No location selected'
    : 'Shop location selected',
style: const TextStyle(
fontWeight: FontWeight.bold,
fontSize: 13,
),
),
const SizedBox(height: 4),
Text(
_selectedDistanceKm == null
? 'Select a point inside the shaded area.'
    : '${_selectedDistanceKm!.toStringAsFixed(2)} km '
'from UDUS campus centre'
'\nMaximum allowed distance: 5 km',
style: const TextStyle(
fontSize: 11,
height: 1.4,
),
),
],
),
),
if (_selectedLocation != null)
IconButton(
tooltip: 'Clear selected location',
onPressed: () {
setState(() {
_selectedLocation = null;
_selectedDistanceKm = null;
});
},
icon: const Icon(
Icons.close,
color: Colors.redAccent,
),
),
],
),
),
),
),

// Current-location button.
Positioned(
right: 16,
bottom: 170,
child: FloatingActionButton(
heroTag: 'pickerCurrentLocation',
tooltip: 'Use my current location',
backgroundColor: Colors.white,
foregroundColor: Colors.teal,
onPressed: _isGettingLocation
? null
    : _useCurrentLocation,
child: _isGettingLocation
? const SizedBox(
width: 24,
height: 24,
child: CircularProgressIndicator(
strokeWidth: 2,
),
)
    : const Icon(Icons.my_location),
),
),

// Confirm selected location.
Positioned(
left: 16,
right: 16,
bottom: 20,
child: SafeArea(
top: false,
child: ElevatedButton.icon(
onPressed: _selectedLocation == null
? null
    : _confirmLocation,
icon: const Icon(Icons.check_circle_outline),
label: Text(
_selectedLocation == null
? 'SELECT A LOCATION FIRST'
    : 'CONFIRM SHOP LOCATION',
),
style: ElevatedButton.styleFrom(
backgroundColor: Colors.teal,
foregroundColor: Colors.white,
disabledBackgroundColor: Colors.grey.shade400,
minimumSize: const Size.fromHeight(55),
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(12),
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

