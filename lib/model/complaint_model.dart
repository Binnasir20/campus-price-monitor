import 'package:cloud_firestore/cloud_firestore.dart';

class Complaint {
  final String id;
  final String userId;
  final String shopId;
  final String university;
  final String reason;
  final String details;
  final DateTime timestamp;
  final String status;

  Complaint({
    required this.id,
    required this.userId,
    required this.shopId,
    required this.university,
    required this.reason,
    required this.details,
    required this.timestamp,
    this.status = 'pending',
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'shopId': shopId,
      'university': university,
      'reason': reason,
      'details': details,
      'timestamp': Timestamp.fromDate(timestamp),
      'status': status,
    };
  }

  factory Complaint.fromMap(
      Map<String, dynamic> map,
      String docId,
      ) {
    final timestamp = map['timestamp'];

    return Complaint(
      id: docId,
      userId: map['userId'] ?? '',
      shopId: map['shopId'] ?? '',
      university: map['university'] ?? '',
      reason: map['reason'] ?? '',
      details: map['details'] ?? '',
      timestamp: timestamp is Timestamp
          ? timestamp.toDate()
          : DateTime.now(),
      status: map['status'] ?? 'pending',
    );
  }
}