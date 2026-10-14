import 'dart:async';
import 'package:flutter/material.dart';

import '../model/complaint_model.dart';
import '../services/firestore_service.dart';

class ComplaintProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Complaints submitted by the current user.
  List<Complaint> _userComplaints = [];
  List<Complaint> get userComplaints => _userComplaints;

  // All complaints belonging to the administrator's university.
  List<Complaint> _universityComplaints = [];
  List<Complaint> get universityComplaints => _universityComplaints;

  StreamSubscription<List<Complaint>>? _userComplaintsSubscription;
  StreamSubscription<List<Complaint>>? _universityComplaintsSubscription;

  // Submit a complaint.
  Future<bool> sendComplaint(Complaint complaint) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _firestoreService.submitComplaint(complaint);
      return true;
    } catch (e) {
      _errorMessage = 'Could not submit complaint: $e';
      debugPrint(_errorMessage);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Listen to complaints submitted by a particular user.
  Future<void> listenToUserComplaints(String userId) async {
    await _userComplaintsSubscription?.cancel();

    if (userId.trim().isEmpty) {
      _userComplaints = [];
      _errorMessage = 'User ID is required.';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    _userComplaintsSubscription =
        _firestoreService.getUserComplaints(userId).listen(
              (complaints) {
            _userComplaints = complaints;
            _isLoading = false;
            _errorMessage = null;
            notifyListeners();
          },
          onError: (Object error) {
            _isLoading = false;
            _errorMessage = 'Could not load your complaints: $error';
            debugPrint(_errorMessage);
            notifyListeners();
          },
        );
  }

  // Listen to complaints from an administrator's university.
  Future<void> listenToUniversityComplaints(String university) async {
    await _universityComplaintsSubscription?.cancel();

    if (university.trim().isEmpty) {
      _universityComplaints = [];
      _errorMessage = 'University is required.';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    _universityComplaintsSubscription =
        _firestoreService.getComplaintsByUniversity(university).listen(
              (complaints) {
            _universityComplaints = complaints;
            _isLoading = false;
            _errorMessage = null;
            notifyListeners();
          },
          onError: (Object error) {
            _isLoading = false;
            _errorMessage = 'Could not load university complaints: $error';
            debugPrint(_errorMessage);
            notifyListeners();
          },
        );
  }

  // Clear the current user's complaint data.
  void clearUserComplaints() {
    _userComplaintsSubscription?.cancel();
    _userComplaintsSubscription = null;
    _userComplaints = [];
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _userComplaintsSubscription?.cancel();
    _universityComplaintsSubscription?.cancel();
    super.dispose();
  }
}