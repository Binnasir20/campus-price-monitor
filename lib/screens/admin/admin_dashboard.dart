import 'package:flutter/material.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Control Panel"),
        backgroundColor: Colors.blueGrey[900],
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: GridView.count(
        padding: const EdgeInsets.all(20),
        crossAxisCount: 2,
        crossAxisSpacing: 15,
        mainAxisSpacing: 15,
        children: [

          // 1. MANAGE SHOPS (General list)
          _buildAdminCard(
            context,
            title: "Manage Shops",
            subtitle: "Edit or Delete",
            icon: Icons.storefront,
            color: Colors.blue,
            onTap: () => Navigator.pushNamed(context, '/manage_shops'),
          ),

          // 3. COMPLAINTS
          _buildAdminCard(
            context,
            title: "Complaints",
            subtitle: "User Reports",
            icon: Icons.report_problem,
            color: Colors.redAccent,
            onTap: () => Navigator.pushNamed(context, '/admin_complaints'),
          ),

          // 4. USERS
          _buildAdminCard(
            context,
            title: "Users",
            subtitle: "Permissions",
            icon: Icons.people,
            color: Colors.teal,
            onTap: () {
              // Future: Navigator.pushNamed(context, '/manage_users');
            },
          ),
        ],
      ),
    );
  }

  // Simplified Card Builder
  Widget _buildAdminCard(BuildContext context,
      {required String title,
        required String subtitle,
        required IconData icon,
        required Color color,
        required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 10),
            Text(title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 4),
            Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          ],
        ),
      ),
    );
  }
}