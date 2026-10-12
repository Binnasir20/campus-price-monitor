import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'package:provider/provider.dart';

import '../../constants/app_colors.dart';
import '../../model/price_report_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/shop_provider.dart';
import '../../providers/price_provider.dart';

class ReportPriceScreen extends StatefulWidget {
  final String? initialShopId;

  const ReportPriceScreen({
    super.key,
    this.initialShopId,
  });

  @override
  State<ReportPriceScreen> createState() => _ReportPriceScreenState();
}

class _ReportPriceScreenState extends State<ReportPriceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _itemController = TextEditingController();
  final _priceController = TextEditingController();

  String? _selectedShopId;

  @override
  void initState() {
    super.initState();
    _selectedShopId = widget.initialShopId;
  }

  @override
  void dispose() {
    _itemController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _submitReport() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final priceProvider =
    Provider.of<PriceProvider>(context, listen: false);

    final user = auth.userModel;

    if (user == null) {
      _showSnackBar("Please log in again", Colors.red);
      return;
    }

    final report = PriceReport(
      id: '',
      itemId: _itemController.text.trim(),
      shopId: _selectedShopId!,
      university: user.university,
      price: double.parse(_priceController.text.trim()),
      reportedBy: user.uid,
      reportedAt: DateTime.now(),
      status: 'pending',
    );

    final success = await priceProvider.submitPriceReport(report);

    if (!mounted) return;

    if (success) {
      _showSnackBar("Price reported successfully", Colors.green);
      Navigator.pop(context);
    } else {
      _showSnackBar("Failed to submit report", Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
      ),
    );
  }

  OutlineInputBorder _inputBorder() {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
      borderSide: BorderSide(color: AppColors.primary),
    );
  }

  TextStyle _textStyle(){
    return TextStyle(
      color: Colors.grey,
      fontSize: 13,

    );
  }

  @override
  Widget build(BuildContext context) {
    final shops = Provider.of<ShopProvider>(context).shops;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text(
          "Report a Price",
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                value: _selectedShopId,
                padding: EdgeInsets.symmetric(horizontal: 10),
                dropdownColor: AppColors.background,
                decoration: InputDecoration(
                  labelStyle: _textStyle(),
                  labelText: "Shop",
                  border: _inputBorder(),
                  focusedBorder: _inputBorder(),
                  prefixIcon: Icon(IconlyLight.buy,size: 20,color: AppColors.primary,),
                ),
                items: shops.map((shop) {
                  return DropdownMenuItem(
                    value: shop.id,
                    child: Text(shop.name),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedShopId = value;
                  });
                },
                validator: (value) {
                  return value == null
                      ? "Please select a shop"
                      : null;
                },
              ),

              const SizedBox(height: 20),

              TextFormField(
                cursorColor: AppColors.primary,
                cursorHeight: 16,
                controller: _itemController,
                decoration: InputDecoration(
                  labelText: "Item name (e.g. Bread)",
                  labelStyle: _textStyle(),
                  border: _inputBorder(),
                  focusedBorder: _inputBorder(),
                  prefixIcon: Icon(IconlyLight.category,size: 20,color: AppColors.primary,),
                ),
                validator: (value) {
                  return value == null || value.trim().isEmpty
                      ? "Enter item name"
                      : null;
                },
              ),

              const SizedBox(height: 20),

              TextFormField(
                controller: _priceController,
                cursorColor: AppColors.primary,
                cursorHeight: 16,
                decoration: InputDecoration(
                  labelText: "Price (₦)",
                  border: _inputBorder(),
                  focusedBorder: _inputBorder(),
                  labelStyle: _textStyle(),
                  prefixIcon: Icon(Icons.price_change,color: AppColors.primary,size: 20,),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return "Enter price";
                  }

                  if (double.tryParse(value.trim()) == null) {
                    return "Enter a valid number";
                  }

                  return null;
                },
              ),

              const SizedBox(height: 30),

              Consumer<PriceProvider>(
                builder: (context, provider, child) {
                  return provider.isLoading
                      ? const CircularProgressIndicator()
                      : ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(55),
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _submitReport,
                    child: const Text(
                      "SUBMIT PRICE REPORT",
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}