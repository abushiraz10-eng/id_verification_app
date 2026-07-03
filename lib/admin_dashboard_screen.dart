import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const kGreen = Color(0xFF1B6B3A);
const kGreenLight = Color(0xFFE8F5E9);
const kBg = Color(0xFFF4F6F8);
const kGrey = Color(0xFF888888);

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});
  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final _supabase = Supabase.instance.client;
  final _searchCtrl = TextEditingController();

  List<Map<String, dynamic>> _all = [];
  List<Map<String, dynamic>> _filtered = [];
  String _activeFilter = 'All';
  bool _loading = true;

  final _filters = ['All', 'Pending', 'Approved', 'Rejected'];

  @override
  void initState() {
    super.initState();
    _loadSubmissions();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSubmissions() async {
    setState(() => _loading = true);
    try {
      final data = await _supabase
          .from('submissions')
          .select()
          .order('created_at', ascending: false);
      setState(() {
        _all = List<Map<String, dynamic>>.from(data);
        _applyFilter();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _applyFilter() {
    final q = _searchCtrl.text.trim().toLowerCase();
    setState(() {
      _filtered = _all.where((s) {
        final matchFilter = _activeFilter == 'All' ||
            (s['status'] ?? '').toLowerCase() == _activeFilter.toLowerCase();
        final matchSearch = q.isEmpty ||
            (s['full_name'] ?? '').toLowerCase().contains(q) ||
            (s['id_number'] ?? '').toLowerCase().contains(q);
        return matchFilter && matchSearch;
      }).toList();
    });
  }

  Future<void> _updateStatus(String id, String status) async {
    try {
      await _supabase
          .from('submissions')
          .update({'status': status}).eq('id', id);
      _loadSubmissions();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Update failed: $e')));
      }
    }
  }

  // ── Open full submission detail sheet ───────
  void _openDetail(Map<String, dynamic> submission) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SubmissionDetailSheet(
        submission: submission,
        onApprove: () {
          Navigator.pop(context);
          _updateStatus(submission['id'].toString(), 'Approved');
        },
        onReject: () {
          Navigator.pop(context);
          _updateStatus(submission['id'].toString(), 'Rejected');
        },
      ),
    );
  }

  int _countByStatus(String s) => _all
      .where((x) => (x['status'] ?? '').toLowerCase() == s.toLowerCase())
      .length;

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

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    final dateStr =
        '${days[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}, ${now.year}';

    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── Header ──
        Container(
            width: double.infinity,
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Admin Dashboard',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                Text(dateStr,
                    style: const TextStyle(color: kGrey, fontSize: 11)),
              ]),
              const SizedBox(height: 2),
              const Text('Manage and review verification requests.',
                  style: TextStyle(color: kGrey, fontSize: 12)),
            ])),

        Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: kGreen))
                : RefreshIndicator(
                    color: kGreen,
                    onRefresh: _loadSubmissions,
                    child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // ── Stat cards ──
                              Row(children: [
                                _StatCard(
                                    label: 'Total',
                                    count: '${_all.length}',
                                    color: kGreen,
                                    icon: Icons.people_alt_rounded),
                                const SizedBox(width: 8),
                                _StatCard(
                                    label: 'Pending',
                                    count: '${_countByStatus("Pending")}',
                                    color: const Color(0xFFF59E0B),
                                    icon: Icons.pending_actions_rounded),
                                const SizedBox(width: 8),
                                _StatCard(
                                    label: 'Approved',
                                    count: '${_countByStatus("Approved")}',
                                    color: const Color(0xFF10B981),
                                    icon: Icons.verified_rounded),
                                const SizedBox(width: 8),
                                _StatCard(
                                    label: 'Rejected',
                                    count: '${_countByStatus("Rejected")}',
                                    color: const Color(0xFFEF4444),
                                    icon: Icons.cancel_rounded),
                              ]),
                              const SizedBox(height: 16),

                              // ── Search ──
                              TextField(
                                  controller: _searchCtrl,
                                  onChanged: (_) => _applyFilter(),
                                  style: const TextStyle(fontSize: 14),
                                  decoration: InputDecoration(
                                      hintText: 'Search name or ID...',
                                      hintStyle: const TextStyle(
                                          color: kGrey, fontSize: 13),
                                      prefixIcon: const Icon(
                                          Icons.search_rounded,
                                          color: kGrey,
                                          size: 20),
                                      filled: true,
                                      fillColor: Colors.white,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 14, vertical: 12),
                                      border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          borderSide: BorderSide(
                                              color: Colors.grey.shade300)),
                                      enabledBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          borderSide: BorderSide(
                                              color: Colors.grey.shade300)),
                                      focusedBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          borderSide: const BorderSide(
                                              color: kGreen, width: 1.5)))),
                              const SizedBox(height: 12),

                              // ── Filter tabs ──
                              SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                      children: _filters.map((f) {
                                    final active = _activeFilter == f;
                                    return GestureDetector(
                                        onTap: () {
                                          setState(() => _activeFilter = f);
                                          _applyFilter();
                                        },
                                        child: AnimatedContainer(
                                            duration: const Duration(
                                                milliseconds: 180),
                                            margin:
                                                const EdgeInsets.only(right: 8),
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 16, vertical: 8),
                                            decoration: BoxDecoration(
                                                color: active
                                                    ? kGreen
                                                    : Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                                border: Border.all(
                                                    color: active
                                                        ? kGreen
                                                        : Colors
                                                            .grey.shade300)),
                                            child: Text(f,
                                                style: TextStyle(
                                                    color: active
                                                        ? Colors.white
                                                        : kGrey,
                                                    fontWeight: active
                                                        ? FontWeight.w600
                                                        : FontWeight.normal,
                                                    fontSize: 13))));
                                  }).toList())),
                              const SizedBox(height: 16),

                              // ── List ──
                              if (_filtered.isEmpty)
                                Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 48),
                                    decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                    child: const Column(children: [
                                      Icon(Icons.inbox_rounded,
                                          size: 40, color: kGrey),
                                      SizedBox(height: 12),
                                      Text(
                                          'No verifications found matching your filters.',
                                          style: TextStyle(
                                              color: kGrey, fontSize: 13),
                                          textAlign: TextAlign.center),
                                    ]))
                              else
                                Column(
                                    children: _filtered
                                        .map((s) => _SubmissionCard(
                                              submission: s,
                                              statusColor: _statusColor(
                                                  s['status'] ?? 'Pending'),
                                              onTap: () => _openDetail(s),
                                              onApprove: () => _updateStatus(
                                                  s['id'].toString(),
                                                  'Approved'),
                                              onReject: () => _updateStatus(
                                                  s['id'].toString(),
                                                  'Rejected'),
                                            ))
                                        .toList()),
                            ])))),
      ])),
    );
  }
}

