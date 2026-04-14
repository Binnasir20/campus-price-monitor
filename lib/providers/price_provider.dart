import 'dart:async'; // 1. IMPORT ASYNC
import 'package:flutter/material.dart';
import '../model/price_model.dart';
import '../services/firestore_service.dart';

class PriceProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  List<Price> _prices = [];
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription? _priceSubscription; // 2. ADD A STREAM SUBSCRIPTION

  List<Price> get prices => _prices;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // FIX: RESTRUCTURED FETCH METHOD
  void fetchPricesByUniversity(String universityName) {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    // Cancel any previous subscription to avoid memory leaks
    _priceSubscription?.cancel();

    _priceSubscription = _firestoreService
        .getPricesByUniversity(universityName)
        .listen((priceData) {
      _prices = priceData;
      _isLoading = false; // Data has arrived, set loading to false
      _errorMessage = null;
      notifyListeners();
    }, onError: (error) {
      // Handle any errors from the stream
      _prices = [];
      _isLoading = false;
      _errorMessage = "Error fetching prices: $error";
      print(_errorMessage);
      notifyListeners();
    });
  }

  // Good practice: Clean up the subscription when the provider is disposed
  @override
  void dispose() {
    _priceSubscription?.cancel();
    super.dispose();
  }

  Future<bool> reportPrice(Price price) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _firestoreService.updatePrice(price);
      _isLoading = false;
      notifyListeners();
      return true; // This triggers the "Success" snackbar
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      print("Provider Error: $e");
      return false; // This triggers the "Failed" snackbar
    }
  }
  void clearPrices() {
    _priceSubscription?.cancel(); // Stop the live Firestore stream
    _priceSubscription = null;
    _prices = [];                 // Wipe the list
    notifyListeners();
  }
}
