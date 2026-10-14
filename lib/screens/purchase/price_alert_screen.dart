import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../model/price_alert_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/purchase_provider.dart';

class PriceAlertScreen extends StatefulWidget {
const PriceAlertScreen({super.key});

@override
State<PriceAlertScreen> createState() => _PriceAlertScreenState();
}

class _PriceAlertScreenState extends State<PriceAlertScreen> {
@override
void initState() {
super.initState();

WidgetsBinding.instance.addPostFrameCallback((_) {
if (mounted) _loadAlerts();
});
}

Future<void> _loadAlerts() async {
final user = context.read<AuthProvider>().userModel;

if (user == null || user.university.trim().isEmpty) return;

await context.read<PurchaseProvider>().fetchPriceAlerts(
university: user.university,
studentId: user.uid,
isAdmin: user.isAdmin == true,
);
}

String _formatDate(DateTime date) {
final d = date.toLocal();

return '${d.day.toString().padLeft(2, '0')}/'
'${d.month.toString().padLeft(2, '0')}/'
'${d.year} '
'${d.hour.toString().padLeft(2, '0')}:'
'${d.minute.toString().padLeft(2, '0')}';
}

String _formatCurrency(double amount) {
return '₦${amount.toStringAsFixed(2)}';
}

String _formatStatus(String status) {
switch (status.toLowerCase()) {
case 'pending':
return 'Pending';
case 'under_review':
return 'Under Review';
case 'confirmed':
return 'Confirmed';
case 'dismissed':
return 'Dismissed';
case 'resolved':
return 'Resolved';
default:
return status;
}
}

Color _statusColor(String status) {
switch (status.toLowerCase()) {
case 'pending':
return Colors.orange;
case 'under_review':
return Colors.blue;
case 'confirmed':
return Colors.red;
case 'dismissed':
return Colors.grey;
case 'resolved':
return Colors.green;
default:
return Colors.blueGrey;
}
}

void _showMessage(String message) {
if (!mounted) return;

ScaffoldMessenger.of(context).showSnackBar(
SnackBar(content: Text(message)),
);
}

Future<void> _reviewAlert(
PriceAlert alert,
String status,
) async {
final user = context.read<AuthProvider>().userModel;

if (user == null || user.isAdmin != true) {
_showMessage('Only administrators can review price alerts.');
return;
}

final noteController = TextEditingController();

final confirmed = await showDialog<bool>(
context: context,
builder: (dialogContext) => AlertDialog(
title: Text(_formatStatus(status)),
content: Column(
mainAxisSize: MainAxisSize.min,
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(
'Update the alert for ${alert.itemName} at ${alert.shopName}?',
),
const SizedBox(height: 12),
TextField(
controller: noteController,
maxLines: 3,
decoration: const InputDecoration(
labelText: 'Review note (optional)',
border: OutlineInputBorder(),
),
),
],
),
actions: [
TextButton(
onPressed: () => Navigator.pop(dialogContext, false),
child: const Text('Cancel'),
),
ElevatedButton(
onPressed: () => Navigator.pop(dialogContext, true),
child: const Text('Update'),
),
],
),
);

if (confirmed != true) {
noteController.dispose();
return;
}

if (!mounted) {
noteController.dispose();
return;
}

final provider = context.read<PurchaseProvider>();

final success = await provider.reviewPriceAlert(
alertId: alert.id,
status: status,
reviewedBy: user.uid,
reviewNote: noteController.text.trim(),
);

noteController.dispose();

if (!mounted) return;

_showMessage(
success
? 'Alert updated successfully.'
    : provider.errorMessage ?? 'Could not update the alert.',
);
}

@override
Widget build(BuildContext context) {
final user = context.watch<AuthProvider>().userModel;
final provider = context.watch<PurchaseProvider>();

final alerts = provider.priceAlerts;
final isAdmin = user?.isAdmin == true;

return Scaffold(
appBar: AppBar(
title: const Text('Price Alerts'),
actions: [
IconButton(
tooltip: 'Refresh alerts',
onPressed: _loadAlerts,
icon: const Icon(Icons.refresh),
),
],
),
body: user == null
? const Center(
child: Text('Please sign in to view price alerts.'),
)
    : user.university.trim().isEmpty
? const Center(
child: Text(
'Your university is not set in your profile.',
textAlign: TextAlign.center,
),
)
    : provider.isLoading && alerts.isEmpty
? const Center(child: CircularProgressIndicator())
    : provider.errorMessage != null && alerts.isEmpty
? _buildErrorState(provider.errorMessage!)
    : alerts.isEmpty
? _buildEmptyState()
    : RefreshIndicator(
onRefresh: _loadAlerts,
child: ListView.builder(
physics:
const AlwaysScrollableScrollPhysics(),
padding: const EdgeInsets.all(16),
itemCount: alerts.length,
itemBuilder: (context, index) {
final alert = alerts[index];

return _PriceAlertCard(
alert: alert,
formattedDate:
_formatDate(alert.createdAt),
formattedCurrency: _formatCurrency,
formattedStatus: _formatStatus,
statusColor: _statusColor,
isAdmin: isAdmin,
onReview: (status) =>
_reviewAlert(alert, status),
);
},
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
Icons.price_check_outlined,
size: 64,
color: Colors.grey,
),
SizedBox(height: 12),
Text(
'No price alerts',
style: TextStyle(
fontSize: 18,
fontWeight: FontWeight.bold,
),
),
SizedBox(height: 8),
Text(
'Alerts will appear here when unusual purchase '
'prices are detected.',
textAlign: TextAlign.center,
),
],
),
),
);
}