// ── Stat Card ─────────────────────────────────
class _StatCard extends StatelessWidget {
  final String label, count;
  final Color color;
  final IconData icon;
  const _StatCard(
      {required this.label,
      required this.count,
      required this.color,
      required this.icon});
  @override
  Widget build(BuildContext context) {
    return Expanded(
        child: Container(
            padding: const EdgeInsets.fromLTRB(10, 12, 10, 10),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border(top: BorderSide(color: color, width: 3)),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.05), blurRadius: 8)
                ]),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 10, color: kGrey, fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              Text(count,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Align(
                  alignment: Alignment.centerRight,
                  child: Icon(icon, color: color.withOpacity(0.6), size: 18)),
            ])));
  }
}

// ── Submission Card ───────────────────────────
class _SubmissionCard extends StatelessWidget {
  final Map<String, dynamic> submission;
  final Color statusColor;
  final VoidCallback onTap, onApprove, onReject;
  const _SubmissionCard(
      {required this.submission,
      required this.statusColor,
      required this.onTap,
      required this.onApprove,
      required this.onReject});

  @override
  Widget build(BuildContext context) {
    final status = submission['status'] as String? ?? 'Pending';
    return GestureDetector(
      onTap: onTap,
      child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)
              ]),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Expanded(
                  child: Text(submission['full_name'] ?? 'Unknown',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15),
                      overflow: TextOverflow.ellipsis)),
              Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20)),
                  child: Text(status,
                      style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 12))),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              _detail(
                  Icons.credit_card_rounded, submission['document_type'] ?? ''),
              const SizedBox(width: 16),
              _detail(Icons.tag_rounded, submission['id_number'] ?? ''),
            ]),
            const SizedBox(height: 6),
            // Tap hint
            Row(children: [
              Icon(Icons.image_outlined,
                  size: 13, color: kGreen.withOpacity(0.7)),
              const SizedBox(width: 4),
              Text('Tap to view documents',
                  style:
                      TextStyle(color: kGreen.withOpacity(0.7), fontSize: 11)),
            ]),
            if (status.toLowerCase() == 'pending') ...[
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                    child: OutlinedButton.icon(
                        onPressed: onReject,
                        icon: const Icon(Icons.close_rounded,
                            size: 16, color: Color(0xFFEF4444)),
                        label: const Text('Reject',
                            style: TextStyle(color: Color(0xFFEF4444))),
                        style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFEF4444)),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(vertical: 8)))),
                const SizedBox(width: 10),
                Expanded(
                    child: ElevatedButton.icon(
                        onPressed: onApprove,
                        icon: const Icon(Icons.check_rounded,
                            size: 16, color: Colors.white),
                        label: const Text('Approve',
                            style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: kGreen,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(vertical: 8)))),
              ]),
            ],
          ])),
    );
  }

  Widget _detail(IconData icon, String text) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 13, color: kGrey),
      const SizedBox(width: 4),
      Text(text.isEmpty ? '—' : text,
          style: const TextStyle(color: kGrey, fontSize: 12)),
    ]);
  }
}

