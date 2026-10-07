import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'package:provider/provider.dart';

import '../../constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/price_provider.dart';
import '../../providers/complaint_provider.dart';
import '../admin/admin_dashboard.dart';
import '../reported_screen/reported_item_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).userModel;
    final priceProv = Provider.of<PriceProvider>(context);
    print("PROFILE REPORT COUNT: ${priceProv.myPriceReports.length}");
    final complaintProv = Provider.of<ComplaintProvider>(context);

    // --- STATISTICS LOGIC ---
    int reportCount = 0;
    int complaintCount = 0;

    if (user != null) {
      if (user.isAdmin) {
        // ADMIN: Sees the total official prices
        reportCount = priceProv.priceReports.length;
        complaintCount = complaintProv.userComplaints.length;
      } else {
        // STUDENT: Sees only their own submitted price reports
        reportCount = priceProv.myPriceReports.length;

        complaintCount = complaintProv.userComplaints
            .where((c) => c.userId == user.uid)
            .length;
      }
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text("My Profile",style: TextStyle(
              fontSize: 15,
              fontWeight:
                FontWeight.bold,
            ),),
        backgroundColor:  Color(AppColors.bgColor),
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
        color:  Color(AppColors.bgColor),
      ),
      child: Column(
        children: [
           CircleAvatar(
            radius: 45,
            backgroundColor: Colors.white,
            child: Icon(
              IconlyLight.profile,
              size: 50,
              color: Color(AppColors.bgColor),
            ),
          ),

          const SizedBox(height: 10),

          Text(
            user?.name ?? "User",
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),

          Text(
            user?.email ?? "",
            style: const TextStyle(
              color: Colors.white70,
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
          ),
        ),
        subtitle: const Text(
          "View your submitted price reports",
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
          Icons.dashboard_customize,
          color: Colors.blueGrey,
        ),
        title: const Text(
          "Admin Dashboard",
          style: TextStyle(
            fontWeight: FontWeight.bold,
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
                fontSize: 13,
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
          color:  Color(AppColors.bgColor),
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
              color: Colors.orange
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