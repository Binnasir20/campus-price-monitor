import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../model/complaint_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';

class AdminComplaintScreen extends StatefulWidget {
  const AdminComplaintScreen({super.key});

  @override
  State<AdminComplaintScreen> createState() =>
      _AdminComplaintScreenState();
}

class _AdminComplaintScreenState extends State<AdminComplaintScreen> {
  final FirestoreService _firestore = FirestoreService();

  Map<String, String> _userNames = {};
  Map<String, String> _shopNames = {};

  bool _isLoadingNames = true;

  @override
  void initState() {
    super.initState();
    _loadNames();
  }

  Future<void> _loadNames() async {
    try {
      final users = await _firestore.getUserNames();

      final shopsSnapshot = await _firestore
          .getAllShopsForAdmin(
        Provider.of<AuthProvider>(
          context,
          listen: false,
        ).userModel!.university.trim(),
      )
          .first;

      final shops = <String, String>{};

      for (final shop in shopsSnapshot) {
        shops[shop.id] = shop.name;
      }

      if (!mounted) return;

      setState(() {
        _userNames = users;
        _shopNames = shops;
        _isLoadingNames = false;
      });
    } catch (e) {
      print("Error loading complaint names: $e");

      if (!mounted) return;

      setState(() {
        _isLoadingNames = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.userModel;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Student Complaints"),
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<Complaint>>(
        stream: _firestore.getAllComplaintsByUniversity(
          user.university.trim(),
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Error: ${snapshot.error}",
              ),
            );
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

              return _buildComplaintCard(
                context,
                complaint,
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildComplaintCard(
      BuildContext context,
      Complaint complaint,
      ) {
    final shopName =
        _shopNames[complaint.shopId] ?? 'Unknown Shop';

    final userName =
        _userNames[complaint.userId] ?? 'Unknown User';

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: Colors.red.shade50,
          child: const Icon(
            Icons.warning_amber_rounded,
            color: Colors.red,
          ),
        ),
        title: Text(
          complaint.reason,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          DateFormat('MMM d, h:mm a')
              .format(complaint.timestamp),
          style: const TextStyle(fontSize: 12),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(),

                _infoRow(
                  Icons.store,
                  "Shop",
                  shopName,
                ),

                const SizedBox(height: 8),

                _infoRow(
                  Icons.person,
                  "Student",
                  userName,
                ),

                const SizedBox(height: 12),

                const Text(
                  "Detailed Complaint:",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  complaint.details,
                  style: TextStyle(
                    color: Colors.grey[800],
                  ),
                ),

                const SizedBox(height: 20),

                ElevatedButton.icon(
                  onPressed: () => _showDeleteDialog(
                    context,
                    complaint.id,
                  ),
                  icon: const Icon(Icons.check),
                  label: const Text("MARK AS RESOLVED"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(
                      double.infinity,
                      45,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.done_all_rounded,
            size: 80,
            color: Colors.green.withOpacity(0.3),
          ),
          const SizedBox(height: 10),
          const Text(
            "No pending complaints!",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
        ],
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
          size: 16,
          color: Colors.grey,
        ),
        const SizedBox(width: 8),
        Text(
          "$label: ",
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 12,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  void _showDeleteDialog(
      BuildContext context,
      String docId,
      ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Resolve?"),
        content: const Text(
          "This will delete the complaint report permanently.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CANCEL"),
          ),
          TextButton(
            onPressed: () async {
              await _firestore.deleteComplaint(docId);

              if (context.mounted) {
                Navigator.pop(context);
              }
            },
            child: const Text(
              "DELETE",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}