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

    await _itemSubscription?.cancel();
    _itemSubscription = null;

    _itemSubscription = _firestoreService.getItems().listen(
          (itemsData) {
        _items = itemsData;
        _isLoading = false;
        notifyListeners();
      },
      onError: (error) {
        debugPrint('Item fetch error: $error');
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  Future<String?> addItem(Item item) async {
    try {
      return await _firestoreService.addItem(item);
    } catch (e) {
      debugPrint('Error adding item: $e');
      return null;
    }
  }

  Future<bool> updateItem(Item item) async {
    try {
      await _firestoreService.updateItem(item);
      return true;
    } catch (e) {
      debugPrint('Error updating item: $e');
      return false;
    }
  }

  Future<bool> deleteItem(
      String itemId, {
        String? itemName,
      }) async {
    try {
      await _firestoreService.deleteItem(
        itemId,
        itemName: itemName,
      );

      debugPrint('Item deleted successfully: $itemId');
      return true;
    } catch (e, stackTrace) {
      debugPrint('Error deleting item $itemId: $e');
      debugPrintStack(stackTrace: stackTrace);
      return false;
    }
  }

  @override
  void dispose() {
    _itemSubscription?.cancel();
    super.dispose();
  }
}