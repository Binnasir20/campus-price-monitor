import 'package:cloud_firestore/cloud_firestore.dart';

import '../model/item_model.dart';
import '../model/notification_model.dart';
import '../model/price_model.dart';
import '../model/complaint_model.dart';
import '../model/shop_model.dart';
import '../model/price_report_model.dart';
import '../model/user_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ============================================================
  // 1. GET ALL ITEMS
  // ============================================================

  Stream<List<Item>> getItems() {
    return _db.collection('items').snapshots().map(
          (snapshot) => snapshot.docs
          .map((doc) => Item.fromMap(doc.data(), doc.id))
          .toList(),
    );
  }

  // ============================================================
  // 2. ADD A NEW ITEM
  // ============================================================

  Future<String> addItem(Item item) async {
    final docRef = await _db.collection('items').add(item.toMap());
    return docRef.id;
  }

  // ============================================================
  // 3. UPDATE AN ITEM
  // ============================================================

  Future<void> updateItem(Item item) async {
    if (item.id.trim().isEmpty) {
      throw ArgumentError('Item ID cannot be empty.');
    }

    await _db.collection('items').doc(item.id).update(item.toMap());
  }

  // ============================================================
// DELETE ONE ITEM AND ITS ASSOCIATED PRICES
// ============================================================

  Future<void> deleteItem(
      String itemId, {
        String? itemName,
      }) async {
    if (itemId.trim().isEmpty) {
      throw ArgumentError('Item ID cannot be empty.');
    }

    final itemRef = _db.collection('items').doc(itemId);
    final pricesRef = _db.collection('prices');

    // Check that the item exists.
    final itemSnapshot = await itemRef.get();

    if (!itemSnapshot.exists) {
      throw Exception('Item not found: $itemId');
    }

    // Find all current prices belonging to this item.
    final pricesSnapshot = await pricesRef
        .where('itemId', isEqualTo: itemId)
        .get();

    // Delete prices and the item together when possible.
    final batch = _db.batch();

    for (final priceDoc in pricesSnapshot.docs) {
      batch.delete(priceDoc.reference);
    }

    batch.delete(itemRef);

    await batch.commit();
  }



  // ============================================================
  // 5. GET PRICES FOR A SPECIFIC UNIVERSITY
  // ============================================================

  Stream<List<Price>> getPricesByUniversity(String universityName) {
    return _db
        .collection('prices')
        .where(
      'university',
      isEqualTo: universityName.trim(),
    )
        .orderBy(
      'updatedAt',
      descending: true,
    )
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Price.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  // ============================================================
  // 6. SUBMIT A COMPLAINT
  // ============================================================

  Future<void> submitComplaint(Complaint complaint) async {
    await _db.collection('complaints').add(complaint.toMap());
  }

  // ============================================================
  // 7. ADD OR UPDATE A CURRENT PRICE
  // ============================================================

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

  // ============================================================
  // 8. GET VERIFIED SHOPS FOR A UNIVERSITY
  // ============================================================

  Stream<List<Shop>> getVerifiedShopsByUniversity(
      String universityName,
      ) {
    return _db
        .collection('shops')
        .where(
      'university',
      isEqualTo: universityName.trim(),
    )
        .where(
      'isVerified',
      isEqualTo: true,
    )
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
          .map((doc) => Shop.fromMap(doc.data(), doc.id))
          .toList(),
    );
  }

  // ============================================================
  // 9. ADD A NEW SHOP
  // ============================================================

  Future<void> addShop(Shop shop) async {
    await _db.collection('shops').add(shop.toMap());
  }

  // ============================================================
  // 10. GET ALL COMPLAINTS FOR ADMIN
  // ============================================================

  Stream<List<Complaint>> getAllComplaintsByUniversity(
      String universityName,
      ) {
    return _db
        .collection('complaints')
        .where(
      'university',
      isEqualTo: universityName.trim(),
    )
        .orderBy(
      'timestamp',
      descending: true,
    )
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
          .map((doc) => Complaint.fromMap(doc.data(), doc.id))
          .toList(),
    );
  }

  // ============================================================
  // 11. RESOLVE A COMPLAINT
  // ============================================================

  Future<void> resolveComplaint(String complaintId) async {
    if (complaintId.trim().isEmpty) {
      throw ArgumentError('Complaint ID cannot be empty.');
    }

    final complaintRef =
    _db.collection('complaints').doc(complaintId);

    final complaintDoc = await complaintRef.get();

    if (!complaintDoc.exists) {
      throw Exception('Complaint not found.');
    }

    await complaintRef.update({
      'status': 'resolved',
    });
  }

  // ============================================================
  // 12. SUBMIT A PRICE REPORT
  // ============================================================

  Future<void> submitPriceReport(PriceReport report) async {
    await _db.collection('priceReports').add(report.toMap());
  }

  // ============================================================
  // 13. GET PRICE REPORTS FOR ADMIN
  // ============================================================

  Stream<List<PriceReport>> getPriceReportsByUniversity(
      String universityName,
      ) {
    return _db
        .collection('priceReports')
        .where(
      'university',
      isEqualTo: universityName.trim(),
    )
        .orderBy(
      'reportedAt',
      descending: true,
    )
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
          .map((doc) => PriceReport.fromMap(doc.data(), doc.id))
          .toList(),
    );
  }

  // ============================================================
  // 14. UPDATE PRICE REPORT STATUS
  // ============================================================

  Future<void> updatePriceReportStatus(
      String reportId,
      String status,
      ) async {
    const allowedStatuses = {
      'pending',
      'approved',
      'rejected',
    };

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

    await reportRef.update({
      'status': status,
    });
  }

  // ============================================================
  // 15. MARK NOTIFICATION AS READ
  // ============================================================

  Future<void> markNotificationAsRead(String notificationId) async {
    if (notificationId.trim().isEmpty) {
      throw ArgumentError('Notification ID cannot be empty.');
    }

    await _db.collection('notifications').doc(notificationId).update({
      'isRead': true,
    });
  }

  // ============================================================
  // 16. GET NOTIFICATIONS FOR A SPECIFIC USER
  // ============================================================

  Stream<List<AppNotification>> getNotificationsByUser(String uid) {
    return _db
        .collection('notifications')
        .where(
      'userId',
      isEqualTo: uid,
    )
        .orderBy(
      'createdAt',
      descending: true,
    )
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
          .map(
            (doc) => AppNotification.fromMap(
          doc.data(),
          doc.id,
        ),
      )
          .toList(),
    );
  }

  // ============================================================
  // 17. GET USER NAME
  // ============================================================

  Future<String> getUserName(String uid) async {
    final userDoc = await _db.collection('users').doc(uid).get();

    if (userDoc.exists) {
      final data = userDoc.data();
      return data?['name']?.toString() ?? 'Unknown user';
    }

    final snapshot = await _db
        .collection('users')
        .where(
      'uid',
      isEqualTo: uid,
    )
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      return snapshot.docs.first.data()['name']?.toString() ??
          'Unknown user';
    }

    return 'Unknown user';
  }

  // ============================================================
  // 18. GET ALL USER NAMES
  // ============================================================

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

  // ============================================================
  // 19. GET PRICE REPORTS SUBMITTED BY A USER
  // ============================================================

  Stream<List<PriceReport>> getPriceReportsByUser(String uid) {
    return _db
        .collection('priceReports')
        .where(
      'reportedBy',
      isEqualTo: uid,
    )
        .orderBy(
      'reportedAt',
      descending: true,
    )
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
          .map((doc) => PriceReport.fromMap(doc.data(), doc.id))
          .toList(),
    );
  }

  // ============================================================
  // 20. GET SHOP NAME
  // ============================================================

  Future<String> getShopName(String shopId) async {
    final doc = await _db.collection('shops').doc(shopId).get();

    if (!doc.exists) {
      return 'Unknown Shop';
    }

    return doc.data()?['name']?.toString() ?? 'Unknown Shop';
  }

  // ============================================================
  // 21. VERIFY SHOP
  // ============================================================

  Future<void> verifyShop(String shopId) async {
    if (shopId.trim().isEmpty) {
      throw ArgumentError('Shop ID cannot be empty.');
    }

    await _db.collection('shops').doc(shopId).update({
      'isVerified': true,
    });
  }

  // ============================================================
  // 22. UPDATE SHOP
  // ============================================================

  Future<void> updateShop(Shop shop) async {
    if (shop.id.trim().isEmpty) {
      throw ArgumentError('Shop ID cannot be empty.');
    }

    await _db.collection('shops').doc(shop.id).update(shop.toMap());
  }

  // ============================================================
  // 23. DELETE SHOP
  // ============================================================

  Future<void> deleteShop(String shopId) async {
    if (shopId.trim().isEmpty) {
      throw ArgumentError('Shop ID cannot be empty.');
    }

    // Delete associated current prices first.
    final prices = await _db
        .collection('prices')
        .where('shopId', isEqualTo: shopId)
        .get();

    final priceIds = prices.docs.map((doc) => doc.id).toList();

    for (var i = 0; i < priceIds.length; i += 450) {
      final batch = _db.batch();
      final end =
      (i + 450 < priceIds.length) ? i + 450 : priceIds.length;

      for (var j = i; j < end; j++) {
        batch.delete(_db.collection('prices').doc(priceIds[j]));
      }

      await batch.commit();
    }

    await _db.collection('shops').doc(shopId).delete();
  }

  // ============================================================
  // 24. GET UNVERIFIED SHOPS FOR ADMIN
  // ============================================================

  Stream<List<Shop>> getUnverifiedShopsForAdmin(
      String universityName,
      ) {
    return _db
        .collection('shops')
        .where(
      'university',
      isEqualTo: universityName.trim(),
    )
        .where(
      'isVerified',
      isEqualTo: false,
    )
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
          .map((doc) => Shop.fromMap(doc.data(), doc.id))
          .toList(),
    );
  }

  // ============================================================
  // 25. GET ALL SHOPS FOR ADMIN
  // ============================================================

  Stream<List<Shop>> getAllShopsForAdmin(String universityName) {
    return _db
        .collection('shops')
        .where(
      'university',
      isEqualTo: universityName.trim(),
    )
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
          .map((doc) => Shop.fromMap(doc.data(), doc.id))
          .toList(),
    );
  }

  // ============================================================
  // 26. GET ALL USERS
  // ============================================================

  Stream<List<UserModel>> getAllUsers() {
    return _db.collection('users').snapshots().map(
          (snapshot) => snapshot.docs
          .map((doc) => UserModel.fromMap(doc.data()))
          .toList(),
    );
  }

  // ============================================================
  // 27. GET COMPLAINTS SUBMITTED BY A USER
  // ============================================================

  Stream<List<Complaint>> getUserComplaints(String userId) {
    return _db
        .collection('complaints')
        .where(
      'userId',
      isEqualTo: userId,
    )
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
          .map((doc) => Complaint.fromMap(doc.data(), doc.id))
          .toList(),
    );
  }

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
      throw Exception('No current price found for this item in the selected shop.');
    }

    // Delete in batches to avoid Firestore's 500-operation limit.
    for (var i = 0; i < snapshot.docs.length; i += 450) {
      final batch = _db.batch();
      final end = (i + 450 < snapshot.docs.length)
          ? i + 450
          : snapshot.docs.length;

      for (var j = i; j < end; j++) {
        batch.delete(snapshot.docs[j].reference);
      }

      await batch.commit();
    }
  }


  // ============================================================
  // 28. GET ALL COMPLAINTS BELONGING TO A UNIVERSITY
  // ============================================================

  Stream<List<Complaint>> getComplaintsByUniversity(
      String universityName,
      ) {
    return _db
        .collection('complaints')
        .where(
      'university',
      isEqualTo: universityName.trim(),
    )
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
          .map((doc) => Complaint.fromMap(doc.data(), doc.id))
          .toList(),
    );
  }
}