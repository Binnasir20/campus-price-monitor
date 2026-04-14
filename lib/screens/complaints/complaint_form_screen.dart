import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../model/complaint_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/shop_provider.dart';
import '../../providers/complaint_provider.dart';

class ComplaintFormScreen extends StatefulWidget {
  final String? initialShopId;
  const ComplaintFormScreen({super.key, this.initialShopId});

  @override
  State<ComplaintFormScreen> createState() => _ComplaintFormScreenState();
}

class _ComplaintFormScreenState extends State<ComplaintFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _detailsController = TextEditingController();
  String? _selectedShopId;
  String? _selectedReason;

  final List<String> _reasons = [
    "Overpricing",
    "Poor Quality",
    "Shop doesn't exist",
    "Inaccurate Information",
    "Other"
  ];

  @override
  void initState() {
    super.initState();
    _selectedShopId = widget.initialShopId;
  }

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  void _submitComplaint() async {
    // 1. Basic validation
    if (!_formKey.currentState!.validate()) return;

    final user = Provider.of<AuthProvider>(context, listen: false).userModel;
    final complaintProv = Provider.of<ComplaintProvider>(context, listen: false);

    if (user == null) return;

    // 2. Create Complaint Object
    final newComplaint = Complaint(
      id: '',
      userId: user.uid,
      shopId: _selectedShopId!,
      university: user.university,
      reason: _selectedReason!,
      details: _detailsController.text.trim(),
      timestamp: DateTime.now(),
    );

    // 3. Submit
    final success = await complaintProv.sendComplaint(newComplaint);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? "Reported successfully!" : "Failed to report."),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
      if (success) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final shops = Provider.of<ShopProvider>(context).shops;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Report an Issue"),
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // --- SHOP DROPDOWN ---
              DropdownButtonFormField<String>(
                value: _selectedShopId,
                decoration: _inputStyle("Select Shop", Icons.storefront),
                items: shops.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))).toList(),
                onChanged: (val) => setState(() => _selectedShopId = val),
                validator: (val) => val == null ? "Select a shop" : null,
              ),
              const SizedBox(height: 20),

              // --- REASON DROPDOWN ---
              DropdownButtonFormField<String>(
                value: _selectedReason,
                decoration: _inputStyle("Issue Type", Icons.report_problem_outlined),
                items: _reasons.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                onChanged: (val) => setState(() => _selectedReason = val),
                validator: (val) => val == null ? "Select a reason" : null,
              ),
              const SizedBox(height: 20),

              // --- DETAILS FIELD ---
              TextFormField(
                controller: _detailsController,
                maxLines: 4,
                decoration: _inputStyle("Details", Icons.description_outlined),
                validator: (val) => val!.isEmpty ? "Please explain the issue" : null,
              ),
              const SizedBox(height: 40),

              // --- SUBMIT BUTTON ---
              Consumer<ComplaintProvider>(
                builder: (context, provider, _) {
                  return ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(60),
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: provider.isLoading ? null : _submitComplaint,
                    child: provider.isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("SUBMIT REPORT", style: TextStyle(fontWeight: FontWeight.bold)),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputStyle(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}