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

class _AdminComplaintScreenState extends State<AdminComplaintScreen>
    with SingleTickerProviderStateMixin {
  final FirestoreService _firestore = FirestoreService();

  late final TabController _tabController;

  Map<String, String> _userNames = {};
  Map<String, String> _shopNames = {};

  bool _isLoadingNames = true;
  String? _namesError;

  final Set<String> _resolvingComplaintIds = {};

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);

    _loadNames();
  }

  void _onTabChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadNames() async {
    try {
      final users = await _firestore.getUserNames();

      if (!mounted) return;

      final auth = Provider.of<AuthProvider>(
        context,
        listen: false,
      );

      final user = auth.userModel;

      if (user == null) {
        setState(() {
          _isLoadingNames = false;
          _namesError = 'Unable to identify the administrator.';
        });
        return;
      }

      final shops = await _firestore
          .getAllShopsForAdmin(user.university.trim())
          .first;

      final shopNames = <String, String>{};

      for (final shop in shops) {
        shopNames[shop.id] = shop.name;
      }

      if (!mounted) return;

      setState(() {
        _userNames = users;
        _shopNames = shopNames;
        _isLoadingNames = false;
        _namesError = null;
      });
    } catch (e, stackTrace) {
      debugPrint('Error loading complaint names: $e');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      setState(() {
        _isLoadingNames = false;
        _namesError = 'Could not load student and shop names.';
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
        title: const Text('Student Complaints'),
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'Resolved'),
          ],
        ),
      ),
      body: StreamBuilder<List<Complaint>>(
        stream: _firestore.getAllComplaintsByUniversity(
          user.university.trim(),
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Could not load complaints.\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final complaints = snapshot.data ?? [];

          final pendingComplaints = complaints
              .where((complaint) => complaint.status != 'resolved')
              .toList();

          final resolvedComplaints = complaints
              .where((complaint) => complaint.status == 'resolved')
              .toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _buildComplaintList(
                pendingComplaints,
                isPending: true,
              ),
              _buildComplaintList(
                resolvedComplaints,
                isPending: false,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildComplaintList(
      List<Complaint> complaints, {
        required bool isPending,
      }) {
    if (_isLoadingNames) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_namesError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _namesError!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isLoadingNames = true;
                    _namesError = null;
                  });
                  _loadNames();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (complaints.isEmpty) {
      return _buildEmptyState(isPending: isPending);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: complaints.length,
      itemBuilder: (context, index) {
        return _buildComplaintCard(complaints[index]);
      },
    );
  }

  Widget _buildComplaintCard(Complaint complaint) {
    final shopName =
        _shopNames[complaint.shopId] ?? 'Unknown Shop';

    final userName =
        _userNames[complaint.userId] ?? 'Unknown User';

    final isResolved = complaint.status == 'resolved';
    final isResolving =
    _resolvingComplaintIds.contains(complaint.id);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor:
          isResolved ? Colors.green.shade50 : Colors.red.shade50,
          child: Icon(
            isResolved
                ? Icons.check_circle_outline
                : Icons.warning_amber_rounded,
            color: isResolved ? Colors.green : Colors.red,
          ),
        ),
        title: Text(
          complaint.reason,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          '${DateFormat('MMM d, h:mm a').format(complaint.timestamp)}'
              ' • ${isResolved ? 'Resolved' : 'Pending'}',
          style: const TextStyle(fontSize: 12),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(),
                _infoRow(Icons.store, 'Shop', shopName),
                const SizedBox(height: 8),
                _infoRow(Icons.person, 'Student', userName),
                const SizedBox(height: 12),
                const Text(
                  'Detailed Complaint:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  complaint.details,
                  style: TextStyle(color: Colors.grey[800]),
                ),
                if (!isResolved) ...[
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: isResolving
                        ? null
                        : () => _showResolveDialog(complaint.id),
                    icon: isResolving
                        ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                        : const Icon(Icons.check_circle_outline),
                    label: Text(
                      isResolving
                          ? 'RESOLVING...'
                          : 'MARK AS RESOLVED',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 45),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({required bool isPending}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isPending
                ? Icons.done_all_rounded
                : Icons.history_rounded,
            size: 80,
            color: Colors.green.withOpacity(0.3),
          ),
          const SizedBox(height: 10),
          Text(
            isPending
                ? 'No pending complaints!'
                : 'No resolved complaints yet.',
            style: const TextStyle(
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
          '$label: ',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 12),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Future<void> _showResolveDialog(String complaintId) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Resolve Complaint?'),
        content: const Text(
          'This will mark the complaint as resolved. '
              'The complaint record will be preserved.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(
              'RESOLVE',
              style: TextStyle(color: Colors.green),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      _resolvingComplaintIds.add(complaintId);
    });

    try {
      await _firestore.resolveComplaint(complaintId);

      if (!mounted) return;

      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Complaint marked as resolved.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e, stackTrace) {
      debugPrint('Error resolving complaint: $e');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Could not resolve complaint: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _resolvingComplaintIds.remove(complaintId);
        });
      }
    }
  }
}