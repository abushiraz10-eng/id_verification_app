import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const kGreen = Color(0xFF1B6B3A);
const kGreenLight = Color(0xFFE8F5E9);
const kBg = Color(0xFFF4F6F8);
const kGrey = Color(0xFF888888);

class CheckStatusScreen extends StatefulWidget {
  const CheckStatusScreen({super.key});
  @override
  State<CheckStatusScreen> createState() => _CheckStatusScreenState();
}

class _CheckStatusScreenState extends State<CheckStatusScreen> {
  final _supabase = Supabase.instance.client;
  final _searchCtrl = TextEditingController();

  bool _searched = false, _loading = false;
  Map<String, dynamic>? _result;
  String? _errorMsg;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final query = _searchCtrl.text.trim();
    if (query.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter an ID number')));
      return;
    }
    setState(() {
      _loading = true;
      _searched = true;
      _result = null;
      _errorMsg = null;
    });
    try {
      final data = await _supabase
          .from('submissions')
          .select()
          .eq('id_number', query)
          .limit(1);
      if (data.isEmpty) {
        setState(() {
          _errorMsg = 'No record found for "$query"';
        });
      } else {
        setState(() {
          _result = data.first;
        });
      }
    } catch (e) {
      setState(() {
        _errorMsg = 'Error: $e';
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  Color _statusColor(String s) {
    switch (s.toLowerCase()) {
      case 'approved':
        return const Color(0xFF10B981);
      case 'rejected':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFFF59E0B);
    }
  }

  IconData _statusIcon(String s) {
    switch (s.toLowerCase()) {
      case 'approved':
        return Icons.check_circle_rounded;
      case 'rejected':
        return Icons.cancel_rounded;
      default:
        return Icons.access_time_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
          child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(children: [
          Container(
              padding: const EdgeInsets.all(18),
              decoration: const BoxDecoration(
                  color: kGreenLight, shape: BoxShape.circle),
              child: const Icon(Icons.search_rounded, size: 36, color: kGreen)),
          const SizedBox(height: 16),
          const Text('Track Application',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          const Text(
              'Enter your ID number to check the status of your verification.',
              textAlign: TextAlign.center,
              style: TextStyle(color: kGrey, fontSize: 13)),
          const SizedBox(height: 28),
          Row(children: [
            Expanded(
                child: TextField(
              controller: _searchCtrl,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _search(),
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                  hintText: 'e.g. GHA-123456789-0',
                  hintStyle: const TextStyle(color: kGrey, fontSize: 13),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey.shade300)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey.shade300)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: kGreen, width: 1.5))),
            )),
            const SizedBox(width: 10),
            ElevatedButton(
                onPressed: _loading ? null : _search,
                style: ElevatedButton.styleFrom(
                    backgroundColor: kGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    elevation: 0),
                child: _loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text('Search',
                        style: TextStyle(fontWeight: FontWeight.w600))),
          ]),
          const SizedBox(height: 28),
          if (_loading)
            const CircularProgressIndicator(color: kGreen)
          else if (_searched && _errorMsg != null)
            Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.05), blurRadius: 10)
                    ]),
                child: Column(children: [
                  const Icon(Icons.info_outline_rounded,
                      size: 40, color: kGrey),
                  const SizedBox(height: 12),
                  Text(_errorMsg!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: kGrey, fontSize: 14)),
                ]))
          else if (_result != null)
            _ResultCard(
                result: _result!,
                statusColor: _statusColor,
                statusIcon: _statusIcon),
        ]),
      )),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final Map<String, dynamic> result;
  final Color Function(String) statusColor;
  final IconData Function(String) statusIcon;
  const _ResultCard(
      {required this.result,
      required this.statusColor,
      required this.statusIcon});

  @override
  Widget build(BuildContext context) {
    final status = result['status'] as String? ?? 'Pending';
    final sColor = statusColor(status);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, 4))
          ]),
      child: Column(children: [
        Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
                color: sColor.withOpacity(0.1),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(14))),
            child: Column(children: [
              Icon(statusIcon(status), size: 40, color: sColor),
              const SizedBox(height: 8),
              Text(status.toUpperCase(),
                  style: TextStyle(
                      color: sColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      letterSpacing: 1.2)),
            ])),
        Padding(
            padding: const EdgeInsets.all(20),
            child: Column(children: [
              _row('Document Type', result['document_type'] ?? ''),
              _divider(),
              _row('Full Name', result['full_name'] ?? ''),
              _divider(),
              _row('ID Number', result['id_number'] ?? ''),
              _divider(),
              _row('Date of Birth', result['date_of_birth'] ?? ''),
            ])),
      ]),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child:
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label, style: const TextStyle(color: kGrey, fontSize: 13)),
          Text(value.isEmpty ? '—' : value,
              style:
                  const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        ]));
  }

  Widget _divider() => Divider(height: 1, color: Colors.grey.shade100);
}
