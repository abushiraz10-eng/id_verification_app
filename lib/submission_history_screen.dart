import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const kGreen = Color(0xFF1B6B3A);
const kGreenLight = Color(0xFFE8F5E9);
const kBg = Color(0xFFF4F6F8);
const kGrey = Color(0xFF888888);

class SubmissionHistoryScreen extends StatefulWidget {
  const SubmissionHistoryScreen({super.key});

  @override
  State<SubmissionHistoryScreen> createState() =>
      _SubmissionHistoryScreenState();
}

class _SubmissionHistoryScreenState extends State<SubmissionHistoryScreen> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _submissions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _loading = true);
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final data = await _supabase
          .from('submissions')
          .select()
          .eq('uid', user.id)
          .order('created_at', ascending: false);

      setState(() {
        _submissions = List<Map<String, dynamic>>.from(data);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading history: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
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

  String _formatDate(dynamic val) {
    if (val == null) return '—';
    try {
      final dt = DateTime.parse(val.toString()).toLocal();
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
      ];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return val.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('My Submissions',
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: kGreen)),
                  SizedBox(height: 4),
                  Text('All your verification requests.',
                      style: TextStyle(fontSize: 13, color: kGrey)),
                ],
              ),
            ),

            // ── Content ──
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(color: kGreen))
                  : _submissions.isEmpty
                      ? _buildEmpty()
                      : RefreshIndicator(
                          color: kGreen,
                          onRefresh: _loadHistory,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _submissions.length,
                            itemBuilder: (_, i) => _SubmissionCard(
                              submission: _submissions[i],
                              statusColor: _statusColor(
                                  _submissions[i]['status'] ?? 'Pending'),
                              statusIcon: _statusIcon(
                                  _submissions[i]['status'] ?? 'Pending'),
                              formatDate: _formatDate,
                              onTap: () => _openDetail(_submissions[i]),
                            ),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration:
                const BoxDecoration(color: kGreenLight, shape: BoxShape.circle),
            child: const Icon(Icons.inbox_rounded, size: 48, color: kGreen),
          ),
          const SizedBox(height: 20),
          const Text('No Submissions Yet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text(
            'You haven\'t submitted any ID for\nverification yet.',
            textAlign: TextAlign.center,
            style: TextStyle(color: kGrey, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.upload_file_rounded,
                color: Colors.white, size: 18),
            label:
                const Text('Submit ID', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: kGreen,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  void _openDetail(Map<String, dynamic> submission) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          _DetailSheet(submission: submission, formatDate: _formatDate),
    );
  }
}

// ── Submission Card ───────────────────────────
class _SubmissionCard extends StatelessWidget {
  final Map<String, dynamic> submission;
  final Color statusColor;
  final IconData statusIcon;
  final String Function(dynamic) formatDate;
  final VoidCallback onTap;

  const _SubmissionCard({
    required this.submission,
    required this.statusColor,
    required this.statusIcon,
    required this.formatDate,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final status = submission['status'] as String? ?? 'Pending';
    final docType = submission['document_type'] as String? ?? '';
    final idNumber = submission['id_number'] as String? ?? '';
    final date = formatDate(submission['created_at']);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: Row(
          children: [
            // Status icon circle
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(statusIcon, color: statusColor, size: 24),
            ),
            const SizedBox(width: 14),

            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(docType,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14)),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(status,
                            style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 11)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(children: [
                    const Icon(Icons.tag_rounded, size: 13, color: kGrey),
                    const SizedBox(width: 4),
                    Text(idNumber,
                        style: const TextStyle(color: kGrey, fontSize: 12)),
                  ]),
                  const SizedBox(height: 4),
                  Row(children: [
                    const Icon(Icons.calendar_today_rounded,
                        size: 13, color: kGrey),
                    const SizedBox(width: 4),
                    Text('Submitted: $date',
                        style: const TextStyle(color: kGrey, fontSize: 12)),
                  ]),
                ],
              ),
            ),

            const Icon(Icons.chevron_right_rounded, color: kGrey),
          ],
        ),
      ),
    );
  }
}

// ── Detail Bottom Sheet ───────────────────────
class _DetailSheet extends StatelessWidget {
  final Map<String, dynamic> submission;
  final String Function(dynamic) formatDate;

