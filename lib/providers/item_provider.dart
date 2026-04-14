import 'package:flutter/material.dart';
import '../model/item_model.dart';
import '../services/firestore_service.dart';

class ItemProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  List<Item> _items = [];
  bool _isLoading = false;

  List<Item> get items => _items;
  bool get isLoading => _isLoading;

  Future<void> fetchItems() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Using a stream to get real-time updates, but you can also use .get() for a one-time fetch
      _firestoreService.getItems().listen((itemsData) {
        _items = itemsData;
        _isLoading = false;
        notifyListeners();
      });
    } catch (e) {
      print("Error fetching items: $e");
      _isLoading = false;
      notifyListeners();
    }
  }
}
