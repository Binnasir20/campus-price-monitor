
import 'dart:convert';

import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class NavigationRoute {
final List<LatLng> points;
final double distanceInMeters;
final double durationInSeconds;

const NavigationRoute({
required this.points,
required this.distanceInMeters,
required this.durationInSeconds,
});

double get distanceInKilometres => distanceInMeters / 1000;

int get estimatedMinutes => (durationInSeconds / 60).round();
}

class LocationService {
// Get the user's current location.
static Future<Position?> getCurrentLocation() async {
final serviceEnabled =
await Geolocator.isLocationServiceEnabled();

if (!serviceEnabled) {
throw Exception('Location services are disabled.');
}

LocationPermission permission =
await Geolocator.checkPermission();

if (permission == LocationPermission.denied) {
permission = await Geolocator.requestPermission();

if (permission == LocationPermission.denied) {
throw Exception('Location permission was denied.');
}
}

if (permission == LocationPermission.deniedForever) {
throw Exception(
'Location permission is permanently denied. '
'Enable it in your phone settings.',
);
}

return Geolocator.getCurrentPosition(
locationSettings: const LocationSettings(
accuracy: LocationAccuracy.high,
timeLimit: Duration(seconds: 20),
),
);
}

// Calculate a route using the OSRM routing service.
static Future<NavigationRoute> getRoute({
required double startLat,
required double startLng,
required double endLat,
required double endLng,
}) async {
// OSRM expects longitude first, then latitude.
final url = Uri.parse(
'https://router.project-osrm.org/route/v1/driving/'
'$startLng,$startLat;$endLng,$endLat'
'?overview=full&geometries=geojson&steps=true',
);

final response = await http
    .get(
url,
headers: {
'Accept': 'application/json',
},
)
    .timeout(const Duration(seconds: 25));

if (response.statusCode != 200) {
throw Exception(
'The routing service returned status '
'${response.statusCode}. Please try again.',
);
}

final Map<String, dynamic> data =
jsonDecode(response.body) as Map<String, dynamic>;

if (data['code'] != 'Ok') {
throw Exception(
'No driving route could be found between your '
'location and this shop.',
);
}

final routes = data['routes'] as List<dynamic>?;

if (routes == null || routes.isEmpty) {
throw Exception('No route was returned by the routing service.');
}

final route = routes.first as Map<String, dynamic>;

final geometry = route['geometry'] as Map<String, dynamic>;

final coordinates = geometry['coordinates'] as List<dynamic>;

final points = coordinates.map((coordinate) {
final values = coordinate as List<dynamic>;

// GeoJSON coordinates are [longitude, latitude].
return LatLng(
(values[1] as num).toDouble(),
(values[0] as num).toDouble(),
);
}).toList();

if (points.isEmpty) {
throw Exception('The route contains no coordinates.');
}

return NavigationRoute(
points: points,
distanceInMeters:
(route['distance'] as num).toDouble(),
durationInSeconds:
(route['duration'] as num).toDouble(),
);
}

// Calculate straight-line distance in kilometres.
static double calculateDistance(
double startLat,
double startLng,
double endLat,
double endLng,
) {
final distanceInMeters = Geolocator.distanceBetween(
startLat,
startLng,
endLat,
endLng,
);

return distanceInMeters / 1000;
}
}
