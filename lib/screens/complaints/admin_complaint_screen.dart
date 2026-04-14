import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../model/complaint_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';

class AdminComplaintScreen extends StatelessWidget {
  const AdminComplaintScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. Listen to AuthProvider
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.userModel;

    // 2. Safety Check: If user isn't loaded yet, show loading
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final firestore = FirestoreService();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Student Complaints"),
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<Complaint>>(
        // 3. .trim() ensures we match the database correctly
        stream: firestore.getAllComplaintsByUniversity(user.university.trim()),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          final complaints = snapshot.data ?? [];

          if (complaints.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: complaints.length,
            itemBuilder: (context, index) {
              final complaint = complaints[index];
              return _buildComplaintCard(context, complaint);
            },
          );
        },
      ),
    );
  }

  // --- UI COMPONENTS ---

  Widget _buildComplaintCard(BuildContext context, Complaint complaint) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: Colors.red, // Light red
          child: const Icon(Icons.warning_amber_rounded, color: Colors.red),
        ),
        title: Text(
          complaint.reason,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          DateFormat('MMM d, h:mm a').format(complaint.timestamp),
          style: const TextStyle(fontSize: 12),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(),
                _infoRow(Icons.store, "Shop ID", complaint.shopId),
                const SizedBox(height: 8),
                _infoRow(Icons.person, "User ID", complaint.userId),
                const SizedBox(height: 12),
                const Text("Detailed Complaint:",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 5),
                Text(complaint.details, style: TextStyle(color: Colors.grey[800])),
                const SizedBox(height: 20),

                // ACTION BUTTON
                ElevatedButton.icon(
                  onPressed: () => _showDeleteDialog(context, complaint.id),
                  icon: const Icon(Icons.check),
                  label: const Text("MARK AS RESOLVED"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 45),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.done_all_rounded, size: 80, color: Colors.green.withOpacity(0.3)),
          const SizedBox(height: 10),
          const Text("No pending complaints!",
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 8),
        Text("$label: ", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis)),
      ],
    );
  }

  void _showDeleteDialog(BuildContext context, String docId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Resolve?"),
        content: const Text("This will delete the complaint report permanently."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL")),
          TextButton(
            onPressed: () async {
              await FirestoreService().deleteComplaint(docId);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text("DELETE", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}