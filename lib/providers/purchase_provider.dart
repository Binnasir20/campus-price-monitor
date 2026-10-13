import 'dart:async';

import 'package:flutter/material.dart';

import '../model/purchase_model.dart';
import '../model/price_alert_model.dart';
import '../model/price_model.dart';
import '../services/firestore_service.dart';

class PurchaseProvider with ChangeNotifier {
final FirestoreService _firestoreService = FirestoreService();

List<Purchase> _myPurchases = [];
List<Purchase> _universityPurchases = [];
List<PriceAlert> _priceAlerts = [];

bool _isLoading = false;
String? _errorMessage;

StreamSubscription? _myPurchasesSubscription;
StreamSubscription? _universityPurchasesSubscription;
StreamSubscription? _priceAlertsSubscription;

List<Purchase> get myPurchases => _myPurchases;
List<Purchase> get universityPurchases => _universityPurchases;
List<PriceAlert> get priceAlerts => _priceAlerts;

bool get isLoading => _isLoading;
String? get errorMessage => _errorMessage;

// Prices more than this percentage above the comparison price are flagged.
static const double alertThresholdPercentage = 25.0;

// Save a simulated purchase and check whether its price looks unusual.
Future<bool> makeDemoPurchase({
required String studentId,
required String studentName,
required String university,
required String campus,
required String itemId,
required String itemName,
required String shopId,
required String shopName,
required double quantity,
required String unit,
required double unitPrice,
required List<Price> availablePrices,
}) async {
_isLoading = true;
_errorMessage = null;
notifyListeners();

try {
if (studentId.trim().isEmpty ||
university.trim().isEmpty ||
itemId.trim().isEmpty ||
shopId.trim().isEmpty) {
throw ArgumentError(
'Student, university, item, and shop are required.',
);
}

if (!quantity.isFinite ||
quantity <= 0 ||
!unitPrice.isFinite ||
unitPrice <= 0) {
throw ArgumentError(
'Quantity and unit price must be greater than zero.',
);
}

final now = DateTime.now();
final purchaseRef =
'${studentId}_${now.microsecondsSinceEpoch}';
final totalAmount = quantity * unitPrice;

final purchase = Purchase(
id: purchaseRef,
studentId: studentId,
studentName: studentName,
university: university,
campus: campus,
itemId: itemId,
itemName: itemName,
shopId: shopId,
shopName: shopName,
quantity: quantity,
unit: unit,
unitPrice: unitPrice,
totalAmount: totalAmount,
paymentStatus: 'successful',
paymentReference: 'DEMO-$purchaseRef',
paymentType: 'demo',
purchasedAt: now,
isDemo: true,
);

// Save the transaction before generating an alert.
await _firestoreService.savePurchase(purchase);

await _checkPriceAndCreateAlert(
purchase: purchase,
availablePrices: availablePrices,
);

_isLoading = false;
notifyListeners();
return true;
} catch (e, stackTrace) {
_isLoading = false;
_errorMessage = 'Could not complete demo purchase: $e';

debugPrint(_errorMessage);
debugPrintStack(stackTrace: stackTrace);

notifyListeners();
return false;
}
}

// Compare the purchase price with prices for the same item at other shops.
Future<void> _checkPriceAndCreateAlert({
required Purchase purchase,
required List<Price> availablePrices,
}) async {
final comparablePrices = availablePrices.where((price) {
return price.itemId == purchase.itemId &&
price.shopId != purchase.shopId &&
price.university.trim() == purchase.university.trim() &&
price.price.isFinite &&
price.price > 0;
}).toList();

if (comparablePrices.isEmpty) {
return;
}

final averagePrice = comparablePrices
    .map((price) => price.price)
    .reduce((a, b) => a + b) /
comparablePrices.length;

if (averagePrice <= 0) {
return;
}

final differencePercentage =
((purchase.unitPrice - averagePrice) / averagePrice) * 100;

if (differencePercentage <= alertThresholdPercentage) {
return;
}

final alertId =
'${purchase.id}_price_alert';

final alert = PriceAlert(
id: alertId,
university: purchase.university,
itemId: purchase.itemId,
itemName: purchase.itemName,
shopId: purchase.shopId,
shopName: purchase.shopName,
purchaseId: purchase.id,
transactionReference: purchase.paymentReference,
observedPrice: purchase.unitPrice,
comparisonPrice: averagePrice,
differencePercentage: differencePercentage,
unit: purchase.unit,
comparisonCount: comparablePrices.length,
status: 'pending',
reason:
'The recorded purchase price is more than '
'${alertThresholdPercentage.toStringAsFixed(0)}% above '
'the average price at other shops.',
createdAt: DateTime.now(),
isDemo: true,
);

await _firestoreService.savePriceAlert(alert);
}

// Listen for purchases made by the current student.
Future<void> fetchMyPurchases(String studentId) async {
await _myPurchasesSubscription?.cancel();

_myPurchasesSubscription =
_firestoreService.getPurchasesByStudent(studentId).listen(
(purchases) {
_myPurchases = purchases;
notifyListeners();
},
onError: (error) {
_errorMessage = 'Could not load purchase history: $error';
debugPrint(_errorMessage);
notifyListeners();
},
);
}

// Listen for purchases made at the current university.
Future<void> fetchUniversityPurchases(String university) async {
await _universityPurchasesSubscription?.cancel();

_universityPurchasesSubscription =
_firestoreService.getPurchasesByUniversity(university).listen(
(purchases) {
_universityPurchases = purchases;
notifyListeners();
},
onError: (error) {
_errorMessage = 'Could not load university purchases: $error';
debugPrint(_errorMessage);
notifyListeners();
},
);
}

// Listen for price alerts at the current university.
Future<void> fetchPriceAlerts(String university) async {
await _priceAlertsSubscription?.cancel();

_priceAlertsSubscription =
_firestoreService.getPriceAlertsByUniversity(university).listen(
(alerts) {
_priceAlerts = alerts;
notifyListeners();
},
onError: (error) {
_errorMessage = 'Could not load price alerts: $error';
debugPrint(_errorMessage);
notifyListeners();
},
);
}

// Save an administrator's decision about an alert.
Future<bool> reviewPriceAlert({
required String alertId,
required String status,
required String reviewedBy,
String? reviewNote,
}) async {
try {
await _firestoreService.updatePriceAlertStatus(
alertId: alertId,
status: status,
reviewedBy: reviewedBy,
reviewNote: reviewNote,
);

return true;
} catch (e) {
_errorMessage = 'Could not update price alert: $e';
debugPrint(_errorMessage);
notifyListeners();
return false;
}
}

// Clear the data when the provider is no longer needed.
void clearData() {
_myPurchasesSubscription?.cancel();
_universityPurchasesSubscription?.cancel();
_priceAlertsSubscription?.cancel();

_myPurchasesSubscription = null;
_universityPurchasesSubscription = null;
_priceAlertsSubscription = null;

_myPurchases = [];
_universityPurchases = [];
_priceAlerts = [];
_errorMessage = null;

notifyListeners();
}

@override
void dispose() {
_myPurchasesSubscription?.cancel();
_universityPurchasesSubscription?.cancel();
_priceAlertsSubscription?.cancel();
super.dispose();
}
}
