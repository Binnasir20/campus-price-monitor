
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:iconly/iconly.dart';
import 'package:provider/provider.dart';

import '../../model/shop_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/shop_provider.dart';
import 'location_picker_screen.dart';

class AddShopScreen extends StatefulWidget {
const AddShopScreen({super.key});

@override
State<AddShopScreen> createState() => _AddShopScreenState();
}

class _AddShopScreenState extends State<AddShopScreen> {
final _formKey = GlobalKey<FormState>();
final _nameController = TextEditingController();
final _locationController = TextEditingController();

String? _selectedCampus;
LatLng? _pickedLocation;
bool _isSaving = false;

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
builder: (context) => const LocationPickerScreen(),
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
if (!_formKey.currentState!.validate()) return;

// Coordinates are required so the shop can appear on the map.
if (_pickedLocation == null) {
_showError('Please select the shop location on the map.');
return;
}

final authProvider = context.read<AuthProvider>();
final shopProvider = context.read<ShopProvider>();
final user = authProvider.userModel;

// Security check.
if (user == null || !user.isAdmin) {
_showError('Only administrators can add official shops.');
return;
}

setState(() {
_isSaving = true;
});

final newShop = Shop(
id: '',
name: _nameController.text.trim(),
university: user.university.trim(),
location: _locationController.text.trim(),
campus: _selectedCampus!,
createdBy: user.uid,
isVerified: true,
isPotentialDuplicate: false,
latitude: _pickedLocation!.latitude,
longitude: _pickedLocation!.longitude,
);

try {
await shopProvider.addNewShop(newShop);

if (!mounted) return;

await shopProvider.fetchShopsByUniversity(
user.university,
user.uid,
isAdmin: true,
);

if (!mounted) return;

ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(
content: Text('Official shop added successfully!'),
backgroundColor: Colors.green,
),
);

Navigator.pop(context);
} catch (e) {
debugPrint('Failed to add shop: $e');

if (mounted) {
_showError('Failed to save shop. Please try again.');
}
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
final user = context.watch<AuthProvider>().userModel;
final bool isAdmin = user?.isAdmin == true;

if (!isAdmin) {
return Scaffold(
appBar: AppBar(
title: const Text('Access Denied'),
),
body: const Center(
child: Text('Only admins can access this page.'),
),
);
}

return Scaffold(
appBar: AppBar(
title: const Text(
'Add Official Shop',
style: TextStyle(fontSize: 17),
),
backgroundColor: Colors.teal,
foregroundColor: Colors.white,
),
body: SingleChildScrollView(
padding: const EdgeInsets.all(24),
child: Form(
key: _formKey,
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
const Text(
'Register New Campus Shop',
style: TextStyle(
fontWeight: FontWeight.bold,
fontSize: 15,
),
),
const Text(
'Visible to all students immediately.',
style: TextStyle(
color: Colors.grey,
fontSize: 11,
),
),
const SizedBox(height: 30),

TextFormField(
controller: _nameController,
decoration: _inputDecoration(
'Shop Name',
Icons.storefront,
),
validator: (value) {
if (value == null || value.trim().isEmpty) {
return 'Enter shop name';
}
return null;
},
),
const SizedBox(height: 20),

TextFormField(
controller: _locationController,
decoration: _inputDecoration(
'Location',
Icons.map_outlined,
),
validator: (value) {
if (value == null || value.trim().isEmpty) {
return 'Enter shop address or description';
}
return null;
},
),
const SizedBox(height: 20),

DropdownButtonFormField<String>(
value: _selectedCampus,
decoration: _inputDecoration(
'Select Campus',
IconlyBold.location,
),
items: ['Main Campus', 'City Campus', 'Annex', 'Other']
    .map(
(campus) => DropdownMenuItem(
value: campus,
child: Text(campus),
),
)
    .toList(),
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

// Shop location picker.
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
fontSize: 12,
),
),
style: OutlinedButton.styleFrom(
minimumSize: const Size.fromHeight(60),
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(12),
),
side: BorderSide(
color: _pickedLocation == null
? Colors.teal
    : Colors.green,
),
),
),

if (_pickedLocation != null)
Padding(
padding: const EdgeInsets.only(
top: 8,
left: 4,
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
backgroundColor: Colors.teal,
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
'SAVE OFFICIAL SHOP',
style: TextStyle(
fontWeight: FontWeight.bold,
fontSize: 15,
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
