class UserModel {
  final String uid;        // Unique ID from Firebase Auth
  final String name;       // User's full name
  final String email;      // User's email address
  final String university; // Their University (e.g., UDUS)
  final String campus;     // Their specific campus
  final bool isAdmin;      // Permission level (Admin or Student)

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.university,
    required this.campus,
    this.isAdmin = false,  // New users are students by default
  });

  /// 1. PACKAGING: Convert the User Object into a Map to save in Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'university': university,
      'campus': campus,
      'isAdmin': isAdmin,
    };
  }

  /// 2. UNPACKING: Create a User Object from a Firestore Map
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      university: map['university'] ?? '',
      campus: map['campus'] ?? '',
      // If 'isAdmin' is missing in the database, default to false
      isAdmin: map['isAdmin'] ?? false,
    );
  }
}