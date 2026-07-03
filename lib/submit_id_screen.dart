import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const kGreen = Color(0xFF1B6B3A);
const kGreenLight = Color(0xFFE8F5EE);
const kBg = Color(0xFFF4F6F8);
const kGrey = Color(0xFF9E9E9E);

class SubmitIDScreen extends StatefulWidget {
  const SubmitIDScreen({super.key});

  @override
  State<SubmitIDScreen> createState() => _SubmitIDScreenState();
}

class _SubmitIDScreenState extends State<SubmitIDScreen> {
  final _supabase = Supabase.instance.client;

  int _step = 0;
  String _docType = 'ghana';

  final _nameCtrl = TextEditingController();
  final _idCtrl = TextEditingController();
  final _dobCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _institutionCtrl = TextEditingController();

  // Store images as bytes — works on both web and mobile
  Uint8List? _frontBytes;
  Uint8List? _backBytes;
  Uint8List? _selfieBytes;

  bool _submitting = false;
  String _uploadStatus = '';

  @override
  void dispose() {
    _nameCtrl.dispose();
    _idCtrl.dispose();
    _dobCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _institutionCtrl.dispose();
    super.dispose();
  }

  void _next() => setState(() => _step++);
  void _back() => setState(() => _step--);

  // ── Pick image → store as bytes (web + mobile) ──
  Future<Uint8List?> _pickImageBytes() async {
    ImageSource? source;

    if (kIsWeb) {
      // On web, only gallery is supported
      source = ImageSource.gallery;
    } else {
      // On mobile, show camera/gallery choice
      source = await showModalBottomSheet<ImageSource>(
        context: context,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
        builder: (_) => SafeArea(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const SizedBox(height: 8),
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded, color: kGreen),
              title: const Text('Take Photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded, color: kGreen),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ]),
        ),
      );
    }

    if (source == null) return null;

    final picked =
        await ImagePicker().pickImage(source: source, imageQuality: 85);
    if (picked == null) return null;
    return await picked.readAsBytes();
  }

  // ── Upload bytes to Supabase Storage ──
  Future<String> _uploadBytes(Uint8List bytes, String path) async {
    final filePath = 'submissions/$path';
    await _supabase.storage.from('submissions').uploadBinary(
          filePath,
          bytes,
          fileOptions:
              const FileOptions(contentType: 'image/jpeg', upsert: true),
        );
    return _supabase.storage.from('submissions').getPublicUrl(filePath);
  }

