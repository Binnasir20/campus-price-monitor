import 'dart:async';
import 'package:flutter/material.dart';
import '../model/item_model.dart';
import '../services/firestore_service.dart';

class ItemProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  List<Item> _items = [];
  bool _isLoading = false;
  StreamSubscription? _itemSubscription;

  List<Item> get items => _items;
  bool get isLoading => _isLoading;

  Future<void> fetchItems() async {
    _isLoading = true;
    notifyListeners();

    _itemSubscription?.cancel();

    _itemSubscription = _firestoreService.getItems().listen((itemsData) {
      _items = itemsData;
      _isLoading = false;
      notifyListeners();
    }, onError: (error) {
      print("Item fetch error: $error");
      _isLoading = false;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _itemSubscription?.cancel();
    super.dispose();
  }

  Future<bool> addItem(Item item) async {
    try {
      await _firestoreService.addItem(item);
      return true;
    } catch (e) {
      print("Error adding item: $e");
      return false;
    }
  }

  Future<bool> updateItem(Item item) async {
    try {
      await _firestoreService.updateItem(item);
      return true;
    } catch (e) {
      print("Error updating item: $e");
      return false;
    }
  }

  Future<bool> deleteItem(String itemId) async {
    try {
      await _firestoreService.deleteItem(itemId);
      return true;
    } catch (e) {
      print("Error deleting item: $e");
      return false;
    }
  }
}
