import 'dart:async';

import 'package:flutter/material.dart';

import '../model/price_model.dart';
import '../model/price_report_model.dart';
import '../services/firestore_service.dart';

class PriceProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  List<Price> _prices = [];

  // Reports submitted by users for admin review
  List<PriceReport> _priceReports = [];

  // Reports submitted by the current user
  List<PriceReport> _myPriceReports = [];

  bool _isLoading = false;
  String? _errorMessage;

  StreamSubscription? _priceSubscription;
  StreamSubscription? _priceReportSubscription;
  StreamSubscription? _myPriceReportSubscription;

  List<Price> get prices => _prices;

  // Admin reports
  List<PriceReport> get priceReports => _priceReports;

  // Current user's reports
  List<PriceReport> get myPriceReports => _myPriceReports;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void fetchPricesByUniversity(String universityName) {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    _priceSubscription?.cancel();

    _priceSubscription = _firestoreService
        .getPricesByUniversity(universityName)
        .listen((priceData) {
      _prices = priceData;
      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
    }, onError: (error) {
      _prices = [];
      _isLoading = false;
      _errorMessage = "Error fetching prices: $error";
      print(_errorMessage);
      notifyListeners();
    });
  }

  Future<bool> reportPrice(Price price) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _firestoreService.updatePrice(price);

      _isLoading = false;
      notifyListeners();

      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();

      print("Provider Error: $e");
      return false;
    }
  }

  Future<bool> submitPriceReport(PriceReport report) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _firestoreService.submitPriceReport(report);

      _isLoading = false;
      notifyListeners();

      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();

      print("Provider Error: $e");
      return false;
    }
  }

  // GET ALL REPORTS FOR ADMIN
  void fetchPriceReportsByUniversity(String universityName) {
    _priceReportSubscription?.cancel();

    _priceReportSubscription = _firestoreService
        .getPriceReportsByUniversity(universityName)
        .listen((reportData) {
      _priceReports = reportData;
      notifyListeners();
    }, onError: (error) {
      _priceReports = [];
      print("Error fetching price reports: $error");
      notifyListeners();
    });
  }

  // GET REPORTS SUBMITTED BY THE CURRENT USER
  void fetchMyPriceReports(String uid) {
    _myPriceReportSubscription?.cancel();

    _myPriceReportSubscription = _firestoreService
        .getPriceReportsByUser(uid)
        .listen((reportData) {
      _myPriceReports = reportData;
      notifyListeners();
    }, onError: (error) {
      _myPriceReports = [];
      print("Error fetching my price reports: $error");
      notifyListeners();
    });
  }

  Future<bool> updatePriceReportStatus(
      String reportId,
      String status,
      ) async {
    try {
      await _firestoreService.updatePriceReportStatus(
        reportId,
        status,
      );

      return true;
    } catch (e) {
      print("Provider Error: $e");
      return false;
    }
  }

  void clearPrices() {
    _priceSubscription?.cancel();
    _priceSubscription = null;
    _prices = [];
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