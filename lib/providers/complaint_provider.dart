
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

// Complaints submitted by the current student.
List<Complaint> _userComplaints = [];
List<Complaint> get userComplaints => _userComplaints;

// All complaints belonging to the administrator's university.
List<Complaint> _universityComplaints = [];
List<Complaint> get universityComplaints => _universityComplaints;

// Firestore stream subscriptions.
StreamSubscription<List<Complaint>>? _userComplaintsSubscription;
StreamSubscription<List<Complaint>>? _universityComplaintsSubscription;

// Submit a new complaint.
Future<bool> sendComplaint(Complaint complaint) async {
_isLoading = true;
_errorMessage = null;
notifyListeners();

try {
await _firestoreService.submitComplaint(complaint);
return true;
} catch (e) {
_errorMessage = e.toString();
debugPrint('Error submitting complaint: $e');
return false;
} finally {
_isLoading = false;
notifyListeners();
}
}

// Listen to complaints submitted by a specific student.
void listenToUserComplaints(String userId) {
_userComplaintsSubscription?.cancel();

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
_errorMessage = error.toString();
debugPrint('Error listening to user complaints: $error');
notifyListeners();
},
);
}

// Listen to all complaints belonging to an administrator's university.
void listenToUniversityComplaints(String university) {
_universityComplaintsSubscription?.cancel();

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
_errorMessage = error.toString();
debugPrint('Error listening to university complaints: $error');
notifyListeners();
},
);
}

@override
void dispose() {
_userComplaintsSubscription?.cancel();
_universityComplaintsSubscription?.cancel();
super.dispose();
}
}
