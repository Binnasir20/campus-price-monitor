import 'package:flutter/material.dart';
import '../model/complaint_model.dart';
import '../services/firestore_service.dart';

class ComplaintProvider with ChangeNotifier {
  // We create an instance of the service to talk to Firebase
  final FirestoreService _firestoreService = FirestoreService();

  bool _isLoading = false;
  String? _errorMessage;

  // Getters to show status in the UI (like a loading spinner)
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // FUNCTION: Submit a new complaint
  Future<bool> sendComplaint(Complaint complaint) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners(); // Tells the UI to show a loading spinner

    try {
      await _firestoreService.submitComplaint(complaint);
      _isLoading = false;
      notifyListeners();
      return true; // Success!
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false; // Error happened
    }
  }

  // 2. Fetch complaints (if a student wants to see their past reports)
  List<Complaint> _userComplaints = [];
  List<Complaint> get userComplaints => _userComplaints;

  Future<void> fetchUserComplaints(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      // In the future, we could add a getMyComplaints() in our Service
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }
}