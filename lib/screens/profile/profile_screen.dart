import 'dart:io';

import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/price_provider.dart';
import '../../providers/complaint_provider.dart';
import '../admin/admin_dashboard.dart';
import '../reported_screen/reported_item_screen.dart';

class ProfileScreen extends StatefulWidget {
const ProfileScreen({super.key});

@override
State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
final ImagePicker _picker = ImagePicker();

bool _isChangingPicture = false;

Future<void> _changeProfilePicture() async {
if (_isChangingPicture) return;

try {
setState(() {
_isChangingPicture = true;
});

final pickedFile = await _picker.pickImage(
source: ImageSource.gallery,
imageQuality: 80,
);

if (!mounted) return;

if (pickedFile == null) return;

final authProvider = Provider.of<AuthProvider>(
context,
listen: false,
);

final success = await authProvider.updateProfilePicture(
File(pickedFile.path),
);

if (!mounted) return;

ScaffoldMessenger.of(context).showSnackBar(
SnackBar(
content: Text(
success
? 'Profile picture updated.'
    : 'Failed to update profile picture.',
),
backgroundColor: success ? Colors.green : Colors.red,
),
);
} catch (e) {
if (!mounted) return;

ScaffoldMessenger.of(context).showSnackBar(
SnackBar(
content: Text('Unable to update profile picture: $e'),
backgroundColor: Colors.red,
),
);
} finally {
if (mounted) {
setState(() {
_isChangingPicture = false;
});
}
}
}

@override
Widget build(BuildContext context) {
final authProvider = Provider.of<AuthProvider>(context);
final user = authProvider.userModel;

final priceProv = Provider.of<PriceProvider>(context);
final complaintProv = Provider.of<ComplaintProvider>(context);

// Statistics logic.
int reportCount = 0;
int complaintCount = 0;

if (user != null) {
if (user.isAdmin) {
// Admin sees university-wide statistics.
reportCount = priceProv.priceReports.length;
complaintCount = complaintProv.universityComplaints.length;
} else {
// Students see their own contributions.
reportCount = priceProv.myPriceReports.length;
complaintCount = complaintProv.userComplaints.length;
}
}

return Scaffold(
appBar: AppBar(
automaticallyImplyLeading: false,
title: const Text(
'My Profile',
style: TextStyle(
fontSize: 17,
fontWeight: FontWeight.bold,
),
),
backgroundColor: Colors.teal,
foregroundColor: Colors.white,
elevation: 0,
),
body: SingleChildScrollView(
child: Column(
children: [
// 1. Header section.
_buildHeader(user),

const SizedBox(height: 20),

// 2. Campus information.
_buildInfoCard(user),

// 3. Student reports.
if (user != null && !user.isAdmin)
_buildMyReportsLink(context),

// 4. Admin dashboard.
if (user?.isAdmin == true) _buildAdminLink(context),

const SizedBox(height: 30),

// 5. Statistics section.
Padding(
padding: const EdgeInsets.symmetric(horizontal: 20),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(
user?.isAdmin == true
? 'University Overview'
    : 'Your Contributions',
style: const TextStyle(
fontSize: 18,
fontWeight: FontWeight.bold,
),
),

const SizedBox(height: 15),

Row(
children: [
_buildStatBox(
user?.isAdmin == true ? 'Total Reports' : 'Prices',
reportCount.toString(),
Colors.blue,
),

const SizedBox(width: 15),

_buildStatBox(
'Complaints',
complaintCount.toString(),
Colors.red,
),
],
),
],
),
),

const SizedBox(height: 50),

// 6. Logout button.
_buildLogoutButton(context),
],
),
),
);
}

// Header section.
Widget _buildHeader(dynamic user) {
final String? localImagePath = user?.localProfileImagePath;
final String? remoteImageUrl = user?.profileImageUrl;

ImageProvider? profileImage;

// Prefer the locally stored image.
if (localImagePath != null && localImagePath.isNotEmpty) {
final localFile = File(localImagePath);

if (localFile.existsSync()) {
profileImage = FileImage(localFile);
}
}

// Fall back to a remote image if one exists.
if (profileImage == null &&
remoteImageUrl != null &&
remoteImageUrl.isNotEmpty) {
profileImage = NetworkImage(remoteImageUrl);
}

return Container(
width: double.infinity,
padding: const EdgeInsets.symmetric(vertical: 30),
decoration: BoxDecoration(
color: AppColors.primary,
),
child: Column(
children: [
GestureDetector(
onTap: _isChangingPicture ? null : _changeProfilePicture,
child: Stack(
children: [
CircleAvatar(
radius: 45,
backgroundColor: Colors.white,
backgroundImage: profileImage,
child: profileImage == null
? Icon(
IconlyLight.profile,
size: 50,
color: AppColors.primary,
)
    : null,
),

Positioned(
right: 0,
bottom: 0,
child: Container(
padding: const EdgeInsets.all(6),
decoration: const BoxDecoration(
color: Colors.white,
shape: BoxShape.circle,
),
child: _isChangingPicture
? SizedBox(
width: 18,
height: 18,
child: CircularProgressIndicator(
strokeWidth: 2,
color: AppColors.primary,
),
)
    : Icon(
IconlyLight.edit_square,
size: 18,
color: AppColors.primary,
),
),
),
],
),
),

const SizedBox(height: 10),

Text(
user?.name ?? 'User',
style: const TextStyle(
fontSize: 15,
fontWeight: FontWeight.bold,
color: Colors.white,
),
),

Text(
user?.email ?? '',
style: const TextStyle(
color: Colors.white70,
fontSize: 12,
),
),
],
),
);
}