  // ── Submit ──
  Future<void> _submit() async {
    setState(() {
      _submitting = true;
      _uploadStatus = 'Preparing...';
    });
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw 'Not logged in';

      final uid = user.id;
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      String frontUrl = '', backUrl = '', selfieUrl = '';

      if (_frontBytes != null) {
        setState(() => _uploadStatus = 'Uploading Front of ID...');
        frontUrl =
            await _uploadBytes(_frontBytes!, '$uid/${timestamp}_front.jpg');
      }
      if (_backBytes != null) {
        setState(() => _uploadStatus = 'Uploading Back of ID...');
        backUrl = await _uploadBytes(_backBytes!, '$uid/${timestamp}_back.jpg');
      }
      if (_selfieBytes != null) {
        setState(() => _uploadStatus = 'Uploading Selfie...');
        selfieUrl =
            await _uploadBytes(_selfieBytes!, '$uid/${timestamp}_selfie.jpg');
      }

      setState(() => _uploadStatus = 'Saving record...');

      await _supabase.from('submissions').insert({
        'uid': uid,
        'document_type': _docType == 'ghana' ? 'GHANA CARD' : 'SCHOOL ID',
        'full_name': _nameCtrl.text.trim(),
        'id_number': _idCtrl.text.trim(),
        'date_of_birth': _dobCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'institution': _institutionCtrl.text.trim(),
        'status': 'Pending',
        'front_image_url': frontUrl,
        'back_image_url': backUrl,
        'selfie_image_url': selfieUrl,
        'created_at': DateTime.now().toIso8601String(),
      });

      if (!mounted) return;
      setState(() {
        _submitting = false;
        _uploadStatus = '';
      });
      _showSuccessDialog();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _uploadStatus = '';
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: $e'),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 8),
          Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                  color: kGreenLight, shape: BoxShape.circle),
              child: const Icon(Icons.check_circle_rounded,
                  color: kGreen, size: 48)),
          const SizedBox(height: 20),
          const Text('Submitted!',
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold, color: kGreen)),
          const SizedBox(height: 10),
          const Text(
              'Your verification request and documents have been submitted successfully.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 24),
          SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: kGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 14)),
                onPressed: () {
                  Navigator.of(context).pop();
                  setState(() {
                    _step = 0;
                    _docType = 'ghana';
                    _nameCtrl.clear();
                    _idCtrl.clear();
                    _dobCtrl.clear();
                    _phoneCtrl.clear();
                    _emailCtrl.clear();
                    _institutionCtrl.clear();
                    _frontBytes = null;
                    _backBytes = null;
                    _selfieBytes = null;
                    _uploadStatus = '';
                  });
                },
                child: const Text('Done', style: TextStyle(fontSize: 16)),
              )),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
          child: Column(children: [
        _Header(step: _step),
        Expanded(
            child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: _buildStep(),
        )),
      ])),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 0:
        return _Step1(
            selected: _docType,
            onSelect: (v) => setState(() => _docType = v),
            onNext: _next);
      case 1:
        return _Step2(
          docType: _docType,
          nameCtrl: _nameCtrl,
          idCtrl: _idCtrl,
          dobCtrl: _dobCtrl,
          phoneCtrl: _phoneCtrl,
          emailCtrl: _emailCtrl,
          institutionCtrl: _institutionCtrl,
          onBack: _back,
          onNext: _next,
        );
      case 2:
        return _Step3(
          frontBytes: _frontBytes,
          backBytes: _backBytes,
          selfieBytes: _selfieBytes,
          onFrontPicked: () async {
            final b = await _pickImageBytes();
            if (b != null) setState(() => _frontBytes = b);
          },
          onBackPicked: () async {
            final b = await _pickImageBytes();
            if (b != null) setState(() => _backBytes = b);
          },
          onSelfiePicked: () async {
            final b = await _pickImageBytes();
            if (b != null) setState(() => _selfieBytes = b);
          },
          onBack: _back,
          onNext: _next,
        );
      case 3:
        return _Step4(
          docType: _docType,
          name: _nameCtrl.text.trim(),
          idNumber: _idCtrl.text.trim(),
          dob: _dobCtrl.text.trim(),
          institution: _institutionCtrl.text.trim(),
          uploadStatus: _uploadStatus,
          frontBytes: _frontBytes,
          backBytes: _backBytes,
          submitting: _submitting,
          onBack: _back,
          onSubmit: _submit,
        );
      default:
        return const SizedBox();
    }
  }
}

// ── Header + Step Indicator ───────────────────
class _Header extends StatelessWidget {
  final int step;
  const _Header({required this.step});
  @override
  Widget build(BuildContext context) {
    return Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Verify Your Identity',
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.bold, color: kGreen)),
          const SizedBox(height: 4),
          const Text('Please provide official documents for verification.',
              style: TextStyle(fontSize: 13, color: Colors.grey)),
          const SizedBox(height: 20),
          _StepIndicator(currentStep: step),
        ]));
  }
}

class _StepIndicator extends StatelessWidget {
  final int currentStep;
  const _StepIndicator({required this.currentStep});
  @override
  Widget build(BuildContext context) {
    return Row(
        children: List.generate(4, (i) {
      final done = i < currentStep;
      final active = i == currentStep;
      Widget circle = done
          ? _circle(
              bg: kGreen,
              child: const Icon(Icons.check, color: Colors.white, size: 16))
          : active
              ? _circle(
                  bg: kGreen,
                  child: Text('${i + 1}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13)))
              : _circle(
                  bg: Colors.white,
                  border: Colors.grey.shade300,
                  child: Text('${i + 1}',
                      style: TextStyle(
                          color: Colors.grey.shade400,
                          fontWeight: FontWeight.bold,
                          fontSize: 13)));
      if (i == 3) return circle;
      return Expanded(
          child: Row(children: [
        circle,
        Expanded(
            child: Container(
                height: 2,
                color: i < currentStep ? kGreen : Colors.grey.shade300)),
      ]));
    }));
  }

  Widget _circle({required Color bg, Color? border, required Widget child}) {
    return Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
            color: bg,
            shape: BoxShape.circle,
            border:
                border != null ? Border.all(color: border, width: 2) : null),
        child: Center(child: child));
  }
}

