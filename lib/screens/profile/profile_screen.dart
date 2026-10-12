import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

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

  Future<void> _changeProfilePicture() async {
    final pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

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
              ? "Profile picture updated."
              : "Failed to update profile picture.",
        ),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).userModel;
    final priceProv = Provider.of<PriceProvider>(context);
    final complaintProv = Provider.of<ComplaintProvider>(context);

    // --- STATISTICS LOGIC ---
    int reportCount = 0;
    int complaintCount = 0;

    if (user != null) {
      if (user.isAdmin) {
        // Admin sees university-wide statistics.
        reportCount = priceProv.priceReports.length;
        complaintCount = complaintProv.universityComplaints.length;
      } else {
        // Student sees their own contributions.
        reportCount = priceProv.myPriceReports.length;
        complaintCount = complaintProv.userComplaints.length;
      }
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text("My Profile",style: TextStyle(
              fontSize: 17,
              fontWeight:
                FontWeight.bold,
            ),),
          backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. HEADER SECTION
            _buildHeader(user),

            const SizedBox(height: 20),

            // 2. CAMPUS INFO
            _buildInfoCard(user),

            // 3. MY REPORTS
            if (user != null && !user.isAdmin)
              _buildMyReportsLink(context),

            // 4. ADMIN DASHBOARD
            if (user?.isAdmin == true) _buildAdminLink(context),

            const SizedBox(height: 30),

            // 5. STATISTICS SECTION
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user?.isAdmin == true
                        ? "University Overview"
                        : "Your Contributions",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 15),

                  Row(
                    children: [
                      _buildStatBox(
                        user?.isAdmin == true ? "Total Report" : "Prices",
                        reportCount.toString(),
                        Colors.blue,
                      ),

                      const SizedBox(width: 15),

                      _buildStatBox(
                        "Complaints",
                        complaintCount.toString(),
                        Colors.red,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 50),

            // 6. LOGOUT BUTTON
            _buildLogoutButton(context),
          ],
        ),
      ),
    );
  }

  // --- UI WIDGET HELPERS ---
  Widget _buildHeader(user) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 30),
      decoration: BoxDecoration(
        color:   AppColors.primary,
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: _changeProfilePicture,
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 45,
                  backgroundColor: Colors.white,
                  backgroundImage: user?.profileImageUrl != null &&
                      user!.profileImageUrl!.isNotEmpty
                      ? NetworkImage(user.profileImageUrl!)
                      : null,
                  child: user?.profileImageUrl == null ||
                      user!.profileImageUrl!.isEmpty
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
                    child:  Icon(
                      IconlyLight.edit_square,
                      size: 18,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          //  CircleAvatar(
          //   radius: 45,
          //   backgroundColor: Colors.white,
          //   child: Icon(
          //     IconlyLight.profile,
          //     size: 50,
          //     color:  Colors.teal,
          //   ),
          // ),

          const SizedBox(height: 10),

          Text(
            user?.name ?? "User",
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),

          Text(
            user?.email ?? "",
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(user) {
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
                "University",
                user?.university ?? "N/A",
              ),

              const Divider(),

              _infoRow(
                Icons.location_on,
                "Campus",
                user?.campus ?? "N/A",
              ),
            ],
          ),
        ),
      ),
    );
  }

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
          "My Reports",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15
          ),
        ),
        subtitle: const Text(
          "View your submitted price reports",
          style: TextStyle(
            fontSize: 12
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
              builder: (context) => const ReportedItemsScreen(),
            ),
          );
        },
      ),
    );
  }

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
          "Admin Dashboard",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 14,
        ),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const AdminDashboard(),
          ),
        ),
      ),
    );
  }

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
          "LOG OUT",
          style: TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.bold,
            fontSize: 15
          ),
        ),
      ),
    );
  }

  Widget _infoRow(
      IconData icon,
      String label,
      String value,
      ) {
    return Row(
      children: [
        Icon(
          icon,
          color:  Colors.teal,
          size: 20,
        ),

        const SizedBox(width: 15),

        Column(
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
      ],
    );
  }
}
Future<void> _confirmLogout(BuildContext context) async {
  final shouldLogout = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text("Log Out"),
        content: const Text(
          "Are you sure you want to log out?",
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context, false);
            },
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context, true);
            },
            child: const Text("Log Out",style: TextStyle(
              color: Colors.teal
            ),),
          ),
        ],
      );
    },
  );

  if (shouldLogout == true) {
    await Provider.of<AuthProvider>(
      context,
      listen: false,
    ).logout();

    if (context.mounted) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/login',
            (route) => false,
      );
    }
  }
}