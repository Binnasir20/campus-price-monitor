import 'package:cloud_firestore/cloud_firestore.dart';

class Complaint {
  final String id;
  final String userId;
  final String shopId;
  final String university;
  final String reason; // e.g., 'Overpricing', 'Poor Quality'
  final String details;
  final DateTime timestamp;

  Complaint({
    required this.id,
    required this.userId,
    required this.shopId,
    required this.university,
    required this.reason,
    required this.details,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'shopId': shopId,
      'university': university,
      'reason': reason,
      'details': details,
      'timestamp': timestamp,
    };
  }

  factory Complaint.fromMap(Map<String, dynamic> map, String docId) {
    return Complaint(
      id: docId,
      userId: map['userId'] ?? '',
      shopId: map['shopId'] ?? '',
      university: map['university'] ?? '',
      reason: map['reason'] ?? '',
      details: map['details'] ?? '',
      timestamp: (map['timestamp'] as Timestamp).toDate(),
    );
  }
}