// ── Step 1 ────────────────────────────────────
class _Step1 extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelect;
  final VoidCallback onNext;
  const _Step1(
      {required this.selected, required this.onSelect, required this.onNext});
  @override
  Widget build(BuildContext context) {
    return _Card(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Select Document Type',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      const SizedBox(height: 20),
      Row(children: [
        _DocCard(
            icon: Icons.credit_card_rounded,
            title: 'Ghana Card',
            subtitle: 'National Identity Card',
            isSelected: selected == 'ghana',
            onTap: () => onSelect('ghana')),
        const SizedBox(width: 14),
        _DocCard(
            icon: Icons.school_rounded,
            title: 'School ID',
            subtitle: 'University or College ID',
            isSelected: selected == 'school',
            onTap: () => onSelect('school')),
      ]),
      const SizedBox(height: 28),
      _NavRow(showBack: false, onNext: onNext),
    ]));
  }
}

// ── Step 2 ────────────────────────────────────
class _Step2 extends StatelessWidget {
  final String docType;
  final TextEditingController nameCtrl,
      idCtrl,
      dobCtrl,
      phoneCtrl,
      emailCtrl,
      institutionCtrl;
  final VoidCallback onBack, onNext;
  const _Step2(
      {required this.docType,
      required this.nameCtrl,
      required this.idCtrl,
      required this.dobCtrl,
      required this.phoneCtrl,
      required this.emailCtrl,
      required this.institutionCtrl,
      required this.onBack,
      required this.onNext});
  bool get isSchool => docType == 'school';
  @override
  Widget build(BuildContext context) {
    return _Card(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Personal Details',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      const SizedBox(height: 20),
      Row(children: [
        Expanded(
            child:
                _Field(ctrl: nameCtrl, label: 'Full Name', hint: 'Ibn Shiraz')),
        const SizedBox(width: 14),
        Expanded(
            child: _Field(
                ctrl: idCtrl,
                label: isSchool ? 'Index / Student ID' : 'Ghana Card Number',
                hint: isSchool ? 'e.g. BTIT240055' : 'GHA-000000000-0')),
      ]),
      if (isSchool) ...[
        const SizedBox(height: 14),
        _Field(
            ctrl: institutionCtrl,
            label: 'Name of Institution',
            hint: 'e.g. Tamale Technical University',
            icon: Icons.account_balance_rounded),
      ],
      const SizedBox(height: 14),
      Row(children: [
        Expanded(
            child: _Field(
                ctrl: dobCtrl,
                label: 'Date of Birth',
                hint: 'dd/mm/yyyy',
                readOnly: true,
                suffix: const Icon(Icons.calendar_today_rounded,
                    size: 18, color: kGrey),
                onTap: () async {
                  final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime(2000),
                      firstDate: DateTime(1940),
                      lastDate: DateTime.now(),
                      builder: (ctx, child) => Theme(
                          data: Theme.of(ctx).copyWith(
                              colorScheme:
                                  const ColorScheme.light(primary: kGreen)),
                          child: child!));
                  if (picked != null) {
                    dobCtrl.text =
                        '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
                  }
                })),
        const SizedBox(width: 14),
        Expanded(
            child: _Field(
                ctrl: phoneCtrl,
                label: 'Phone Number',
                hint: '054 332 5635',
                keyboardType: TextInputType.phone)),
      ]),
      const SizedBox(height: 14),
      _Field(
          ctrl: emailCtrl,
          label: 'Email Address',
          hint: 'ibnshiraz@yahoo.com',
          keyboardType: TextInputType.emailAddress),
      const SizedBox(height: 28),
      _NavRow(showBack: true, onBack: onBack, onNext: onNext),
    ]));
  }
}

// ── Step 3 ────────────────────────────────────
class _Step3 extends StatelessWidget {
  final Uint8List? frontBytes, backBytes, selfieBytes;
  final VoidCallback onFrontPicked,
      onBackPicked,
      onSelfiePicked,
      onBack,
      onNext;
  const _Step3(
      {required this.frontBytes,
      required this.backBytes,
      required this.selfieBytes,
      required this.onFrontPicked,
      required this.onBackPicked,
      required this.onSelfiePicked,
      required this.onBack,
      required this.onNext});
  @override
  Widget build(BuildContext context) {
    return _Card(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Upload Documents',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      const SizedBox(height: 4),
      const Text('Ensure all text is clearly legible and well-lit.',
          style: TextStyle(color: kGrey, fontSize: 13)),
      const SizedBox(height: 20),
      Row(children: [
        Expanded(
            child: _UploadBox(
                label: 'Front of ID',
                required: true,
                imageBytes: frontBytes,
                onTap: onFrontPicked)),
        const SizedBox(width: 14),
        Expanded(
            child: _UploadBox(
                label: 'Back of ID',
                required: false,
                imageBytes: backBytes,
                onTap: onBackPicked)),
      ]),
      const SizedBox(height: 14),
      _UploadBox(
          label: 'Selfie with ID',
          required: false,
          tall: true,
          imageBytes: selfieBytes,
          onTap: onSelfiePicked,
          hint: 'Upload a clear selfie holding your ID'),
      const SizedBox(height: 28),
      _NavRow(
          showBack: true,
          onBack: onBack,
          onNext: frontBytes == null ? null : onNext),
      if (frontBytes == null)
        const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text('* Front of ID is required to continue',
                style: TextStyle(color: Colors.red, fontSize: 12))),
    ]));
  }
}