// University and campus information.
Widget _buildInfoCard(dynamic user) {
return Padding(
padding: const EdgeInsets.symmetric(horizontal: 20),
child: Card(
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(12),
),
child: Padding(
padding: const EdgeInsets.all(16),
child: Column(
children: [
_infoRow(
Icons.school,
'University',
user?.university ?? 'N/A',
),

const Divider(),

_infoRow(
Icons.location_on,
'Campus',
user?.campus ?? 'N/A',
),
],
),
),
),
);
}

// Student reports navigation.
Widget _buildMyReportsLink(BuildContext context) {
return Padding(
padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
child: ListTile(
tileColor: Colors.blue.shade50,
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(12),
),
leading: const Icon(
IconlyLight.document,
color: Colors.blue,
),
title: const Text(
'My Reports',
style: TextStyle(
fontWeight: FontWeight.bold,
fontSize: 15,
),
),
subtitle: const Text(
'View your submitted price reports',
style: TextStyle(fontSize: 12),
),
trailing: const Icon(
Icons.arrow_forward_ios,
size: 14,
),
onTap: () {
Navigator.push(
context,
MaterialPageRoute(
builder: (context) => const ReportedItemsScreen(),
),
);
},
),
);
}

// Admin dashboard navigation.
Widget _buildAdminLink(BuildContext context) {
return Padding(
padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
child: ListTile(
tileColor: Colors.blueGrey.shade50,
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(12),
),
leading: const Icon(
IconlyLight.setting,
color: Colors.blueGrey,
),
title: const Text(
'Admin Dashboard',
style: TextStyle(
fontWeight: FontWeight.bold,
fontSize: 15,
),
),
trailing: const Icon(
Icons.arrow_forward_ios,
size: 14,
),
onTap: () {
Navigator.push(
context,
MaterialPageRoute(
builder: (context) => const AdminDashboard(),
),
);
},
),
);
}

// Statistics card.
Widget _buildStatBox(
String title,
String value,
Color color,
) {
return Expanded(
child: Container(
padding: const EdgeInsets.all(20),
decoration: BoxDecoration(
color: color.withOpacity(0.1),
borderRadius: BorderRadius.circular(12),
),
child: Column(
children: [
Text(
value,
style: TextStyle(
fontSize: 22,
fontWeight: FontWeight.bold,
color: color,
),
),

Text(
title,
textAlign: TextAlign.center,
style: TextStyle(
color: color,
fontSize: 11,
),
),
],
),
),
);
}

// Logout button.
Widget _buildLogoutButton(BuildContext context) {
return Padding(
padding: const EdgeInsets.symmetric(horizontal: 20),
child: TextButton.icon(
onPressed: () => _confirmLogout(context),
icon: const Icon(
IconlyLight.logout,
color: Colors.red,
),
label: const Text(
'LOG OUT',
style: TextStyle(
color: Colors.red,
fontWeight: FontWeight.bold,
fontSize: 15,
),
),
),
);
}

// Information row.
Widget _infoRow(
IconData icon,
String label,
String value,
) {
return Row(
children: [
Icon(
icon,
color: Colors.teal,
size: 20,
),

const SizedBox(width: 15),

Expanded(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(
label,
style: const TextStyle(
color: Colors.grey,
fontSize: 11,
),
),

Text(
value,
style: const TextStyle(
fontWeight: FontWeight.w600,
),
),
],
),
),
],
);
}

// Logout confirmation.
Future<void> _confirmLogout(BuildContext context) async {
final shouldLogout = await showDialog<bool>(
context: context,
builder: (dialogContext) {
return AlertDialog(
title: const Text('Log Out'),
content: const Text(
'Are you sure you want to log out?',
),
actions: [
TextButton(
onPressed: () {
Navigator.pop(dialogContext, false);
},
child: const Text('Cancel'),
),

TextButton(
onPressed: () {
Navigator.pop(dialogContext, true);
},
child: const Text(
'Log Out',
style: TextStyle(
color: Colors.teal,
),
),
),
],
);
},
);

if (shouldLogout != true || !context.mounted) return;

try {
await Provider.of<AuthProvider>(
context,
listen: false,
).logout();

if (!context.mounted) return;

Navigator.pushNamedAndRemoveUntil(
context,
'/login',
(route) => false,
);
} catch (e) {
if (!context.mounted) return;

ScaffoldMessenger.of(context).showSnackBar(
SnackBar(
content: Text('Failed to log out: $e'),
backgroundColor: Colors.red,
),
);
}
}
}
