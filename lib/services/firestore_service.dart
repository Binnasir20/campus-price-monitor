import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/item_model.dart';
import '../model/price_model.dart';
import '../model/complaint_model.dart';
import '../model/shop_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 1. GET ALL ITEMS
  Stream<List<Item>> getItems() {
    return _db.collection('items').snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => Item.fromMap(doc.data(), doc.id)).toList());
  }

  // 2. GET PRICES FOR A SPECIFIC UNIVERSITY
  Stream<List<Price>> getPricesByUniversity(String universityName) {
    return _db
        .collection('prices')
        .where('university', isEqualTo: universityName.trim())
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => Price.fromMap(doc.data(), doc.id)).toList());
  }

  // 3. SUBMIT A COMPLAINT
  Future<void> submitComplaint(Complaint complaint) async {
    await _db.collection('complaints').add(complaint.toMap());
  }

  // 4. REPORT/UPDATE A PRICE
  Future<void> updatePrice(Price price) async {
    String uniqueId = "${price.shopId}_${price.itemId.replaceAll(' ', '_')}";
    await _db.collection('prices').doc(uniqueId).set(price.toMap());
  }

  // 5. GET ONLY VERIFIED SHOPS
  Stream<List<Shop>> getVerifiedShopsByUniversity(String universityName) {
    return _db
        .collection('shops')
        .where('university', isEqualTo: universityName.trim())
        .where('isVerified', isEqualTo: true)
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => Shop.fromMap(doc.data(), doc.id)).toList());
  }

  // 6. ADD A NEW SHOP (Now logic handles Admin only via Rules)
  Future<void> addShop(Shop shop) async {
    await _db.collection('shops').add(shop.toMap());
  }

  // 7. GET ALL COMPLAINTS FOR ADMIN
  Stream<List<Complaint>> getAllComplaintsByUniversity(String universityName) {
    return _db
        .collection('complaints')
        .where('university', isEqualTo: universityName.trim())
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => Complaint.fromMap(doc.data(), doc.id)).toList());
  }

  // 8. DELETE A COMPLAINT
  Future<void> deleteComplaint(String complaintId) async {
    await _db.collection('complaints').doc(complaintId).delete();
  }

  // --- ADMIN METHODS ---

  Future<void> verifyShop(String shopId) async {
    await _db.collection('shops').doc(shopId).update({'isVerified': true});
  }

  Future<void> deleteShop(String shopId) async {
    await _db.collection('shops').doc(shopId).delete();
  }

  Stream<List<Shop>> getUnverifiedShopsForAdmin(String universityName) {
    return _db
        .collection('shops')
        .where('university', isEqualTo: universityName.trim())
        .where('isVerified', isEqualTo: false)
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => Shop.fromMap(doc.data(), doc.id)).toList());
  }

  Stream<List<Shop>> getAllShopsForAdmin(String universityName) {
    return _db
        .collection('shops')
        .where('university', isEqualTo: universityName.trim())
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => Shop.fromMap(doc.data(), doc.id)).toList());
  }
}