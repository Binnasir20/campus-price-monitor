import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../../constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/shop_provider.dart';
import '../../services/location_service.dart';
import 'shop_detail_screen.dart';
import 'add_shop_screen.dart';

class ShopListScreen extends StatefulWidget {
  const ShopListScreen({super.key});

  @override
  State<ShopListScreen> createState() => _ShopListScreenState();
}

class _ShopListScreenState extends State<ShopListScreen> {
  Position? _currentPosition;



  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initData();
    });
  }

  Future<void> _initData() async {
    if (!mounted) return;

    final authProvider = context.read<AuthProvider>();
    final user = authProvider.userModel;


    if (user != null) {
      await context.read<ShopProvider>().fetchShopsByUniversity(
        user.university,
        user.uid,
        isAdmin: user.isAdmin,
      );
    }


  }




  // void _initData() async {
  //   // 1. Tell the app to fetch shops
  //   WidgetsBinding.instance.addPostFrameCallback((_) {
  //     final user = Provider.of<AuthProvider>(context, listen: false).userModel;
  //     if (user != null) {
  //       Provider.of<ShopProvider>(context, listen: false)
  //           .fetchShopsByUniversity(user.university, user.uid);
  //     }
  //   });
  //
  //   // 2. Get current location for distance calculation
  //   try {
  //     Position? position = await LocationService.getCurrentLocation();
  //     setState(() {
  //       _currentPosition = position;
  //     });
  //   } catch (e) {
  //     debugPrint("Location permission denied or disabled: $e");
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    final shopProv = Provider.of<ShopProvider>(context);
    final user = Provider.of<AuthProvider>(context).userModel;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text("${user?.university } Shops",
          style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold
        ),),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: shopProv.isLoading
          ? const Center(child: CircularProgressIndicator())
          : shopProv.shops.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: shopProv.shops.length,
        itemBuilder: (context, index) {
          final shop = shopProv.shops[index];

          // 2. Check if the shop is waiting for Admin approval
          final bool isPending = !shop.isVerified;

          return Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: CircleAvatar(
                // Orange for pending, Green for verified
                backgroundColor: isPending ? AppColors.primary : Colors.white.withOpacity(0.1),
                child: Icon(
                    isPending ? Icons.hourglass_top : IconlyLight.buy
                    ,
                    color: isPending ? AppColors.accent :  AppColors.primary
                ),
              ),
              title: Text(
                shop.name,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text("Campus:",style: TextStyle(

                        fontSize: 13,
                        fontWeight: FontWeight.bold
                      ),),
                      SizedBox(width: 5,),
                      Text( shop.campus,style:TextStyle(
                        color: AppColors.accent,
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                        fontStyle: FontStyle.italic
                      ),),
                    ],
                  ),
                  Row(
                    children: [
                      Icon(IconlyLight.location,size: 15,),
                      SizedBox(width: 5,),
                      Text(shop.location,
                          style: TextStyle(fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey)),
                    ],
                  ),
                  
                  // NEW: Display Distance
                  if (_currentPosition != null && shop.latitude != null && shop.longitude != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Row(
                        children: [
                          const Icon(IconlyLight.location, size: 14, color: Colors.green),
                          const SizedBox(width: 4),
                          Text(
                            "${LocationService.calculateDistance(_currentPosition!.latitude, _currentPosition!.longitude, shop.latitude!, shop.longitude!).toStringAsFixed(1)} km away",
                            style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ],
                      ),
                    ),

                  if (isPending)
                    const Padding(
                      padding: EdgeInsets.only(top: 4.0),
                      child: Text(
                        "Waiting for approval...",
                        style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (shop.latitude != null)
                    IconButton(
                      icon: const Icon(Icons.directions,
                          color: Colors.blue),
                      onPressed: () => LocationService.navigateTo(shop.latitude!, shop.longitude!),
                    ),
                  const Icon(Icons.arrow_forward_ios,
                      size: 16, color: Colors.grey),
                ],
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ShopDetailScreen(shop: shop),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddShopScreen()),
          );
        },
        backgroundColor: AppColors.primary,
        icon: Icon(IconlyLight.edit_square, color: Colors.white),
        label: const Text("Add Shop",
            style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.storefront_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text(
            "No shops found for your university",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          const Text("Be the first to add a shop!"),
        ],
      ),
    );
  }
}