
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../model/complaint_model.dart';
import '../../model/shop_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/complaint_provider.dart';
import '../../providers/shop_provider.dart';

class MyComplaintsScreen extends StatefulWidget {
const MyComplaintsScreen({super.key});

@override
State<MyComplaintsScreen> createState() => _MyComplaintsScreenState();
}

class _MyComplaintsScreenState extends State<MyComplaintsScreen> {
@override
void initState() {
super.initState();

WidgetsBinding.instance.addPostFrameCallback((_) {
if (!mounted) return;

final user = context.read<AuthProvider>().userModel;

if (user != null) {
context.read<ComplaintProvider>().listenToUserComplaints(user.uid);
}
});
}

String _formatDate(DateTime date) {
final d = date.toLocal();

return '${d.day.toString().padLeft(2, '0')}/'
'${d.month.toString().padLeft(2, '0')}/'
'${d.year} '
'${d.hour.toString().padLeft(2, '0')}:'
'${d.minute.toString().padLeft(2, '0')}';
}

@override
Widget build(BuildContext context) {
final user = context.watch<AuthProvider>().userModel;
final complaintProvider = context.watch<ComplaintProvider>();
final shopProvider = context.watch<ShopProvider>();

final complaints = complaintProvider.userComplaints;

return Scaffold(
appBar: AppBar(
title: const Text('My Complaints'),
backgroundColor: Colors.teal,
foregroundColor: Colors.white,
actions: [
IconButton(
tooltip: 'Refresh',
icon: const Icon(Icons.refresh),
onPressed: user == null
? null
    : () {
complaintProvider.listenToUserComplaints(user.uid);
},
),
],
),
body: user == null
? const Center(
child: Text('Please sign in to continue.'),
)
    : complaintProvider.isLoading && complaints.isEmpty
? const Center(
child: CircularProgressIndicator(),
)
    : complaintProvider.errorMessage != null &&
complaints.isEmpty
? _buildError(
complaintProvider.errorMessage!,
user.uid,
)
    : complaints.isEmpty
? _buildEmptyState()
    : RefreshIndicator(
onRefresh: () async {
complaintProvider.listenToUserComplaints(
user.uid,
);
},
child: ListView.builder(
physics: const AlwaysScrollableScrollPhysics(),
padding: const EdgeInsets.all(16),
itemCount: complaints.length,
itemBuilder: (context, index) {
final complaint = complaints[index];

return _ComplaintCard(
key: ValueKey(complaint.id),
complaint: complaint,
formattedDate:
_formatDate(complaint.timestamp),
shops: shopProvider.shops,
isLoadingShops: shopProvider.isLoading,
);
},
),
),
);
}

Widget _buildError(String message, String userId) {
return Center(
child: Padding(
padding: const EdgeInsets.all(24),
child: Column(
mainAxisSize: MainAxisSize.min,
children: [
const Icon(
Icons.error_outline,
color: Colors.red,
size: 48,
),
const SizedBox(height: 12),
Text(
message,
textAlign: TextAlign.center,
),
const SizedBox(height: 12),
ElevatedButton(
onPressed: () {
context
    .read<ComplaintProvider>()
    .listenToUserComplaints(userId);
},
child: const Text('Try Again'),
),
],
),
),
);
}

Widget _buildEmptyState() {
return const Center(
child: Padding(
padding: EdgeInsets.all(24),
child: Column(
mainAxisSize: MainAxisSize.min,
children: [
Icon(
Icons.report_problem_outlined,
size: 60,
color: Colors.grey,
),
SizedBox(height: 12),
Text(
'No Complaints Yet',
style: TextStyle(
fontSize: 18,
fontWeight: FontWeight.bold,
),
),
SizedBox(height: 8),
Text(
'Complaints you submit will appear here.',
textAlign: TextAlign.center,
),
],
),
),
);
}
}

class _ComplaintCard extends StatelessWidget {
final Complaint complaint;
final String formattedDate;
final List<Shop> shops;
final bool isLoadingShops;

const _ComplaintCard({
super.key,
required this.complaint,
required this.formattedDate,
required this.shops,
required this.isLoadingShops,
});

String _getShopName() {
if (complaint.shopId.isEmpty) {
return 'Unknown Shop';
}

for (final shop in shops) {
if (shop.id == complaint.shopId) {
return shop.name;
}
}

if (isLoadingShops) {
return 'Loading shop...';
}

return 'Shop not found';
}

String _formatStatus(String status) {
if (status.trim().isEmpty) {
return 'Submitted';
}

return status
    .replaceAll('_', ' ')
    .split(' ')
    .map(
(word) => word.isEmpty
? word
    : '${word[0].toUpperCase()}'
'${word.substring(1).toLowerCase()}',
)
    .join(' ');
}

Color _statusColor(String status) {
switch (status.toLowerCase()) {
case 'resolved':
case 'approved':
case 'closed':
return Colors.green;

case 'rejected':
case 'dismissed':
return Colors.red;

case 'under_review':
case 'in_progress':
return Colors.blue;

default:
return Colors.orange;
}
}

@override
Widget build(BuildContext context) {
final color = _statusColor(complaint.status);
final shopName = _getShopName();

return Card(
margin: const EdgeInsets.only(bottom: 16),
child: Padding(
padding: const EdgeInsets.all(16),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Row(
children: [
const Icon(
Icons.report_problem_outlined,
color: Colors.teal,
),
const SizedBox(width: 10),
Expanded(
child: Text(
complaint.reason,
style: const TextStyle(
fontSize: 16,
fontWeight: FontWeight.bold,
),
),
),
const SizedBox(width: 8),
Container(
padding: const EdgeInsets.symmetric(
horizontal: 10,
vertical: 5,
),
decoration: BoxDecoration(
color: color.withValues(alpha: 0.12),
borderRadius: BorderRadius.circular(20),
),
child: Text(
_formatStatus(complaint.status),
style: TextStyle(
color: color,
fontSize: 12,
fontWeight: FontWeight.bold,
),
),
),
],
),
const SizedBox(height: 12),
Row(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
const Text(
'Shop: ',
style: TextStyle(
fontWeight: FontWeight.w600,
),
),
Expanded(
child: Text(
shopName,
style: TextStyle(
color: shopName == 'Shop not found'
? Colors.grey
    : null,
),
),
),
],
),
const SizedBox(height: 8),
Text(complaint.details),
const SizedBox(height: 12),
Row(
children: [
const Icon(
Icons.access_time,
size: 16,
color: Colors.grey,
),
const SizedBox(width: 6),
Text(
formattedDate,
style: const TextStyle(
color: Colors.grey,
fontSize: 12,
),
),
],
),
],
),
),
);
}
}
