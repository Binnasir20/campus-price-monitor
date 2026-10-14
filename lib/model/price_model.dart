import 'package:cloud_firestore/cloud_firestore.dart';

class Price {
  final String id;
  final String itemId;
  final String shopId;
  final String university;
  final double price;
  final DateTime updatedAt;
  final String reportedBy;
  final bool isAdminSet;

  Price({
    required this.id,
    required this.itemId,
    required this.shopId,
    required this.university,
    required this.price,
    required this.updatedAt,
    required this.reportedBy,
    this.isAdminSet = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'itemId': itemId,
      'shopId': shopId,
      'university': university,
      'price': price,
      'updatedAt': Timestamp.fromDate(updatedAt),
      'reportedBy': reportedBy,
      'isAdminSet': isAdminSet,
    };
  }

  factory Price.fromMap(Map<String, dynamic> map, String docId) {
    final rawTimestamp = map['updatedAt'];

    DateTime updatedAt;

    if (rawTimestamp is Timestamp) {
      updatedAt = rawTimestamp.toDate();
    } else if (rawTimestamp is DateTime) {
      updatedAt = rawTimestamp;
    } else {
      updatedAt = DateTime.now();
    }

    final rawPrice = map['price'];

    double price;

    if (rawPrice is num) {
      price = rawPrice.toDouble();
    } else {
      price = double.tryParse(rawPrice?.toString() ?? '') ?? 0.0;
    }

    return Price(
      id: docId,
      itemId: map['itemId']?.toString() ?? '',
      shopId: map['shopId']?.toString() ?? '',
      university: map['university']?.toString() ?? '',
      price: price,
      updatedAt: updatedAt,
      reportedBy: map['reportedBy']?.toString() ?? '',
      isAdminSet: map['isAdminSet'] == true,
    );
  }
}