Widget _buildErrorState(String message) {
return Center(
child: Padding(
padding: const EdgeInsets.all(24),
child: Column(
mainAxisSize: MainAxisSize.min,
children: [
const Icon(
Icons.error_outline,
size: 48,
color: Colors.red,
),
const SizedBox(height: 12),
Text(message, textAlign: TextAlign.center),
const SizedBox(height: 12),
ElevatedButton(
onPressed: _loadAlerts,
child: const Text('Try again'),
),
],
),
),
);
}
}

class _PriceAlertCard extends StatelessWidget {
final PriceAlert alert;
final String formattedDate;
final String Function(double) formattedCurrency;
final String Function(String) formattedStatus;
final Color Function(String) statusColor;
final bool isAdmin;
final ValueChanged<String> onReview;

const _PriceAlertCard({
required this.alert,
required this.formattedDate,
required this.formattedCurrency,
required this.formattedStatus,
required this.statusColor,
required this.isAdmin,
required this.onReview,
});

@override
Widget build(BuildContext context) {
final color = statusColor(alert.status);

final isClosed =
alert.status == 'dismissed' || alert.status == 'resolved';

return Card(
margin: const EdgeInsets.only(bottom: 16),
clipBehavior: Clip.antiAlias,
child: Padding(
padding: const EdgeInsets.all(16),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Row(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
CircleAvatar(
backgroundColor: color.withValues(alpha: 0.12),
child: Icon(
Icons.warning_amber_rounded,
color: color,
),
),
const SizedBox(width: 12),
Expanded(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(
alert.itemName,
style: Theme.of(context)
    .textTheme
    .titleMedium
    ?.copyWith(fontWeight: FontWeight.bold),
),
const SizedBox(height: 4),
Text('Shop: ${alert.shopName}'),
],
),
),
const SizedBox(width: 8),
Container(
padding: const EdgeInsets.symmetric(
horizontal: 10,
vertical: 6,
),
decoration: BoxDecoration(
color: color.withValues(alpha: 0.12),
borderRadius: BorderRadius.circular(20),
),
child: Text(
formattedStatus(alert.status),
style: TextStyle(
color: color,
fontSize: 12,
fontWeight: FontWeight.bold,
),
),
),
],
),
const SizedBox(height: 20),
_AlertDetailRow(
label: 'Recorded price',
value: formattedCurrency(alert.observedPrice),
),
_AlertDetailRow(
label: 'Comparison average',
value: formattedCurrency(alert.comparisonPrice),
),
_AlertDetailRow(
label: 'Price difference',
value:
'${alert.differencePercentage.toStringAsFixed(1)}% higher',
isBold: true,
),
_AlertDetailRow(
label: 'Other shops compared',
value: '${alert.comparisonCount}',
),
_AlertDetailRow(
label: 'Date reported',
value: formattedDate,
),
const SizedBox(height: 12),
Container(
width: double.infinity,
padding: const EdgeInsets.all(12),
decoration: BoxDecoration(
color: Theme.of(context)
    .colorScheme
    .surfaceContainerHighest,
borderRadius: BorderRadius.circular(8),
),
child: Text(alert.reason),
),
if (alert.reviewNote?.trim().isNotEmpty == true) ...[
const SizedBox(height: 12),
Text('Review note: ${alert.reviewNote}'),
],
if (isAdmin && !isClosed) ...[
const Divider(height: 28),
const Text(
'Admin actions',
style: TextStyle(fontWeight: FontWeight.bold),
),
const SizedBox(height: 8),
Wrap(
spacing: 8,
runSpacing: 8,
children: [
OutlinedButton(
onPressed: () => onReview('under_review'),
child: const Text('Review'),
),
ElevatedButton(
onPressed: () => onReview('confirmed'),
child: const Text('Confirm'),
),
OutlinedButton(
onPressed: () => onReview('dismissed'),
child: const Text('Dismiss'),
),
OutlinedButton(
onPressed: () => onReview('resolved'),
child: const Text('Resolve'),
),
],
),
],
],
),
),
);
}
}

class _AlertDetailRow extends StatelessWidget {
final String label;
final String value;
final bool isBold;

const _AlertDetailRow({
required this.label,
required this.value,
this.isBold = false,
});

@override
Widget build(BuildContext context) {
return Padding(
padding: const EdgeInsets.symmetric(vertical: 5),
child: Row(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Expanded(child: Text(label)),
const SizedBox(width: 12),
Flexible(
child: Text(
value,
textAlign: TextAlign.end,
style: TextStyle(
fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
),
),
),
],
),
);
}
}
