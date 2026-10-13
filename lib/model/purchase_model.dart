
import 'package:cloud_firestore/cloud_firestore.dart';

class Purchase {
final String id;
final String studentId;
final String studentName;
final String university;
final String campus;

final String itemId;
final String itemName;
final String shopId;
final String shopName;

final double quantity;
final String unit;
final double unitPrice;
final double totalAmount;

final String paymentStatus;
final String paymentReference;
final String paymentType;

final DateTime purchasedAt;
final bool isDemo;

Purchase({
required this.id,
required this.studentId,
required this.studentName,
required this.university,
required this.campus,
required this.itemId,
required this.itemName,
required this.shopId,
required this.shopName,
required this.quantity,
required this.unit,
required this.unitPrice,
required this.totalAmount,
required this.paymentStatus,
required this.paymentReference,
required this.paymentType,
required this.purchasedAt,
this.isDemo = true,
});

Map<String, dynamic> toMap() {
return {
'studentId': studentId,
'studentName': studentName,
'university': university,
'campus': campus,
'itemId': itemId,
'itemName': itemName,
'shopId': shopId,
'shopName': shopName,
'quantity': quantity,
'unit': unit,
'unitPrice': unitPrice,
'totalAmount': totalAmount,
'paymentStatus': paymentStatus,
'paymentReference': paymentReference,
'paymentType': paymentType,
'purchasedAt': Timestamp.fromDate(purchasedAt),
'isDemo': isDemo,
};
}

factory Purchase.fromMap(Map<String, dynamic> map, String documentId) {
return Purchase(
id: documentId,
studentId: map['studentId']?.toString() ?? '',
studentName: map['studentName']?.toString() ?? '',
university: map['university']?.toString() ?? '',
campus: map['campus']?.toString() ?? '',
itemId: map['itemId']?.toString() ?? '',
itemName: map['itemName']?.toString() ?? '',
shopId: map['shopId']?.toString() ?? '',
shopName: map['shopName']?.toString() ?? '',
quantity: _toDouble(map['quantity']),
unit: map['unit']?.toString() ?? '',
unitPrice: _toDouble(map['unitPrice']),
totalAmount: _toDouble(map['totalAmount']),
paymentStatus: map['paymentStatus']?.toString() ?? 'unknown',
paymentReference: map['paymentReference']?.toString() ?? '',
paymentType: map['paymentType']?.toString() ?? 'demo',
purchasedAt: _toDateTime(map['purchasedAt']),
isDemo: map['isDemo'] as bool? ?? true,
);
}

static double _toDouble(dynamic value) {
if (value is num) return value.toDouble();
return double.tryParse(value?.toString() ?? '') ?? 0.0;
}

static DateTime _toDateTime(dynamic value) {
if (value is Timestamp) return value.toDate();
if (value is DateTime) return value;
return DateTime.fromMillisecondsSinceEpoch(0);
}
}
