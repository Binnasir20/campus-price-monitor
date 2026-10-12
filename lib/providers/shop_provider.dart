import 'dart:async';

import 'package:flutter/material.dart';

import '../model/shop_model.dart';
import '../services/firestore_service.dart';

class ShopProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  List<Shop> _shops = [];
  bool _isLoading = false;

  StreamSubscription? _shopSubscription;

  List<Shop> get shops => _shops;
  bool get isLoading => _isLoading;

  /// Fetch verified shops from Firebase by university.
  Future<void> fetchShopsByUniversity(
      String universityName,
      String currentUserId, {
        bool isAdmin = false,
      }) async {
    _isLoading = true;
    notifyListeners();

    await _shopSubscription?.cancel();
    _shopSubscription = null;

    _shopSubscription = _firestoreService
        .getVerifiedShopsByUniversity(universityName)
        .listen(
          (shopData) {
        _shops = shopData;
        _isLoading = false;
        notifyListeners();
      },
      onError: (error) {
        debugPrint('Shop fetch error: $error');
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  /// Add a shop to Firebase.
  Future<void> addNewShop(Shop shop) async {
    await _firestoreService.addShop(shop);
  }

  /// Verify a shop in Firebase.
  Future<void> verifyShop(String shopId) async {
    await _firestoreService.verifyShop(shopId);
  }

  /// Update a shop in Firebase.
  Future<void> updateShop(Shop shop) async {
    await _firestoreService.updateShop(shop);
  }

  /// Delete a shop from Firebase.
  Future<void> deleteShop(String shopId) async {
    await _firestoreService.deleteShop(shopId);
  }

  /// Clear shops and cancel the Firebase listener.
  void clearShops() {
    _shopSubscription?.cancel();
    _shopSubscription = null;
    _shops = [];
    notifyListeners();
  }

  @override
  void dispose() {
    _shopSubscription?.cancel();
    super.dispose();
  }
}