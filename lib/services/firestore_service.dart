import 'package:cloud_firestore/cloud_firestore.dart';

import '../model/item_model.dart';
import '../model/notification_model.dart';
import '../model/price_model.dart';
import '../model/complaint_model.dart';
import '../model/shop_model.dart';
import '../model/price_report_model.dart';
import '../model/user_model.dart';
import '../model/purchase_model.dart';
import '../model/price_alert_model.dart';

class FirestoreService {
final FirebaseFirestore _db = FirebaseFirestore.instance;

// Get all registered items.
Stream<List<Item>> getItems() {
return _db.collection('items').snapshots().map(
(snapshot) => snapshot.docs
    .map((doc) => Item.fromMap(doc.data(), doc.id))
    .toList(),
);
}

// Add a new item.
Future<String> addItem(Item item) async {
final docRef = await _db.collection('items').add(item.toMap());
return docRef.id;
}

// Update an existing item.
Future<void> updateItem(Item item) async {
if (item.id.trim().isEmpty) {
throw ArgumentError('Item ID cannot be empty.');
}

await _db.collection('items').doc(item.id).update(item.toMap());
}

// Delete an item and its current prices.
Future<void> deleteItem(
String itemId, {
String? itemName,
}) async {
if (itemId.trim().isEmpty) {
throw ArgumentError('Item ID cannot be empty.');
}

final itemRef = _db.collection('items').doc(itemId);
final itemSnapshot = await itemRef.get();

if (!itemSnapshot.exists) {
throw Exception('Item not found: $itemId');
}

final pricesSnapshot = await _db
    .collection('prices')
    .where('itemId', isEqualTo: itemId)
    .get();

final batch = _db.batch();

for (final priceDoc in pricesSnapshot.docs) {
batch.delete(priceDoc.reference);
}

batch.delete(itemRef);

await batch.commit();
}

// Get current prices for a university.
Stream<List<Price>> getPricesByUniversity(String universityName) {
return _db
    .collection('prices')
    .where('university', isEqualTo: universityName.trim())
    .orderBy('updatedAt', descending: true)
    .snapshots()
    .map(
(snapshot) => snapshot.docs
    .map((doc) => Price.fromMap(doc.data(), doc.id))
    .toList(),
);
}

// Submit a complaint.
Future<void> submitComplaint(Complaint complaint) async {
await _db.collection('complaints').add(complaint.toMap());
}

// Add or update the current price of an item in a shop.
Future<void> updatePrice(Price price) async {
if (price.itemId.trim().isEmpty ||
price.shopId.trim().isEmpty ||
price.university.trim().isEmpty) {
throw ArgumentError('Item, shop, and university are required.');
}

if (!price.price.isFinite || price.price <= 0) {
throw ArgumentError('Price must be greater than zero.');
}

final priceId = price.id.trim().isNotEmpty
? price.id
    : '${price.shopId}_${price.itemId.replaceAll(' ', '_')}';

await _db.collection('prices').doc(priceId).set(
price.toMap(),
SetOptions(merge: true),
);
}

// Get verified shops at a university.
Stream<List<Shop>> getVerifiedShopsByUniversity(
String universityName,
) {
return _db
    .collection('shops')
    .where('university', isEqualTo: universityName.trim())
    .where('isVerified', isEqualTo: true)
    .snapshots()
    .map(
(snapshot) => snapshot.docs
    .map((doc) => Shop.fromMap(doc.data(), doc.id))
    .toList(),
);
}

// Add a shop.
Future<void> addShop(Shop shop) async {
await _db.collection('shops').add(shop.toMap());
}

// Get complaints for a university.
Stream<List<Complaint>> getAllComplaintsByUniversity(
String universityName,
) {
return _db
    .collection('complaints')
    .where('university', isEqualTo: universityName.trim())
    .orderBy('timestamp', descending: true)
    .snapshots()
    .map(
(snapshot) => snapshot.docs
    .map((doc) => Complaint.fromMap(doc.data(), doc.id))
    .toList(),
);
}

// Mark a complaint as resolved.
Future<void> resolveComplaint(String complaintId) async {
if (complaintId.trim().isEmpty) {
throw ArgumentError('Complaint ID cannot be empty.');
}

final complaintRef = _db.collection('complaints').doc(complaintId);
final complaintDoc = await complaintRef.get();

if (!complaintDoc.exists) {
throw Exception('Complaint not found.');
}

await complaintRef.update({'status': 'resolved'});
}

// Submit a price report.
Future<void> submitPriceReport(PriceReport report) async {
await _db.collection('priceReports').add(report.toMap());
}

// Get price reports for a university.
Stream<List<PriceReport>> getPriceReportsByUniversity(
String universityName,
) {
return _db
    .collection('priceReports')
    .where('university', isEqualTo: universityName.trim())
    .orderBy('reportedAt', descending: true)
    .snapshots()
    .map(
(snapshot) => snapshot.docs
    .map((doc) => PriceReport.fromMap(doc.data(), doc.id))
    .toList(),
);
}

// Update a price report's status.
Future<void> updatePriceReportStatus(
String reportId,
String status,
) async {
const allowedStatuses = {'pending', 'approved', 'rejected'};

if (reportId.trim().isEmpty) {
throw ArgumentError('Report ID cannot be empty.');
}

if (!allowedStatuses.contains(status)) {
throw ArgumentError('Invalid price report status: $status');
}

final reportRef = _db.collection('priceReports').doc(reportId);
final reportDoc = await reportRef.get();

if (!reportDoc.exists) {
throw Exception('Price report not found.');
}

await reportRef.update({'status': status});
}

// Mark a notification as read.
Future<void> markNotificationAsRead(String notificationId) async {
if (notificationId.trim().isEmpty) {
throw ArgumentError('Notification ID cannot be empty.');
}

await _db.collection('notifications').doc(notificationId).update({
'isRead': true,
});
}

// Get notifications belonging to a user.
Stream<List<AppNotification>> getNotificationsByUser(String uid) {
return _db
    .collection('notifications')
    .where('userId', isEqualTo: uid)
    .orderBy('createdAt', descending: true)
    .snapshots()
    .map(
(snapshot) => snapshot.docs
    .map(
(doc) => AppNotification.fromMap(doc.data(), doc.id),
)
    .toList(),
);
}

// Get a user's name.
Future<String> getUserName(String uid) async {
final userDoc = await _db.collection('users').doc(uid).get();

if (userDoc.exists) {
return userDoc.data()?['name']?.toString() ?? 'Unknown user';
}

final snapshot = await _db
    .collection('users')
    .where('uid', isEqualTo: uid)
    .limit(1)
    .get();

if (snapshot.docs.isNotEmpty) {
return snapshot.docs.first.data()['name']?.toString() ??
'Unknown user';
}

return 'Unknown user';
}

// Get the names of all users.
Future<Map<String, String>> getUserNames() async {
final snapshot = await _db.collection('users').get();
final Map<String, String> userNames = {};

for (final doc in snapshot.docs) {
final data = doc.data();
final uid = data['uid']?.toString() ?? doc.id;
final name = data['name']?.toString() ?? 'Unknown user';

userNames[uid] = name;
}

return userNames;
}

// Get price reports submitted by a user.
Stream<List<PriceReport>> getPriceReportsByUser(String uid) {
return _db
    .collection('priceReports')
    .where('reportedBy', isEqualTo: uid)
    .orderBy('reportedAt', descending: true)
    .snapshots()
    .map(
(snapshot) => snapshot.docs
    .map((doc) => PriceReport.fromMap(doc.data(), doc.id))
    .toList(),
);
}

// Get a shop's name.
Future<String> getShopName(String shopId) async {
final doc = await _db.collection('shops').doc(shopId).get();

if (!doc.exists) {
return 'Unknown Shop';
}

return doc.data()?['name']?.toString() ?? 'Unknown Shop';
}

// Verify a shop.
Future<void> verifyShop(String shopId) async {
if (shopId.trim().isEmpty) {
throw ArgumentError('Shop ID cannot be empty.');
}

await _db.collection('shops').doc(shopId).update({
'isVerified': true,
});
}

// Update a shop.
Future<void> updateShop(Shop shop) async {
if (shop.id.trim().isEmpty) {
throw ArgumentError('Shop ID cannot be empty.');
}

await _db.collection('shops').doc(shop.id).update(shop.toMap());
}

// Delete a shop and its current prices.
Future<void> deleteShop(String shopId) async {
if (shopId.trim().isEmpty) {
throw ArgumentError('Shop ID cannot be empty.');
}

final prices = await _db
    .collection('prices')
    .where('shopId', isEqualTo: shopId)
    .get();

for (var i = 0; i < prices.docs.length; i += 450) {
final batch = _db.batch();
final end =
(i + 450 < prices.docs.length) ? i + 450 : prices.docs.length;

for (var j = i; j < end; j++) {
batch.delete(prices.docs[j].reference);
}

await batch.commit();
}

await _db.collection('shops').doc(shopId).delete();
}

// Get shops that are waiting for verification.
Stream<List<Shop>> getUnverifiedShopsForAdmin(
String universityName,
) {
return _db
    .collection('shops')
    .where('university', isEqualTo: universityName.trim())
    .where('isVerified', isEqualTo: false)
    .snapshots()
    .map(
(snapshot) => snapshot.docs
    .map((doc) => Shop.fromMap(doc.data(), doc.id))
    .toList(),
);
}

// Get all shops belonging to a university.
Stream<List<Shop>> getAllShopsForAdmin(String universityName) {
return _db
    .collection('shops')
    .where('university', isEqualTo: universityName.trim())
    .snapshots()
    .map(
(snapshot) => snapshot.docs
    .map((doc) => Shop.fromMap(doc.data(), doc.id))
    .toList(),
);
}

// Get all registered users.
Stream<List<UserModel>> getAllUsers() {
return _db.collection('users').snapshots().map(
(snapshot) => snapshot.docs
    .map((doc) => UserModel.fromMap(doc.data()))
    .toList(),
);
}

// Get complaints submitted by a user.
Stream<List<Complaint>> getUserComplaints(String userId) {
return _db
    .collection('complaints')
    .where('userId', isEqualTo: userId)
    .snapshots()
    .map(
(snapshot) => snapshot.docs
    .map((doc) => Complaint.fromMap(doc.data(), doc.id))
    .toList(),
);
}

// Get all complaints for a university.
Stream<List<Complaint>> getComplaintsByUniversity(
String universityName,
) {
return _db
    .collection('complaints')
    .where('university', isEqualTo: universityName.trim())
    .snapshots()
    .map(
(snapshot) => snapshot.docs
    .map((doc) => Complaint.fromMap(doc.data(), doc.id))
    .toList(),
);
}

// Remove an item's current price from a shop.
Future<void> removeItemFromShop({
required String itemId,
required String shopId,
}) async {
if (itemId.trim().isEmpty || shopId.trim().isEmpty) {
throw ArgumentError('Item ID and Shop ID are required.');
}

final snapshot = await _db
    .collection('prices')
    .where('itemId', isEqualTo: itemId)
    .where('shopId', isEqualTo: shopId)
    .get();

if (snapshot.docs.isEmpty) {
throw Exception(
'No current price found for this item in the selected shop.',
);
}

for (var i = 0; i < snapshot.docs.length; i += 450) {
final batch = _db.batch();
final end =
(i + 450 < snapshot.docs.length) ? i + 450 : snapshot.docs.length;

for (var j = i; j < end; j++) {
batch.delete(snapshot.docs[j].reference);
}

await batch.commit();
}
}

// Save a completed demo purchase.
Future<void> savePurchase(Purchase purchase) async {
if (purchase.id.trim().isEmpty) {
throw ArgumentError('Purchase ID cannot be empty.');
}

if (purchase.studentId.trim().isEmpty ||
purchase.itemId.trim().isEmpty ||
purchase.shopId.trim().isEmpty ||
purchase.university.trim().isEmpty) {
throw ArgumentError(
'Student, university, item, and shop are required.',
);
}

if (!purchase.quantity.isFinite ||
purchase.quantity <= 0 ||
!purchase.unitPrice.isFinite ||
purchase.unitPrice <= 0) {
throw ArgumentError(
'Quantity and unit price must be greater than zero.',
);
}

final expectedTotal = purchase.quantity * purchase.unitPrice;

if ((purchase.totalAmount - expectedTotal).abs() > 0.01) {
throw ArgumentError(
'Purchase total does not match quantity and price.',
);
}

if (purchase.paymentStatus != 'successful' || !purchase.isDemo) {
throw ArgumentError(
'Only successful demo purchases are supported.',
);
}

await _db
    .collection('purchases')
    .doc(purchase.id)
    .set(purchase.toMap());
}

// Get a student's purchase history.
Stream<List<Purchase>> getPurchasesByStudent(String studentId) {
return _db
    .collection('purchases')
    .where('studentId', isEqualTo: studentId)
    .orderBy('purchasedAt', descending: true)
    .snapshots()
    .map(
(snapshot) => snapshot.docs
    .map((doc) => Purchase.fromMap(doc.data(), doc.id))
    .toList(),
);
}

// Get purchase records for a university.
Stream<List<Purchase>> getPurchasesByUniversity(
String universityName,
) {
return _db
    .collection('purchases')
    .where('university', isEqualTo: universityName.trim())
    .orderBy('purchasedAt', descending: true)
    .snapshots()
    .map(
(snapshot) => snapshot.docs
    .map((doc) => Purchase.fromMap(doc.data(), doc.id))
    .toList(),
);
}

// Save a new price alert.
Future<void> savePriceAlert(PriceAlert alert) async {
if (alert.id.trim().isEmpty ||
alert.university.trim().isEmpty ||
alert.itemId.trim().isEmpty ||
alert.shopId.trim().isEmpty) {
throw ArgumentError(
'Alert ID, university, item, and shop are required.',
);
}

if (!alert.observedPrice.isFinite ||
!alert.comparisonPrice.isFinite ||
!alert.differencePercentage.isFinite ||
alert.observedPrice <= 0 ||
alert.comparisonPrice <= 0 ||
alert.differencePercentage < 0) {
throw ArgumentError('Alert prices and percentage are invalid.');
}

if (alert.status != 'pending') {
throw ArgumentError('New alerts must have pending status.');
}

await _db
    .collection('priceAlerts')
    .doc(alert.id)
    .set(alert.toMap());
}

// Get price alerts for a university.
Stream<List<PriceAlert>> getPriceAlertsByUniversity(
String universityName,
) {
return _db
    .collection('priceAlerts')
    .where('university', isEqualTo: universityName.trim())
    .orderBy('createdAt', descending: true)
    .snapshots()
    .map(
(snapshot) => snapshot.docs
    .map((doc) => PriceAlert.fromMap(doc.data(), doc.id))
    .toList(),
);
}

// Save an administrator's decision on a price alert.
Future<void> updatePriceAlertStatus({
required String alertId,
required String status,
required String reviewedBy,
String? reviewNote,
}) async {
const allowedStatuses = {
'under_review',
'confirmed',
'dismissed',
'resolved',
};

if (alertId.trim().isEmpty || reviewedBy.trim().isEmpty) {
throw ArgumentError('Alert ID and reviewer ID are required.');
}

if (!allowedStatuses.contains(status)) {
throw ArgumentError('Invalid price alert status: $status');
}

final alertRef = _db.collection('priceAlerts').doc(alertId);
final alertDoc = await alertRef.get();

if (!alertDoc.exists) {
throw Exception('Price alert not found.');
}

final currentStatus = alertDoc.data()?['status'];

if (currentStatus == 'dismissed' || currentStatus == 'resolved') {
throw StateError('This alert has already been closed.');
}

await alertRef.update({
'status': status,
'reviewedBy': reviewedBy,
'reviewedAt': FieldValue.serverTimestamp(),
'reviewNote': reviewNote?.trim(),
});
}
}
