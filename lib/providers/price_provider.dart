import 'dart:async';
import 'package:flutter/material.dart';
import '../model/price_model.dart';
import '../model/price_report_model.dart';
import '../services/firestore_service.dart';

class PriceProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  List<Price> _prices = [];
  List<PriceReport> _priceReports = [];
  List<PriceReport> _myPriceReports = [];

  bool _isLoading = false;
  String? _errorMessage;

  StreamSubscription? _priceSubscription;
  StreamSubscription? _priceReportSubscription;
  StreamSubscription? _myPriceReportSubscription;

  List<Price> get prices => _prices;
  List<PriceReport> get priceReports => _priceReports;
  List<PriceReport> get myPriceReports => _myPriceReports;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // LOAD PRICES BY UNIVERSITY.
  Future<void> fetchPricesByUniversity(String universityName) async {
    await _priceSubscription?.cancel();
    _priceSubscription = null;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    _priceSubscription = _firestoreService
        .getPricesByUniversity(universityName)
        .listen(
          (priceData) {
        _prices = priceData;
        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
      },
      onError: (error) {
        _prices = [];
        _isLoading = false;
        _errorMessage = 'Error fetching prices: $error';
        debugPrint(_errorMessage);
        notifyListeners();
      },
    );
  }

  // ADD OR UPDATE A PRICE.
  Future<bool> reportPrice(Price price) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _firestoreService.updatePrice(price);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Error saving price: $e';
      debugPrint(_errorMessage);
      notifyListeners();
      return false;
    }
  }

  // ============================================================
// UPDATE AN EXISTING CURRENT PRICE (ADMIN)
// ============================================================

  Future<bool> updateCurrentPrice(Price price) async {
    _errorMessage = null;

    try {
      await _firestoreService.updatePrice(price);

      _errorMessage = null;
      return true;
    } catch (e, stackTrace) {
      _errorMessage = 'Error updating current price: $e';

      debugPrint(_errorMessage);
      debugPrintStack(stackTrace: stackTrace);

      return false;
    }
  }

// ============================================================
// REMOVE AN ITEM FROM A SPECIFIC SHOP (ADMIN)
// ============================================================

  Future<bool> removeItemFromShop({
    required String itemId,
    required String shopId,
  }) async {
    try {
      await _firestoreService.removeItemFromShop(
        itemId: itemId,
        shopId: shopId,
      );
      return true;
    } catch (e) {
      debugPrint('Error removing item from shop: $e');
      return false;
    }
  }


  // SUBMIT A PRICE REPORT.
  Future<bool> submitPriceReport(PriceReport report) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _firestoreService.submitPriceReport(report);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Error submitting price report: $e';
      debugPrint(_errorMessage);
      notifyListeners();
      return false;
    }
  }

  // LOAD ALL REPORTS FOR ADMIN REVIEW.
  Future<void> fetchPriceReportsByUniversity(
      String universityName,
      ) async {
    await _priceReportSubscription?.cancel();
    _priceReportSubscription = null;

    _priceReportSubscription = _firestoreService
        .getPriceReportsByUniversity(universityName)
        .listen(
          (reportData) {
        _priceReports = reportData;
        notifyListeners();
      },
      onError: (error) {
        _priceReports = [];
        debugPrint('Error fetching price reports: $error');
        notifyListeners();
      },
    );
  }

  // LOAD REPORTS SUBMITTED BY THE CURRENT USER.
  Future<void> fetchMyPriceReports(String uid) async {
    debugPrint('FETCHING MY REPORTS FOR: $uid');

    await _myPriceReportSubscription?.cancel();
    _myPriceReportSubscription = null;

    _myPriceReportSubscription = _firestoreService
        .getPriceReportsByUser(uid)
        .listen(
          (reportData) {
        debugPrint('MY REPORTS RECEIVED: ${reportData.length}');
        _myPriceReports = reportData;
        notifyListeners();
      },
      onError: (error) {
        _myPriceReports = [];
        debugPrint('MY REPORTS ERROR: $error');
        notifyListeners();
      },
    );
  }

  // APPROVE OR REJECT A PRICE REPORT.
  Future<bool> updatePriceReportStatus(
      String reportId,
      String status,
      ) async {
    if (!['pending', 'approved', 'rejected'].contains(status)) {
      debugPrint('Invalid price report status: $status');
      return false;
    }

    try {
      await _firestoreService.updatePriceReportStatus(
        reportId,
        status,
      );

      return true;
    } catch (e) {
      debugPrint('Provider Error updating report status: $e');
      return false;
    }
  }

  void clearPrices() {
    _priceSubscription?.cancel();
    _priceSubscription = null;

    _priceReportSubscription?.cancel();
    _priceReportSubscription = null;

    _myPriceReportSubscription?.cancel();
    _myPriceReportSubscription = null;

    _prices = [];
    _priceReports = [];
    _myPriceReports = [];

    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _priceSubscription?.cancel();
    _priceReportSubscription?.cancel();
    _myPriceReportSubscription?.cancel();
    super.dispose();
  }
}