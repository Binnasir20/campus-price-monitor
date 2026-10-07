import 'package:cloud_firestore/cloud_firestore.dart';

import '../model/item_model.dart';
import '../model/notification_model.dart';
import '../model/price_model.dart';
import '../model/complaint_model.dart';
import '../model/shop_model.dart';
import '../model/price_report_model.dart';

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

  // 1b. ADD A NEW ITEM (Admin only)

  Future<void> addItem(Item item) async {
    await _db.collection('items').add(item.toMap());
  }

  // 1c. UPDATE AN ITEM (Admin only)

  Future<void> updateItem(Item item) async {
    await _db.collection('items').doc(item.id).update(item.toMap());
  }

  // 1d. DELETE AN ITEM (Admin only)

  Future<void> deleteItem(String itemId) async {
    await _db.collection('items').doc(itemId).delete();
  }

  // ============================================================
  // 2. GET PRICES FOR A SPECIFIC UNIVERSITY
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
      print("========== PRICES FROM FIRESTORE ==========");
      print("University: ${universityName.trim()}");
      print("Number of price documents: ${snapshot.docs.length}");

      for (var doc in snapshot.docs) {
        print("PRICE DOC ID: ${doc.id}");
        print("ITEM ID: ${doc.data()['itemId']}");
      }

      print("==========================================");

      return snapshot.docs
          .map((doc) => Price.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  // ============================================================
  // 3. SUBMIT A COMPLAINT
  // ============================================================

  Future<void> submitComplaint(Complaint complaint) async {
    await _db.collection('complaints').add(complaint.toMap());
  }

  // ============================================================
  // 4. REPORT / UPDATE A PRICE
  // ============================================================

  Future<void> updatePrice(Price price) async {
    final uniqueId =
        "${price.shopId}_${price.itemId.replaceAll(' ', '_')}";

    await _db
        .collection('prices')
        .doc(uniqueId)
        .set(price.toMap());
  }

  // ============================================================
  // 5. GET ONLY VERIFIED SHOPS
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
  // 6. ADD A NEW SHOP
  // ============================================================

  Future<void> addShop(Shop shop) async {
    await _db.collection('shops').add(shop.toMap());
  }

  // ============================================================
  // 7. GET ALL COMPLAINTS FOR ADMIN
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
  // 8. DELETE A COMPLAINT
  // ============================================================

  Future<void> deleteComplaint(String complaintId) async {
    await _db
        .collection('complaints')
        .doc(complaintId)
        .delete();
  }

  // ============================================================
  // 9. SUBMIT A PRICE REPORT
  // ============================================================

  Future<void> submitPriceReport(PriceReport report) async {
    await _db
        .collection('priceReports')
        .add(report.toMap());
  }

  // ============================================================
  // 10. GET PRICE REPORTS FOR ADMIN
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
  // 11. UPDATE PRICE REPORT STATUS
  // ============================================================

  Future<void> updatePriceReportStatus(
      String reportId,
      String status,
      ) async {
    final reportDoc = await _db
        .collection('priceReports')
        .doc(reportId)
        .get();

    if (!reportDoc.exists) {
      throw Exception('Price report not found');
    }

    await _db
        .collection('priceReports')
        .doc(reportId)
        .update({
      'status': status,
    });
  }

  // ============================================================
  // 12. MARK NOTIFICATION AS READ
  // ============================================================

  Future<void> markNotificationAsRead(
      String notificationId,
      ) async {
    await _db
        .collection('notifications')
        .doc(notificationId)
        .update({
      'isRead': true,
    });
  }

  // ============================================================
  // 13. GET NOTIFICATIONS FOR A SPECIFIC USER
  // ============================================================

  Stream<List<AppNotification>> getNotificationsByUser(
      String uid,
      ) {
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
  // 14. GET USER NAME
  // ============================================================

  Future<String> getUserName(String uid) async {
    // First, check if the UID is the document ID.
    final userDoc = await _db
        .collection('users')
        .doc(uid)
        .get();

    if (userDoc.exists) {
      final data = userDoc.data();

      return data?['name'] ?? 'Unknown user';
    }

    // If not, search for the UID inside the document.
    final snapshot = await _db
        .collection('users')
        .where(
      'uid',
      isEqualTo: uid,
    )
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      final data = snapshot.docs.first.data();

      return data['name'] ?? 'Unknown user';
    }

    return 'Unknown user';
  }

  // ============================================================
  // 15. GET ALL USER NAMES
  // ============================================================

  Future<Map<String, String>> getUserNames() async {
    final snapshot = await _db
        .collection('users')
        .get();

    final Map<String, String> userNames = {};

    for (final doc in snapshot.docs) {
      final data = doc.data();

      final uid = data['uid'] ?? doc.id;
      final name = data['name'] ?? 'Unknown user';

      userNames[uid] = name;
    }

    return userNames;
  }

  // ============================================================
  // 16. GET PRICE REPORTS SUBMITTED BY A USER
  // ============================================================

  Stream<List<PriceReport>> getPriceReportsByUser(
      String uid,
      ) {
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
  // 17. GET SHOP NAME
  // ============================================================

  Future<String> getShopName(String shopId) async {
    final doc = await _db
        .collection('shops')
        .doc(shopId)
        .get();

    if (!doc.exists) {
      return 'Unknown Shop';
    }

    return doc.data()?['name'] ?? 'Unknown Shop';
  }

  // ============================================================
  // ADMIN METHODS
  // ============================================================

  // 18. VERIFY SHOP

  Future<void> verifyShop(String shopId) async {
    await _db
        .collection('shops')
        .doc(shopId)
        .update({
      'isVerified': true,
    });
  }

  // 19. UPDATE SHOP

  Future<void> updateShop(Shop shop) async {
    await _db
        .collection('shops')
        .doc(shop.id)
        .update(shop.toMap());
  }

  // 20. DELETE SHOP

  Future<void> deleteShop(String shopId) async {
    await _db
        .collection('shops')
        .doc(shopId)
        .delete();
  }

  // 21. GET UNVERIFIED SHOPS FOR ADMIN

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

  // 22. GET ALL SHOPS FOR ADMIN

  Stream<List<Shop>> getAllShopsForAdmin(
      String universityName,
      ) {
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
}