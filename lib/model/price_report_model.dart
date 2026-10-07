import 'package:cloud_firestore/cloud_firestore.dart';

class PriceReport {
  final String id;
  final String itemId;
  final String shopId;
  final String university;
  final double price;
  final String reportedBy;
  final DateTime reportedAt;
  final String status;
  final String? assignedAdminId;

  PriceReport({
    required this.id,
    required this.itemId,
    required this.shopId,
    required this.university,
    required this.price,
    required this.reportedBy,
    required this.reportedAt,
    required this.status,
    this.assignedAdminId,
  });

  Map<String, dynamic> toMap() {
    return {
      'itemId': itemId,
      'shopId': shopId,
      'university': university,
      'price': price,
      'reportedBy': reportedBy,
      'reportedAt': reportedAt,
      'status': status,
      'assignedAdminId': assignedAdminId,
    };
  }

  factory PriceReport.fromMap(
      Map<String, dynamic> map,
      String docId,
      ) {
    return PriceReport(
      id: docId,
      itemId: map['itemId'] ?? '',
      shopId: map['shopId'] ?? '',
      university: map['university'] ?? '',
      price: (map['price'] ?? 0.0).toDouble(),
      reportedBy: map['reportedBy'] ?? '',
      reportedAt: (map['reportedAt'] as Timestamp).toDate(),
      status: map['status'] ?? 'pending',
      assignedAdminId: map['assignedAdminId'],
    );
  }
}