// ── Submission Detail Bottom Sheet ────────────
class _SubmissionDetailSheet extends StatelessWidget {
  final Map<String, dynamic> submission;
  final VoidCallback onApprove, onReject;
  const _SubmissionDetailSheet(
      {required this.submission,
      required this.onApprove,
      required this.onReject});

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

  @override
  Widget build(BuildContext context) {
    final status = submission['status'] as String? ?? 'Pending';
    final sColor = _statusColor(status);
    final frontUrl = submission['front_image_url'] as String? ?? '';
    final backUrl = submission['back_image_url'] as String? ?? '';
    final selfieUrl = submission['selfie_image_url'] as String? ?? '';
    final isPending = status.toLowerCase() == 'pending';

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(children: [
        // Handle bar
        const SizedBox(height: 12),
        Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 16),

        // Header
        Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Submission Details',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                          color: sColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20)),
                      child: Text(status,
                          style: TextStyle(
                              color: sColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 13))),
                ])),

        const SizedBox(height: 4),
        Divider(color: Colors.grey.shade100),

        // Scrollable content
        Expanded(
            child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // ── Personal details ──
            _sectionTitle('Personal Information'),
            const SizedBox(height: 12),
            Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: kBg, borderRadius: BorderRadius.circular(12)),
                child: Column(children: [
                  _infoRow('Full Name', submission['full_name'] ?? '—'),
                  _divider(),
                  _infoRow('Document Type', submission['document_type'] ?? '—'),
                  _divider(),
                  _infoRow('ID Number', submission['id_number'] ?? '—'),
                  _divider(),
                  _infoRow('Date of Birth', submission['date_of_birth'] ?? '—'),
                  _divider(),
                  _infoRow('Phone', submission['phone'] ?? '—'),
                  _divider(),
                  _infoRow('Email', submission['email'] ?? '—'),
                  if ((submission['institution'] ?? '').isNotEmpty) ...[
                    _divider(),
                    _infoRow('Institution', submission['institution']),
                  ],
                ])),

            const SizedBox(height: 24),

            // ── Uploaded documents ──
            _sectionTitle('Uploaded Documents'),
            const SizedBox(height: 12),

            if (frontUrl.isEmpty && backUrl.isEmpty && selfieUrl.isEmpty)
              Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                      color: kBg, borderRadius: BorderRadius.circular(12)),
                  child: const Center(
                      child: Text('No documents uploaded',
                          style: TextStyle(color: kGrey))))
            else
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // Front + Back side by side
                if (frontUrl.isNotEmpty || backUrl.isNotEmpty)
                  Row(children: [
                    if (frontUrl.isNotEmpty)
                      Expanded(
                          child:
                              _ImageCard(label: 'Front of ID', url: frontUrl)),
                    if (frontUrl.isNotEmpty && backUrl.isNotEmpty)
                      const SizedBox(width: 12),
                    if (backUrl.isNotEmpty)
                      Expanded(
                          child: _ImageCard(label: 'Back of ID', url: backUrl)),
                  ]),
                // Selfie full width
                if (selfieUrl.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _ImageCard(
                      label: 'Selfie with ID', url: selfieUrl, tall: true),
                ],
              ]),

            const SizedBox(height: 28),

            // ── Action buttons (only for pending) ──
            if (isPending)
              Row(children: [
                Expanded(
                    child: OutlinedButton.icon(
                  onPressed: onReject,
                  icon: const Icon(Icons.close_rounded,
                      size: 18, color: Color(0xFFEF4444)),
                  label: const Text('Reject',
                      style: TextStyle(color: Color(0xFFEF4444), fontSize: 15)),
                  style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFEF4444)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 14)),
                )),
                const SizedBox(width: 12),
                Expanded(
                    child: ElevatedButton.icon(
                  onPressed: onApprove,
                  icon: const Icon(Icons.check_rounded,
                      size: 18, color: Colors.white),
                  label: const Text('Approve',
                      style: TextStyle(color: Colors.white, fontSize: 15)),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: kGreen,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 14)),
                )),
              ]),

            const SizedBox(height: 20),
          ]),
        )),
      ]),
    );
  }

  Widget _sectionTitle(String title) {
    return Row(children: [
      Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
              color: kGreen, borderRadius: BorderRadius.circular(2))),
      const SizedBox(width: 8),
      Text(title,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
    ]);
  }

  Widget _infoRow(String label, String value) {
    return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child:
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label, style: const TextStyle(color: kGrey, fontSize: 13)),
          Flexible(
              child: Text(value,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13),
                  textAlign: TextAlign.right,
                  overflow: TextOverflow.ellipsis)),
        ]));
  }

  Widget _divider() => Divider(height: 1, color: Colors.grey.shade200);
}

