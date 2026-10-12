
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../model/shop_model.dart';
import '../../providers/shop_provider.dart';
import 'location_picker_screen.dart';

class EditShopScreen extends StatefulWidget {
final Shop shop;

const EditShopScreen({
super.key,
required this.shop,
});

@override
State<EditShopScreen> createState() => _EditShopScreenState();
}

class _EditShopScreenState extends State<EditShopScreen> {
final _formKey = GlobalKey<FormState>();

late TextEditingController _nameController;
late TextEditingController _locationController;

String? _selectedCampus;
LatLng? _pickedLocation;
bool _isSaving = false;

@override
void initState() {
super.initState();

_nameController = TextEditingController(text: widget.shop.name);
_locationController = TextEditingController(text: widget.shop.location);

_selectedCampus = widget.shop.campus;

if (widget.shop.latitude != null &&
widget.shop.longitude != null) {
_pickedLocation = LatLng(
widget.shop.latitude!,
widget.shop.longitude!,
);
}
}

@override
void dispose() {
_nameController.dispose();
_locationController.dispose();
super.dispose();
}

Future<void> _pickLocation() async {
final LatLng? result = await Navigator.push<LatLng>(
context,
MaterialPageRoute(
builder: (context) => LocationPickerScreen(
initialLat: _pickedLocation?.latitude,
initialLng: _pickedLocation?.longitude,
),
),
);

if (!mounted) return;

if (result != null) {
setState(() {
_pickedLocation = result;
});
}
}

Future<void> _submitShop() async {
if (_isSaving) return;

if (!_formKey.currentState!.validate()) return;

if (_pickedLocation == null) {
_showError('Please select the shop location on the map.');
return;
}

setState(() {
_isSaving = true;
});

final shopProvider = context.read<ShopProvider>();

final updatedShop = Shop(
id: widget.shop.id,
name: _nameController.text.trim(),
university: widget.shop.university,
location: _locationController.text.trim(),
campus: _selectedCampus!,
createdBy: widget.shop.createdBy,
isVerified: widget.shop.isVerified,
isPotentialDuplicate: widget.shop.isPotentialDuplicate,
latitude: _pickedLocation!.latitude,
longitude: _pickedLocation!.longitude,
);

try {
await shopProvider.updateShop(updatedShop);

if (!mounted) return;

ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(
content: Text('Shop updated successfully!'),
backgroundColor: Colors.green,
),
);

Navigator.pop(context);
} catch (e) {
if (!mounted) return;

_showError('Failed to update shop. Please try again.');
} finally {
if (mounted) {
setState(() {
_isSaving = false;
});
}
}
}

@override
Widget build(BuildContext context) {
return Scaffold(
appBar: AppBar(
title: const Text(
'Edit Shop',
style: TextStyle(fontSize: 17),
),
backgroundColor: Colors.teal,
foregroundColor: Colors.white,
),
body: SingleChildScrollView(
padding: const EdgeInsets.all(24.0),
child: Form(
key: _formKey,
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
const Text(
'Edit Shop Details',
style: TextStyle(
fontWeight: FontWeight.bold,
fontSize: 15,
),
),
const SizedBox(height: 30),

TextFormField(
controller: _nameController,
decoration: _inputDecoration(
'Shop Name',
Icons.storefront,
),
validator: (val) {
if (val == null || val.trim().isEmpty) {
return 'Enter shop name';
}
return null;
},
),
const SizedBox(height: 20),

TextFormField(
controller: _locationController,
decoration: _inputDecoration(
'Location/Address',
Icons.map_outlined,
),
validator: (val) {
if (val == null || val.trim().isEmpty) {
return 'Enter location';
}
return null;
},
),
const SizedBox(height: 20),

DropdownButtonFormField<String>(
value: _selectedCampus,
decoration: _inputDecoration(
'Select Campus',
Icons.location_on,
),
items: [
'Main Campus',
'City Campus',
'Annex',
'Other',
].map((campus) {
return DropdownMenuItem<String>(
value: campus,
child: Text(campus),
);
}).toList(),
onChanged: (value) {
setState(() {
_selectedCampus = value;
});
},
validator: (value) {
if (value == null) {
return 'Select campus';
}
return null;
},
),

const SizedBox(height: 20),

OutlinedButton.icon(
onPressed: _isSaving ? null : _pickLocation,
icon: Icon(
_pickedLocation == null
? Icons.add_location_alt
    : Icons.location_on,
color: _pickedLocation == null
? Colors.blueGrey
    : Colors.green,
),
label: Text(
_pickedLocation == null
? 'Select Location on Map'
    : 'Location Selected',
style: TextStyle(
color: _pickedLocation == null
? Colors.blueGrey
    : Colors.green,
fontWeight: FontWeight.bold,
),
),
style: OutlinedButton.styleFrom(
minimumSize: const Size.fromHeight(60),
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(12),
),
side: BorderSide(
color: _pickedLocation == null
? Colors.blueGrey
    : Colors.green,
),
),
),

if (_pickedLocation != null)
Padding(
padding: const EdgeInsets.only(
top: 8.0,
left: 4.0,
),
child: Text(
'Coordinates: '
'${_pickedLocation!.latitude.toStringAsFixed(6)}, '
'${_pickedLocation!.longitude.toStringAsFixed(6)}',
style: const TextStyle(
fontSize: 12,
color: Colors.grey,
),
),
),

const SizedBox(height: 40),

ElevatedButton(
style: ElevatedButton.styleFrom(
minimumSize: const Size.fromHeight(60),
backgroundColor: Colors.blueGrey[900],
foregroundColor: Colors.white,
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(12),
),
),
onPressed: _isSaving ? null : _submitShop,
child: _isSaving
? const CircularProgressIndicator(
color: Colors.white,
)
    : const Text(
'UPDATE SHOP',
style: TextStyle(
fontWeight: FontWeight.bold,
),
),
),
],
),
),
),
);
}

InputDecoration _inputDecoration(
String label,
IconData icon,
) {
return InputDecoration(
labelText: label,
prefixIcon: Icon(icon),
border: OutlineInputBorder(
borderRadius: BorderRadius.circular(12),
),
);
}

void _showError(String message) {
if (!mounted) return;

ScaffoldMessenger.of(context).showSnackBar(
SnackBar(
content: Text(message),
backgroundColor: Colors.redAccent,
),
);
}
}