  const _DetailSheet({required this.submission, required this.formatDate});

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
    final institution = submission['institution'] as String? ?? '';

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(children: [
        // Handle
        const SizedBox(height: 12),
        Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 16),

        // Title + status
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Submission Details',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: sColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(status,
                    style: TextStyle(
                        color: sColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
              ),
            ],
          ),
        ),

        Divider(color: Colors.grey.shade100, height: 24),

        // Scrollable content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Info ──
                _sectionTitle('Submission Information'),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: kBg, borderRadius: BorderRadius.circular(12)),
                  child: Column(children: [
                    _infoRow(
                        'Document Type', submission['document_type'] ?? '—'),
                    _div(),
                    _infoRow('Full Name', submission['full_name'] ?? '—'),
                    _div(),
                    _infoRow('ID Number', submission['id_number'] ?? '—'),
                    _div(),
                    _infoRow(
                        'Date of Birth', submission['date_of_birth'] ?? '—'),
                    _div(),
                    _infoRow('Phone', submission['phone'] ?? '—'),
                    _div(),
                    _infoRow('Email', submission['email'] ?? '—'),
                    if (institution.isNotEmpty) ...[
                      _div(),
                      _infoRow('Institution', institution),
                    ],
                    _div(),
                    _infoRow(
                        'Date Submitted', formatDate(submission['created_at'])),
                  ]),
                ),

                const SizedBox(height: 24),

                // ── Status message ──
                _statusBanner(status, sColor),

                const SizedBox(height: 24),

                // ── Uploaded documents ──
                _sectionTitle('Uploaded Documents'),
                const SizedBox(height: 12),

                if (frontUrl.isEmpty && backUrl.isEmpty && selfieUrl.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                        color: kBg, borderRadius: BorderRadius.circular(12)),
                    child: const Center(
                      child: Text('No documents uploaded',
                          style: TextStyle(color: kGrey)),
                    ),
                  )
                else
                  Column(children: [
                    if (frontUrl.isNotEmpty || backUrl.isNotEmpty)
                      Row(children: [
                        if (frontUrl.isNotEmpty)
                          Expanded(child: _imgCard('Front of ID', frontUrl)),
                        if (frontUrl.isNotEmpty && backUrl.isNotEmpty)
                          const SizedBox(width: 12),
                        if (backUrl.isNotEmpty)
                          Expanded(child: _imgCard('Back of ID', backUrl)),
                      ]),
                    if (selfieUrl.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _imgCard('Selfie with ID', selfieUrl, tall: true),
                    ],
                  ]),

                const SizedBox(height: 28),
              ],
            ),
          ),
        ),
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: kGrey, fontSize: 13)),
          Flexible(
              child: Text(value,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13),
                  textAlign: TextAlign.right,
                  overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }

  Widget _div() => Divider(height: 1, color: Colors.grey.shade200);

  Widget _statusBanner(String status, Color color) {
    String message;
    IconData icon;
    switch (status.toLowerCase()) {
      case 'approved':
        message = 'Your identity has been verified and approved!';
        icon = Icons.check_circle_rounded;
        break;
      case 'rejected':
        message =
            'Your submission was rejected. Please resubmit with correct documents.';
        icon = Icons.cancel_rounded;
        break;
      default:
        message =
            'Your submission is under review. You\'ll be notified once it\'s approved.';
        icon = Icons.access_time_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 10),
        Expanded(
            child: Text(message,
                style: TextStyle(color: color, fontSize: 13, height: 1.4))),
      ]),
    );
  }

  Widget _imgCard(String label, String url, {bool tall = false}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.black87)),
      const SizedBox(height: 6),
      Container(
        height: tall ? 160 : 120,
        width: double.infinity,
        decoration: BoxDecoration(
          color: kBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade200),
        ),
        clipBehavior: Clip.antiAlias,
        child: Image.network(url,
            fit: BoxFit.cover,
            loadingBuilder: (_, child, progress) => progress == null
                ? child
                : const Center(
                    child: CircularProgressIndicator(
                        color: kGreen, strokeWidth: 2)),
            errorBuilder: (_, __, ___) => const Center(
                child:
                    Icon(Icons.broken_image_outlined, color: kGrey, size: 32))),
      ),
    ]);
  }
}