// ── Image Card with tap to zoom ───────────────
class _ImageCard extends StatelessWidget {
  final String label, url;
  final bool tall;
  const _ImageCard({required this.label, required this.url, this.tall = false});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.black87)),
      const SizedBox(height: 6),
      GestureDetector(
        onTap: () => _openFullImage(context),
        child: Container(
            height: tall ? 160 : 130,
            width: double.infinity,
            decoration: BoxDecoration(
                color: kBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200)),
            clipBehavior: Clip.antiAlias,
            child: Stack(fit: StackFit.expand, children: [
              Image.network(url,
                  fit: BoxFit.cover,
                  loadingBuilder: (_, child, progress) => progress == null
                      ? child
                      : const Center(
                          child: CircularProgressIndicator(
                              color: kGreen, strokeWidth: 2)),
                  errorBuilder: (_, __, ___) => const Center(
                      child: Icon(Icons.broken_image_outlined,
                          color: kGrey, size: 32))),
              // Zoom hint overlay
              Positioned(
                  bottom: 6,
                  right: 6,
                  child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          shape: BoxShape.circle),
                      child: const Icon(Icons.zoom_in_rounded,
                          color: Colors.white, size: 14))),
            ])),
      ),
    ]);
  }

  void _openFullImage(BuildContext context) {
    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => _FullImageViewer(url: url, label: label),
        ));
  }
}

// ── Full screen image viewer ──────────────────
class _FullImageViewer extends StatelessWidget {
  final String url, label;
  const _FullImageViewer({required this.url, required this.label});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(label,
            style: const TextStyle(color: Colors.white, fontSize: 15)),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: Image.network(url,
              fit: BoxFit.contain,
              loadingBuilder: (_, child, progress) => progress == null
                  ? child
                  : const CircularProgressIndicator(color: Colors.white),
              errorBuilder: (_, __, ___) => const Icon(Icons.broken_image,
                  color: Colors.white, size: 64)),
        ),
      ),
    );
  }
}