// ── Step 4 ────────────────────────────────────
class _Step4 extends StatelessWidget {
  final String docType, name, idNumber, dob, institution, uploadStatus;
  final Uint8List? frontBytes, backBytes;
  final bool submitting;
  final VoidCallback onBack, onSubmit;
  const _Step4(
      {required this.docType,
      required this.name,
      required this.idNumber,
      required this.dob,
      required this.institution,
      required this.uploadStatus,
      required this.frontBytes,
      required this.backBytes,
      required this.submitting,
      required this.onBack,
      required this.onSubmit});
  bool get isSchool => docType == 'school';
  @override
  Widget build(BuildContext context) {
    return _Card(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Review & Submit',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      const SizedBox(height: 20),
      Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: kBg, borderRadius: BorderRadius.circular(12)),
          child: Column(children: [
            Row(children: [
              Expanded(
                  child: _ReviewField(
                      label: 'Document Type',
                      value: isSchool ? 'SCHOOL ID' : 'GHANA CARD')),
              Expanded(
                  child: _ReviewField(
                      label: isSchool ? 'Index / Student ID' : 'Ghana Card No.',
                      value: idNumber)),
            ]),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: _ReviewField(label: 'Full Name', value: name)),
              Expanded(child: _ReviewField(label: 'Date of Birth', value: dob)),
            ]),
            if (isSchool) ...[
              const SizedBox(height: 16),
              Row(children: [
                Expanded(
                    child:
                        _ReviewField(label: 'Institution', value: institution)),
                const Expanded(child: SizedBox()),
              ]),
            ],
          ])),
      const SizedBox(height: 20),
      const Text('Attached Documents',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      const SizedBox(height: 12),
      Row(children: [
        if (frontBytes != null)
          _ThumbPreview(bytes: frontBytes!, label: 'Front'),
        if (backBytes != null) ...[
          const SizedBox(width: 12),
          _ThumbPreview(bytes: backBytes!, label: 'Back')
        ],
        if (frontBytes == null)
          const Text('No documents attached', style: TextStyle(color: kGrey)),
      ]),
      const SizedBox(height: 20),
      Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
              color: kGreenLight,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: kGreen.withOpacity(0.3))),
          child: const Text(
              'By submitting, I confirm that all information provided is accurate and the documents are genuine.',
              style: TextStyle(fontSize: 13, color: kGreen))),
      const SizedBox(height: 20),
      if (submitting && uploadStatus.isNotEmpty) ...[
        Row(children: [
          const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: kGreen)),
          const SizedBox(width: 10),
          Text(uploadStatus,
              style: const TextStyle(color: kGreen, fontSize: 13)),
        ]),
        const SizedBox(height: 16),
      ],
      _NavRow(
          showBack: !submitting,
          onBack: onBack,
          onNext: submitting ? null : onSubmit,
          nextLabel: 'Submit Verification',
          nextIcon: Icons.check_circle_outline_rounded),
    ]));
  }
}

// ── Reusable Widgets ──────────────────────────
class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});
  @override
  Widget build(BuildContext context) {
    return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4))
            ]),
        child: child);
  }
}

class _DocCard extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final bool isSelected;
  final VoidCallback onTap;
  const _DocCard(
      {required this.icon,
      required this.title,
      required this.subtitle,
      required this.isSelected,
      required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Expanded(
        child: GestureDetector(
            onTap: onTap,
            child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                    color: isSelected ? kGreenLight : Colors.white,
                    border: Border.all(
                        color: isSelected ? kGreen : Colors.grey.shade300,
                        width: isSelected ? 2 : 1.5),
                    borderRadius: BorderRadius.circular(14)),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(icon,
                          size: 28,
                          color: isSelected ? kGreen : Colors.grey.shade600),
                      const SizedBox(height: 10),
                      Text(title,
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isSelected ? kGreen : Colors.black87)),
                      const SizedBox(height: 4),
                      Text(subtitle,
                          style: const TextStyle(fontSize: 12, color: kGrey)),
                    ]))));
  }
}

