
import 'dart:io';

import 'package:path_provider/path_provider.dart';

class LocalProfileImageService {
// Get the application's private directory for profile pictures.
static Future<Directory> _getProfileImagesDirectory() async {
final appDirectory = await getApplicationDocumentsDirectory();

final profileImagesDirectory = Directory(
'${appDirectory.path}/profile_images',
);

if (!await profileImagesDirectory.exists()) {
await profileImagesDirectory.create(recursive: true);
}

return profileImagesDirectory;
}

// Save a user's profile picture using their Firebase UID.
static Future<String> saveProfileImage({
required String uid,
required File imageFile,
}) async {
if (uid.trim().isEmpty) {
throw ArgumentError('User ID cannot be empty.');
}

if (!await imageFile.exists()) {
throw Exception('The selected image does not exist.');
}

final directory = await _getProfileImagesDirectory();

final savedImage = File(
'${directory.path}/$uid.jpg',
);

// Copy the selected image into the application's private storage.
await imageFile.copy(savedImage.path);

return savedImage.path;
}

// Retrieve the saved profile picture for a user.
static Future<File?> getProfileImage(String uid) async {
if (uid.trim().isEmpty) return null;

final directory = await _getProfileImagesDirectory();

final imageFile = File(
'${directory.path}/$uid.jpg',
);

if (await imageFile.exists()) {
return imageFile;
}

return null;
}

// Delete a user's locally saved profile picture.
static Future<void> deleteProfileImage(String uid) async {
if (uid.trim().isEmpty) return;

final directory = await _getProfileImagesDirectory();

final imageFile = File(
'${directory.path}/$uid.jpg',
);

if (await imageFile.exists()) {
await imageFile.delete();
}
}
}
