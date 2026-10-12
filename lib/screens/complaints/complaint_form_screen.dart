
import 'package:campus_price_monitor/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../model/complaint_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/shop_provider.dart';
import '../../providers/complaint_provider.dart';

class ComplaintFormScreen extends StatefulWidget {
final String? initialShopId;

const ComplaintFormScreen({
super.key,
this.initialShopId,
});

@override
State<ComplaintFormScreen> createState() =>
_ComplaintFormScreenState();
}

class _ComplaintFormScreenState extends State<ComplaintFormScreen> {
final _formKey = GlobalKey<FormState>();
final _detailsController = TextEditingController();

final stt.SpeechToText _speech = stt.SpeechToText();

String? _selectedShopId;
String? _selectedReason;

bool _isListening = false;
bool _isSpeechAvailable = false;
bool _isInitializingSpeech = false;
bool _isSubmitting = false;

final List<String> _reasons = [
'Overpricing',
'Poor Quality',
"Shop doesn't exist",
'Inaccurate Information',
'Other',
];

@override
void initState() {
super.initState();
_selectedShopId = widget.initialShopId;
}

@override
void dispose() {
_speech.stop();
_detailsController.dispose();
super.dispose();
}

Future<void> _startListening() async {
if (_isListening || _isInitializingSpeech) return;

setState(() {
_isInitializingSpeech = true;
});

try {
final available = await _speech.initialize(
onStatus: (status) {
if (!mounted) return;

if (status == 'done' || status == 'notListening') {
setState(() {
_isListening = false;
});
}
},
onError: (error) {
if (!mounted) return;

setState(() {
_isListening = false;
});

ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(
content: Text('Could not recognize speech.'),
backgroundColor: Colors.red,
),
);
},
);

if (!mounted) return;

_isSpeechAvailable = available;

if (!available) {
ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(
content: Text(
'Speech recognition is not available.',
),
backgroundColor: Colors.red,
),
);
return;
}

setState(() {
_isListening = true;
});

await _speech.listen(
onResult: (result) {
if (!mounted) return;

setState(() {
_detailsController.value = TextEditingValue(
text: result.recognizedWords,
selection: TextSelection.collapsed(
offset: result.recognizedWords.length,
),
);
});
},
);
} catch (e) {
if (!mounted) return;

setState(() {
_isListening = false;
});

ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(
content: Text('Unable to start the microphone.'),
backgroundColor: Colors.red,
),
);
} finally {
if (mounted) {
setState(() {
_isInitializingSpeech = false;
});
}
}
}

Future<void> _stopListening() async {
if (!_isListening) return;

await _speech.stop();

if (!mounted) return;

setState(() {
_isListening = false;
});
}

Future<void> _submitComplaint() async {
if (_isSubmitting) return;

if (_isListening) {
await _stopListening();
}

if (!_formKey.currentState!.validate()) return;

final user = Provider.of<AuthProvider>(
context,
listen: false,
).userModel;

final complaintProvider = Provider.of<ComplaintProvider>(
context,
listen: false,
);

if (user == null) return;

setState(() {
_isSubmitting = true;
});

try {
final newComplaint = Complaint(
id: '',
userId: user.uid,
shopId: _selectedShopId!,
university: user.university,
reason: _selectedReason!,
details: _detailsController.text.trim(),
timestamp: DateTime.now(),
);

final success =
await complaintProvider.sendComplaint(newComplaint);

if (!mounted) return;

ScaffoldMessenger.of(context).showSnackBar(
SnackBar(
content: Text(
success
? 'Reported successfully!'
    : 'Failed to report.',
),
backgroundColor: success ? Colors.green : Colors.red,
),
);

if (success) {
Navigator.pop(context);
}
} catch (e) {
if (!mounted) return;

ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(
content: Text('An error occurred while submitting.'),
backgroundColor: Colors.red,
),
);
} finally {
if (mounted) {
setState(() {
_isSubmitting = false;
});
}
}
}

