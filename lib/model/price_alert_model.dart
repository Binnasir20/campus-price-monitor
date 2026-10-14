
import 'package:cloud_firestore/cloud_firestore.dart';

class PriceAlert {
final String id;

final String university;
final String itemId;
final String itemName;
final String shopId;
final String shopName;
final String studentId;
final String purchaseId;
final String transactionReference;

final double observedPrice;
final double comparisonPrice;
final double differencePercentage;

final String unit;
final int comparisonCount;

final String status;
final String reason;

final DateTime createdAt;
final String? reviewedBy;
final DateTime? reviewedAt;
final String? reviewNote;

final bool isDemo;

PriceAlert({
  required this.studentId,
required this.id,
required this.university,
required this.itemId,
required this.itemName,
required this.shopId,
required this.shopName,
required this.purchaseId,
required this.transactionReference,
required this.observedPrice,
required this.comparisonPrice,
required this.differencePercentage,
required this.unit,
required this.comparisonCount,
required this.status,
required this.reason,
required this.createdAt,
this.reviewedBy,
this.reviewedAt,
this.reviewNote,
this.isDemo = true,
});

Map<String, dynamic> toMap() {
return {
'university': university,
'itemId': itemId,
'itemName': itemName,
'shopId': shopId,
'shopName': shopName,
'purchaseId': purchaseId,
'transactionReference': transactionReference,
'observedPrice': observedPrice,
'comparisonPrice': comparisonPrice,
'differencePercentage': differencePercentage,
'unit': unit,
'comparisonCount': comparisonCount,
'status': status,
'reason': reason,
'createdAt': Timestamp.fromDate(createdAt),
'reviewedBy': reviewedBy,
'reviewedAt':
reviewedAt == null ? null : Timestamp.fromDate(reviewedAt!),
'reviewNote': reviewNote,
'isDemo': isDemo,
};
}

factory PriceAlert.fromMap(
Map<String, dynamic> map,
String documentId,
) {
return PriceAlert(
  studentId: map['studentId']?.toString() ?? '',
id: documentId,
university: map['university']?.toString() ?? '',
itemId: map['itemId']?.toString() ?? '',
itemName: map['itemName']?.toString() ?? '',
shopId: map['shopId']?.toString() ?? '',
shopName: map['shopName']?.toString() ?? '',
purchaseId: map['purchaseId']?.toString() ?? '',
transactionReference:
map['transactionReference']?.toString() ?? '',
observedPrice: _toDouble(map['observedPrice']),
comparisonPrice: _toDouble(map['comparisonPrice']),
differencePercentage: _toDouble(map['differencePercentage']),
unit: map['unit']?.toString() ?? '',
comparisonCount: _toInt(map['comparisonCount']),
status: map['status']?.toString() ?? 'pending',
reason: map['reason']?.toString() ?? '',
createdAt: _toDateTime(map['createdAt']),
reviewedBy: map['reviewedBy']?.toString(),
reviewedAt: map['reviewedAt'] == null
? null
    : _toDateTime(map['reviewedAt']),
reviewNote: map['reviewNote']?.toString(),
isDemo: map['isDemo'] as bool? ?? true,
);
}

static double _toDouble(dynamic value) {
if (value is num) return value.toDouble();
return double.tryParse(value?.toString() ?? '') ?? 0.0;
}

static int _toInt(dynamic value) {
if (value is int) return value;
if (value is num) return value.toInt();
return int.tryParse(value?.toString() ?? '') ?? 0;
}

static DateTime _toDateTime(dynamic value) {
if (value is Timestamp) return value.toDate();
if (value is DateTime) return value;
return DateTime.fromMillisecondsSinceEpoch(0);
}
}
