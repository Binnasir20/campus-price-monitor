class Shop {
  final String id;
  final String name;
  final String university;
  final String location;
  final String campus;
  final bool isVerified;
  final String createdBy;
  // NEW: Flag to tell Admin if this might be a duplicate
  final bool isPotentialDuplicate;

  Shop({
    required this.id,
    required this.name,
    required this.university,
    required this.location,
    required this.campus,
    required this.createdBy,
    this.isVerified = false,
    this.isPotentialDuplicate = false, // Default to false
  });

  // 1. PACKAGING: Turn the object into a Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'university': university,
      'location': location,
      'campus': campus,
      'isVerified': isVerified,
      'createdBy': createdBy,
      'isPotentialDuplicate': isPotentialDuplicate, // Added this
    };
  }

  // 2. UNPACKING: Turn a Firestore Map back into a Shop object
  factory Shop.fromMap(Map<String, dynamic> map, String docId) {
    return Shop(
      id: docId,
      name: map['name'] ?? '',
      university: map['university'] ?? '',
      location: map['location'] ?? '',
      campus: map['campus'] ?? '',
      isVerified: map['isVerified'] ?? false,
      createdBy: map['createdBy'] ?? 'admin',
      // Added this with a fallback to false
      isPotentialDuplicate: map['isPotentialDuplicate'] ?? false,
    );
  }
}