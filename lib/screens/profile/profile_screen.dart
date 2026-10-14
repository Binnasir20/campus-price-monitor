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
import '../complaints/my_complaints_screen.dart';

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

setState(() => _isChangingPicture = true);

try {
final pickedFile = await _picker.pickImage(
source: ImageSource.gallery,
imageQuality: 80,
);

if (!mounted || pickedFile == null) return;

final success = await context.read<AuthProvider>().updateProfilePicture(
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
),
);
} catch (e) {
if (!mounted) return;

ScaffoldMessenger.of(context).showSnackBar(
SnackBar(content: Text('Unable to update picture: $e')),
);
} finally {
if (mounted) {
setState(() => _isChangingPicture = false);
}
}
}

@override
Widget build(BuildContext context) {
final user = context.watch<AuthProvider>().userModel;
final priceProvider = context.watch<PriceProvider>();
final complaintProvider = context.watch<ComplaintProvider>();

final isAdmin = user?.isAdmin == true;

final reportCount = user == null
? 0
    : isAdmin
? priceProvider.priceReports.length
    : priceProvider.myPriceReports.length;

final complaintCount = user == null
? 0
    : isAdmin
? complaintProvider.universityComplaints.length
    : complaintProvider.userComplaints.length;

return Scaffold(
appBar: AppBar(
automaticallyImplyLeading: false,
title: const Text(
'My Profile',
style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
),
backgroundColor: Colors.teal,
foregroundColor: Colors.white,
elevation: 0,
),
body: SingleChildScrollView(
child: Column(
children: [
_buildHeader(user),
const SizedBox(height: 20),
_buildInfoCard(user),

if (user != null && !isAdmin) ...[
_buildNavigationTile(
icon: IconlyLight.document,
title: 'My Reports',
subtitle: 'View your submitted price reports',
color: Colors.blue,
onTap: () {
Navigator.push(
context,
MaterialPageRoute(
builder: (_) => const ReportedItemsScreen(),
),
);
},
),
_buildNavigationTile(
icon: IconlyLight.chat,
title: 'My Complaints',
subtitle: 'View your submitted complaints',
color: Colors.red,
onTap: () {
Navigator.push(
context,
MaterialPageRoute(
builder: (_) => const MyComplaintsScreen(),
),
);
},
),
],

if (isAdmin) _buildAdminLink(context),

const SizedBox(height: 30),

Padding(
padding: const EdgeInsets.symmetric(horizontal: 20),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(
isAdmin ? 'University Overview' : 'Your Contributions',
style: const TextStyle(
fontSize: 18,
fontWeight: FontWeight.bold,
),
),
const SizedBox(height: 15),
Row(
children: [
_buildStatBox(
isAdmin ? 'Total Reports' : 'Price Reports',
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
_buildLogoutButton(context),
const SizedBox(height: 20),
],
),
),
);
}

Widget _buildHeader(dynamic user) {
final String? localPath = user?.localProfileImagePath;
final String? remoteUrl = user?.profileImageUrl;

ImageProvider? image;

if (localPath != null && localPath.isNotEmpty) {
final file = File(localPath);
if (file.existsSync()) image = FileImage(file);
}

if (image == null && remoteUrl != null && remoteUrl.isNotEmpty) {
image = NetworkImage(remoteUrl);
}

return Container(
width: double.infinity,
padding: const EdgeInsets.symmetric(vertical: 30),
color: AppColors.primary,
child: Column(
children: [
GestureDetector(
onTap: _isChangingPicture ? null : _changeProfilePicture,
child: Stack(
children: [
CircleAvatar(
radius: 45,
backgroundColor: Colors.white,
backgroundImage: image,
child: image == null
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
style: const TextStyle(color: Colors.white70, fontSize: 12),
),
],
),
);
}

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

Widget _buildNavigationTile({
required IconData icon,
required String title,
required String subtitle,
required Color color,
required VoidCallback onTap,
}) {
return Padding(
padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
child: ListTile(
tileColor: color.withValues(alpha: 0.08),
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(12),
),
leading: Icon(icon, color: color),
title: Text(
title,
style: const TextStyle(
fontWeight: FontWeight.bold,
fontSize: 15,
),
),
subtitle: Text(
subtitle,
style: const TextStyle(fontSize: 12),
),
trailing: const Icon(Icons.arrow_forward_ios, size: 14),
onTap: onTap,
),
);
}

Widget _buildAdminLink(BuildContext context) {
return _buildNavigationTile(
icon: IconlyLight.setting,
title: 'Admin Dashboard',
subtitle: 'Manage campus activities',
color: Colors.blueGrey,
onTap: () {
Navigator.push(
context,
MaterialPageRoute(
builder: (_) => const AdminDashboard(),
),
);
},
);
}

Widget _buildStatBox(String title, String value, Color color) {
return Expanded(
child: Container(
padding: const EdgeInsets.all(20),
decoration: BoxDecoration(
color: color.withValues(alpha: 0.1),
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
style: TextStyle(color: color, fontSize: 11),
),
],
),
),
);
}

Widget _buildLogoutButton(BuildContext context) {
return Padding(
padding: const EdgeInsets.symmetric(horizontal: 20),
child: TextButton.icon(
onPressed: () => _confirmLogout(context),
icon: const Icon(IconlyLight.logout, color: Colors.red),
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

Widget _infoRow(IconData icon, String label, String value) {
return Row(
children: [
Icon(icon, color: Colors.teal, size: 20),
const SizedBox(width: 15),
Expanded(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(
label,
style: const TextStyle(color: Colors.grey, fontSize: 11),
),
Text(
value,
style: const TextStyle(fontWeight: FontWeight.w600),
),
],
),
),
],
);
}

Future<void> _confirmLogout(BuildContext context) async {
final shouldLogout = await showDialog<bool>(
context: context,
builder: (dialogContext) => AlertDialog(
title: const Text('Log Out'),
content: const Text('Are you sure you want to log out?'),
actions: [
TextButton(
onPressed: () => Navigator.pop(dialogContext, false),
child: const Text('Cancel'),
),
TextButton(
onPressed: () => Navigator.pop(dialogContext, true),
child: const Text(
'Log Out',
style: TextStyle(color: Colors.teal),
),
),
],
),
);

if (shouldLogout != true || !context.mounted) return;

try {
await context.read<AuthProvider>().logout();

if (!context.mounted) return;

Navigator.pushNamedAndRemoveUntil(
context,
'/login',
(route) => false,
);
} catch (e) {
if (!context.mounted) return;

ScaffoldMessenger.of(context).showSnackBar(
SnackBar(content: Text('Failed to log out: $e')),
);
}
}
}