@override
Widget build(BuildContext context) {
final shops = Provider.of<ShopProvider>(context).shops;

return Scaffold(
  backgroundColor: AppColors.background,
appBar: AppBar(
  leading: IconButton(onPressed: (){
    Navigator.pop(context);
  },
      icon: Icon(IconlyLight.arrow_left,
     color: AppColors.textPrimary,)),
  backgroundColor: AppColors.background,
title: const Text('Report an Issue',style: TextStyle(
  color: AppColors.textPrimary
),),

foregroundColor: Colors.white,
),
body: SingleChildScrollView(
padding: const EdgeInsets.all(24),
child: Form(
key: _formKey,
child: Column(
children: [
// Shop dropdown.
DropdownButtonFormField<String>(
value: _selectedShopId,
decoration: _inputStyle(
'Select Shop', IconlyLight.buy,
),
items: shops
    .map(
(shop) => DropdownMenuItem<String>(
value: shop.id,
child: Text(shop.name),
),
)
    .toList(),
onChanged: (value) {
setState(() {
_selectedShopId = value;
});
},
validator: (value) =>
value == null ? 'Select a shop' : null,
),

const SizedBox(height: 20),

// Issue type dropdown.
DropdownButtonFormField<String>(
value: _selectedReason,
decoration: _inputStyle(
'Issue Type',
IconlyLight.danger,
),
items: _reasons
    .map(
(reason) => DropdownMenuItem<String>(
value: reason,
child: Text(reason),
),
)
    .toList(),
onChanged: (value) {
setState(() {
_selectedReason = value;
});
},
validator: (value) =>
value == null ? 'Select a reason' : null,
),

const SizedBox(height: 20),

// Complaint details.
TextFormField(
controller: _detailsController,
maxLines: 4,
decoration: _inputStyle(
'Details',
IconlyLight.chat,
).copyWith(
suffixIcon: IconButton(
onPressed: _isListening
? _stopListening
    : _startListening,
tooltip: _isListening
? 'Stop recording'
    : 'Start recording',
icon: Icon(
_isListening ? Icons.stop_circle : IconlyLight.voice,
color: _isListening ? Colors.red : null,
),
),
),
validator: (value) =>
value == null || value.trim().isEmpty
? 'Please explain the issue'
    : null,
),

const SizedBox(height: 12),

// Dedicated microphone controls.
Row(
children: [
Expanded(
child: GestureDetector(
onLongPressStart: (_) {
_startListening();
},
onLongPressEnd: (_) {
_stopListening();
},
child: ElevatedButton.icon(
onPressed: _isListening ||
_isInitializingSpeech
? null
    : _startListening,
icon: const Icon(IconlyLight.voice),
label: const Text('Hold to Speak'),
style: ElevatedButton.styleFrom(
backgroundColor: AppColors.primary,
foregroundColor: Colors.white,
padding: const EdgeInsets.symmetric(
vertical: 14,
),
),
),
),
),
const SizedBox(width: 10),
Expanded(
child: ElevatedButton.icon(
onPressed: _isListening
? _stopListening
    : null,
icon: const Icon(Icons.stop),
label: const Text('Stop'),
style: ElevatedButton.styleFrom(
backgroundColor: Colors.grey.shade700,
foregroundColor: Colors.white,
padding: const EdgeInsets.symmetric(
vertical: 14,
),
),
),
),
],
),

const SizedBox(height: 8),

Text(
_isListening
? 'Listening... Speak clearly.'
    : _isInitializingSpeech
? 'Starting microphone...'
    : 'Tap the microphone to speak, or hold '
'the button while speaking.',
textAlign: TextAlign.center,
style: TextStyle(
color: _isListening
? Colors.red
    : Colors.grey.shade700,
fontSize: 12,
),
),

const SizedBox(height: 40),

// Submit complaint.
Consumer<ComplaintProvider>(
builder: (context, provider, _) {
return ElevatedButton(
style: ElevatedButton.styleFrom(
minimumSize: const Size.fromHeight(60),
backgroundColor: AppColors.primary,
foregroundColor: Colors.white,
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(12),
),
),
onPressed: provider.isLoading || _isSubmitting
? null
    : _submitComplaint,
child: provider.isLoading || _isSubmitting
? const CircularProgressIndicator(
color: Colors.white,
)
    : const Text(
'SUBMIT REPORT',
style: TextStyle(
fontWeight: FontWeight.bold,
),
),
);
},
),
],
),
),
),
);
}

InputDecoration _inputStyle(
String label,
IconData icon,
) {
return InputDecoration(
labelText: label,
prefixIcon: Icon(icon,size: 20,),
border: OutlineInputBorder(
borderRadius: BorderRadius.circular(12),
  borderSide: BorderSide(
      color: AppColors.primary
  )
),
  focusColor: AppColors.primary,
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(
      color: AppColors.primary
    )
  )
);
}
}