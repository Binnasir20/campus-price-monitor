
class Shop {
final String id;
final String name;
final String university;
final String location;
final String campus;
final bool isVerified;
final String createdBy;
final double? latitude;
final double? longitude;
final bool isPotentialDuplicate;

Shop({
required this.id,
required this.name,
required this.university,
required this.location,
required this.campus,
required this.createdBy,
this.latitude,
this.longitude,
this.isVerified = false,
this.isPotentialDuplicate = false,
});

// Convert the Shop object into a Map for Firestore.
Map<String, dynamic> toMap() {
return {
'name': name,
'university': university,
'location': location,
'campus': campus,
'isVerified': isVerified,
'createdBy': createdBy,
'latitude': latitude,
'longitude': longitude,
'isPotentialDuplicate': isPotentialDuplicate,
};
}

// Convert Firestore data into a Shop object.
factory Shop.fromMap(Map<String, dynamic> map, String docId) {
return Shop(
id: docId,
name: map['name'] as String? ?? '',
university: map['university'] as String? ?? '',
location: map['location'] as String? ?? '',
campus: map['campus'] as String? ?? '',
isVerified: map['isVerified'] as bool? ?? false,
createdBy: map['createdBy'] as String? ?? 'admin',
latitude: _toDouble(map['latitude']),
longitude: _toDouble(map['longitude']),
isPotentialDuplicate:
map['isPotentialDuplicate'] as bool? ?? false,
);
}

// Handle coordinates stored as numbers or numeric strings.
static double? _toDouble(dynamic value) {
if (value is num) {
return value.toDouble();
}

if (value is String) {
return double.tryParse(value);
}

return null;
}
}
