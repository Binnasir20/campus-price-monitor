import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../model/shop_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/shop_provider.dart';

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
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _submitShop() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final shopProvider = Provider.of<ShopProvider>(context, listen: false);
    final user = authProvider.userModel;

    // Security check
    if (user == null || !user.isAdmin) return;

    setState(() => _isSaving = true);

    final newShop = Shop(
      id: '',
      name: _nameController.text.trim(),
      university: user.university.trim(),
      location: _locationController.text.trim(),
      campus: _selectedCampus!,
      createdBy: user.uid,
      isVerified: true,
      isPotentialDuplicate: false,
    );

    try {
      await shopProvider.addNewShop(newShop);
      shopProvider.fetchShopsByUniversity(user.university, user.uid, isAdmin: true);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Official shop added!"), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _isSaving = false);
      _showError("Failed to save shop.");
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).userModel;
    final bool isAdmin = user?.isAdmin == true;


    if (!isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text("Access Denied")),
        body: const Center(child: Text("Only Admins can access this page.")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Official Shop"),
        backgroundColor: Colors.blueGrey[900],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Register New Campus Shop",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const Text("Visible to all students immediately.",
                  style: TextStyle(color: Colors.grey, fontSize: 14)),
              const SizedBox(height: 30),

              TextFormField(
                controller: _nameController,
                decoration: _inputDecoration("Shop Name", Icons.storefront),
                validator: (val) => val!.isEmpty ? "Enter name" : null,
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _locationController,
                decoration: _inputDecoration("Location", Icons.map_outlined),
                validator: (val) => val!.isEmpty ? "Enter location" : null,
              ),
              const SizedBox(height: 20),

              DropdownButtonFormField<String>(
                value: _selectedCampus,
                decoration: _inputDecoration("Select Campus", Icons.location_on),
                items: ["Main Campus", "City Campus", "Annex", "Other"]
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (val) => setState(() => _selectedCampus = val),
                validator: (val) => val == null ? "Select campus" : null,
              ),

              const SizedBox(height: 40),

              // The button is only reachable if isAdmin is true
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(60),
                  backgroundColor: Colors.blueGrey[900],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isSaving ? null : _submitShop,
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("SAVE OFFICIAL SHOP", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  void _showError(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
      );
    }
  }
}