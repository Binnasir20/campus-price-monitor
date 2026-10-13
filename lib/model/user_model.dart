
class UserModel {
final String uid;
final String name;
final String email;
final String university;
final String campus;
final bool isAdmin;

// Retained for compatibility with existing remote image URLs.
final String? profileImageUrl;

// Local path on the current device.
final String? localProfileImagePath;

UserModel({
required this.uid,
required this.name,
required this.email,
required this.university,
required this.campus,
this.isAdmin = false,
this.profileImageUrl,
this.localProfileImagePath,
});

// Convert the user object into a Firestore map.
Map<String, dynamic> toMap() {
return {
'uid': uid,
'name': name,
'email': email,
'university': university,
'campus': campus,
'isAdmin': isAdmin,
'profileImageUrl': profileImageUrl,

// Do not save localProfileImagePath in Firestore.
// The path belongs to this device only.
};
}

// Create a user object from a Firestore map.
factory UserModel.fromMap(Map<String, dynamic> map) {
return UserModel(
uid: map['uid'] ?? '',
name: map['name'] ?? '',
email: map['email'] ?? '',
university: map['university'] ?? '',
campus: map['campus'] ?? '',
isAdmin: map['isAdmin'] ?? false,
profileImageUrl: map['profileImageUrl'],
);
}

// Create a copy while preserving fields that haven't changed.
UserModel copyWith({
String? name,
String? email,
String? university,
String? campus,
bool? isAdmin,
String? profileImageUrl,
String? localProfileImagePath,
bool clearProfileImageUrl = false,
bool clearLocalProfileImagePath = false,
}) {
return UserModel(
uid: uid,
name: name ?? this.name,
email: email ?? this.email,
university: university ?? this.university,
campus: campus ?? this.campus,
isAdmin: isAdmin ?? this.isAdmin,
profileImageUrl: clearProfileImageUrl
? null
    : profileImageUrl ?? this.profileImageUrl,
localProfileImagePath: clearLocalProfileImagePath
? null
    : localProfileImagePath ?? this.localProfileImagePath,
);
}
}
