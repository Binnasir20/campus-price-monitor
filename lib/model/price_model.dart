import 'package:cloud_firestore/cloud_firestore.dart';

class Price {
  final String id;
  final String itemId;
  final String shopId;
  final String university; // Added for easy querying
  final double price;
  final DateTime updatedAt;
  final String reportedBy;

  Price({
    required this.id,
    required this.itemId,
    required this.shopId,
    required this.university,
    required this.price,
    required this.updatedAt,
    required this.reportedBy,
  });

  Map<String, dynamic> toMap() {
    return {
      'itemId': itemId,
      'shopId': shopId,
      'university': university,
      'price': price,
      'updatedAt': updatedAt,
      'reportedBy': reportedBy,
    };
  }

  factory Price.fromMap(Map<String, dynamic> map, String docId) {
    return Price(
      id: docId,
      itemId: map['itemId'] ?? '',
      shopId: map['shopId'] ?? '',
      university: map['university'] ?? '',
      price: (map['price'] ?? 0.0).toDouble(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
      reportedBy: map['reportedBy'] ?? '',
    );
  }
}