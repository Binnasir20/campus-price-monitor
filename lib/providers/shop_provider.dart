import 'dart:async';
import 'package:flutter/material.dart';
import '../model/shop_model.dart';
import '../services/firestore_service.dart';

class ShopProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  // 1. SIMPLIFIED: We only need one list of shops now
  List<Shop> _shops = [];
  bool _isLoading = false;

  StreamSubscription? _shopSubscription;

  // 2. SIMPLIFIED GETTERS
  List<Shop> get shops => _shops;
  bool get isLoading => _isLoading;

  /// Fetch all shops for the university.
  /// Since admins add them directly, every shop in the DB is now "Official".
  void fetchShopsByUniversity(String universityName, String currentUserId, {bool isAdmin = false}) {
    _isLoading = true;
    notifyListeners();

    _shopSubscription?.cancel();

    // We now use a single stream.
    // If the admin adds a shop, this stream updates for everyone immediately.
    _shopSubscription = _firestoreService
        .getVerifiedShopsByUniversity(universityName)
        .listen((shopData) {
      _shops = shopData;
      _isLoading = false;
      notifyListeners();
    });
  }

  /// Adds a new shop. In your AddShopScreen, 'isVerified' is set to true.
  Future<void> addNewShop(Shop shop) async {
    try {
      await _firestoreService.addShop(shop);
    } catch (e) {
      rethrow;
    }
  }

  // --- ADMIN ACTIONS ---

  /// Since only Admins add shops and they are instantly verified,
  /// 'verifyShop' is technically no longer needed unless you want to
  /// keep it for legacy data.
  Future<void> verifyShop(String shopId) async {
    await _firestoreService.verifyShop(shopId);
  }

  Future<void> deleteShop(String shopId) async {
    try {
      await _firestoreService.deleteShop(shopId);
    } catch (e) {
      rethrow;
    }
  }

  void clearShops() {
    _shopSubscription?.cancel();
    _shops = [];
    notifyListeners();
  }

}