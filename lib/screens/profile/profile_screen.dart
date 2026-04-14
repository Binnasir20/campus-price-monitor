import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/price_provider.dart';
import '../../providers/complaint_provider.dart';
import '../admin/admin_dashboard.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

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
        // ADMIN: Sees the total count for the university
        reportCount = priceProv.prices.length;
        complaintCount = complaintProv.userComplaints.length;
      } else {
        // STUDENT: Sees only their personal counts
        reportCount = priceProv.prices.where((p) => p.reportedBy == user.uid).length;
        complaintCount = complaintProv.userComplaints.where((c) => c.userId == user.uid).length;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Profile"),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. HEADER SECTION (User Info)
            _buildHeader(user),

            const SizedBox(height: 20),

            // 2. CAMPUS INFO
            _buildInfoCard(user),

            // 3. ADMIN DASHBOARD BUTTON (Only for Admin)
            if (user?.isAdmin == true) _buildAdminLink(context),

            const SizedBox(height: 30),

            // 4. STATISTICS SECTION
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user?.isAdmin == true ? "University Overview" : "Your Contributions",
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      _buildStatBox("Prices", reportCount.toString(), Colors.blue),
                      const SizedBox(width: 15),
                      _buildStatBox("Complaints", complaintCount.toString(), Colors.red),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 50),

            // 5. LOGOUT BUTTON
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
      decoration: const BoxDecoration(color: Colors.green),
      child: Column(
        children: [
          const CircleAvatar(
            radius: 45,
            backgroundColor: Colors.white,
            child: Icon(Icons.person, size: 50, color: Colors.green),
          ),
          const SizedBox(height: 10),
          Text(
            user?.name ?? "User",
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          Text(user?.email ?? "", style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }

  Widget _buildInfoCard(user) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _infoRow(Icons.school, "University", user?.university ?? "N/A"),
              const Divider(),
              _infoRow(Icons.location_on, "Campus", user?.campus ?? "N/A"),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdminLink(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: ListTile(
        tileColor: Colors.blueGrey.shade50,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: const Icon(Icons.dashboard_customize, color: Colors.blueGrey),
        title: const Text("Admin Dashboard", style: TextStyle(fontWeight: FontWeight.bold)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminDashboard())),
      ),
    );
  }

  Widget _buildStatBox(String title, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
            Text(title, style: TextStyle(color: color, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: TextButton.icon(
        onPressed: () async {
          await Provider.of<AuthProvider>(context, listen: false).logout();
          if (context.mounted) {
            Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
          }
        },
        icon: const Icon(Icons.logout, color: Colors.red),
        label: const Text("LOG OUT", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.green, size: 20),
        const SizedBox(width: 15),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ],
    );
  }
}