class _Field extends StatelessWidget {
  final TextEditingController ctrl;
  final String label, hint;
  final TextInputType? keyboardType;
  final VoidCallback? onTap;
  final bool readOnly;
  final Widget? suffix;
  final IconData? icon;
  const _Field(
      {required this.ctrl,
      required this.label,
      required this.hint,
      this.keyboardType,
      this.onTap,
      this.readOnly = false,
      this.suffix,
      this.icon});
  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.black87)),
      const SizedBox(height: 6),
      TextField(
          controller: ctrl,
          keyboardType: keyboardType,
          readOnly: readOnly,
          onTap: onTap,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: kGrey, fontSize: 13),
              prefixIcon:
                  icon != null ? Icon(icon, color: kGrey, size: 20) : null,
              suffixIcon: suffix,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              filled: true,
              fillColor: kBg,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade300)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade300)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: kGreen, width: 1.5)))),
    ]);
  }
}

class _UploadBox extends StatelessWidget {
  final String label, hint;
  final bool required, tall;
  final Uint8List? imageBytes;
  final VoidCallback onTap;
  const _UploadBox(
      {required this.label,
      required this.required,
      required this.imageBytes,
      required this.onTap,
      this.hint = 'Tap to upload',
      this.tall = false});
  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text(label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        if (required) const Text(' *', style: TextStyle(color: Colors.red)),
        if (!required)
          const Text(' (Optional)',
              style: TextStyle(color: kGrey, fontSize: 12)),
      ]),
      const SizedBox(height: 8),
      GestureDetector(
          onTap: onTap,
          child: Container(
              height: tall ? 120 : 100,
              width: double.infinity,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: imageBytes != null ? kGreen : Colors.grey.shade300,
                      width: 1.5)),
              clipBehavior: Clip.antiAlias,
              child: imageBytes != null
                  ? Stack(fit: StackFit.expand, children: [
                      Image.memory(imageBytes!, fit: BoxFit.cover),
                      Positioned(
                          top: 6,
                          right: 6,
                          child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                  color: kGreen, shape: BoxShape.circle),
                              child: const Icon(Icons.check,
                                  color: Colors.white, size: 14))),
                    ])
                  : Container(
                      color: kBg,
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.cloud_upload_outlined,
                                color: kGrey, size: 30),
                            const SizedBox(height: 6),
                            Text(hint,
                                style:
                                    const TextStyle(color: kGrey, fontSize: 12),
                                textAlign: TextAlign.center),
                          ])))),
    ]);
  }
}

class _ReviewField extends StatelessWidget {
  final String label, value;
  const _ReviewField({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 12, color: kGrey)),
      const SizedBox(height: 4),
      Text(value.isEmpty ? '—' : value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
    ]);
  }
}

class _ThumbPreview extends StatelessWidget {
  final Uint8List bytes;
  final String label;
  const _ThumbPreview({required this.bytes, required this.label});
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.memory(bytes, width: 90, height: 60, fit: BoxFit.cover)),
      const SizedBox(height: 4),
      Text(label, style: const TextStyle(fontSize: 11, color: kGrey)),
    ]);
  }
}

class _NavRow extends StatelessWidget {
  final bool showBack;
  final VoidCallback? onBack, onNext;
  final String nextLabel;
  final IconData? nextIcon;
  const _NavRow(
      {required this.showBack,
      this.onBack,
      this.onNext,
      this.nextLabel = 'Continue',
      this.nextIcon});
  @override
  Widget build(BuildContext context) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      if (showBack)
        TextButton.icon(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_rounded, size: 18),
            label: const Text('Back'),
            style: TextButton.styleFrom(foregroundColor: Colors.grey.shade700))
      else
        const SizedBox(),
      ElevatedButton.icon(
          onPressed: onNext,
          icon: onNext == null
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : Icon(nextIcon ?? Icons.arrow_forward_rounded,
                  size: 18, color: Colors.white),
          label: Text(nextLabel,
              style: const TextStyle(color: Colors.white, fontSize: 14)),
          style: ElevatedButton.styleFrom(
              backgroundColor: onNext == null ? Colors.grey : kGreen,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)))),
    ]);
  }
}
