// PATH: lib/presentation/screens/money_economy_screen.dart
// STATUS: ✅ Align with Market Radar (Badges + Archive no-index + local sort + source slot label) — FIXED TYPES ✅

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' as intl;

import '../../core/constants/app_colors.dart';
import '../widgets/admin_inline_controls.dart';

class MoneyEconomyScreen extends StatelessWidget {
  const MoneyEconomyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const contentColor = Color(0xFF1B5E20);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7F9),
        appBar: AppBar(
          backgroundColor: AppColors.primaryDeepTeal,
          foregroundColor: Colors.white,
          centerTitle: true,
          elevation: 2,
          shadowColor: Colors.black12,
          title: Text(
            'الاقتصاد والعقار',
            style: GoogleFonts.cairo(fontWeight: FontWeight.w900),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          children: [
            _heroSection(contentColor),
            const SizedBox(height: 30),
            _sectionHeader('مؤشرات السوق', Icons.trending_up, contentColor),
            const SizedBox(height: 12),
            _marketCard(
              context,
              type: _EconomyFormat.shortNews,
              label: 'خبر سريع',
              icon: Icons.flash_on_rounded,
              color: Colors.amber[900]!,
            ),
            const SizedBox(height: 12),
            _marketCard(
              context,
              type: _EconomyFormat.mediumAnalysis,
              label: 'تحليل متوسط',
              icon: Icons.pie_chart_rounded,
              color: contentColor,
            ),
            const SizedBox(height: 12),
            _marketCard(
              context,
              type: _EconomyFormat.deepDive,
              label: 'Deep Dive',
              icon: Icons.scuba_diving_rounded,
              color: AppColors.primaryDeepTeal,
            ),
            const SizedBox(height: 35),
            _sectionHeader(
                'ادواتك الماليه و الاقتصاديه', Icons.history_edu, contentColor),
            const SizedBox(height: 12),
            _buildArchiveList(contentColor),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────
  // Helpers (Radar-style)
  // ─────────────────────────────────────────

  String _cleanText(String text) {
    if (text.isEmpty) return '';
    return text
        .replaceAll(RegExp(r'[\(]تجريبي[\)]|تجريبي|\[.*?\]|##'), '')
        .trim();
  }

  int _safeInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return 0;
  }

  DateTime _dateFromData(Map<String, dynamic> data) {
    final ms = _safeInt(data['createdAtMs']) != 0
        ? _safeInt(data['createdAtMs'])
        : _safeInt(data['updatedAtMs']);
    if (ms <= 0) return DateTime.fromMillisecondsSinceEpoch(0);
    return DateTime.fromMillisecondsSinceEpoch(ms);
  }

  String _slotLabel(String? slot) {
    switch ((slot ?? '').trim()) {
      case 'short_news':
        return 'خبر سريع';
      case 'medium_analysis':
        return 'تحليل متوسط';
      case 'deep_dive':
        return 'Deep Dive';
      default:
        return 'سجل';
    }
  }

  Widget _buildRichContent(String rawBody) {
    final lines = rawBody.split('\n');
    List<Widget> widgets = [];
    for (String line in lines) {
      String text = line.trim();
      if (text.isEmpty) {
        widgets.add(const SizedBox(height: 14));
        continue;
      }
      if (text.startsWith('##') || text.startsWith('[H]')) {
        text = text.replaceAll('##', '').replaceAll('[H]', '').trim();
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 20, bottom: 10),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 24,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D32),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    text,
                    style: GoogleFonts.cairo(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primaryDeepTeal,
                      height: 1.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      } else if (text.startsWith('-') || text.startsWith('•')) {
        text = text.substring(1).trim();
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 8, right: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: Icon(
                    Icons.check_circle,
                    size: 16,
                    color: Color(0xFFC5A059),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    text,
                    style: GoogleFonts.cairo(
                      fontSize: 15,
                      height: 1.6,
                      color: Colors.black87,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      } else {
        text = text.replaceAll('[P]', '').trim();
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              text,
              textAlign: TextAlign.justify,
              style: GoogleFonts.cairo(
                fontSize: 16,
                height: 1.8,
                color: const Color(0xFF263238),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        );
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: widgets,
    );
  }

  Widget _heroSection(Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.attach_money_rounded, color: color, size: 30),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'الاقتصاد اليوم',
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primaryDeepTeal,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'ترجمة لغة المال وتأثيرها العقاري.',
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.blueGrey[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────
  // Cards (Badges like Radar) — FIXED TYPING ✅
  // ─────────────────────────────────────────

  Widget _marketCard(
    BuildContext context, {
    required _EconomyFormat type,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    final docId = _docIdFor(type);

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream:
          FirebaseFirestore.instance.collection('money').doc(docId).snapshots(),
      builder: (context, snapshot) {
        final exists = snapshot.hasData && (snapshot.data?.exists ?? false);
        final data = exists
            ? (snapshot.data!.data() ?? <String, dynamic>{})
            : <String, dynamic>{};

        final bool isPinned = data['isPinned'] == true; // 🔥 مهم
        final bool isFeatured = data['isFeatured'] == true; // ⭐ مميّز

        String title = _cleanText(
          (exists && (data['title']?.toString().isNotEmpty ?? false))
              ? data['title'].toString()
              : label,
        );

        final rawBody = data['body']?.toString() ?? '';
        final cleanPreview = rawBody.replaceAll(RegExp(r'[#\-\n]'), ' ').trim();

        return Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.blueGrey.shade50),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  )
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => _openPreview(
                    context,
                    docId,
                    title,
                    rawBody,
                    _sectionKeyFor(type),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(icon, color: color, size: 24),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.cairo(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.primaryDeepTeal,
                                ),
                              ),
                              const SizedBox(height: 6),
                              if (exists && rawBody.isNotEmpty)
                                Text(
                                  cleanPreview,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.cairo(
                                    fontSize: 12,
                                    color: const Color(0xFF455A64),
                                    fontWeight: FontWeight.w700,
                                    height: 1.4,
                                  ),
                                )
                              else
                                Text(
                                  'اضغط للعرض',
                                  style: GoogleFonts.cairo(
                                    fontSize: 10,
                                    color: Colors.grey[400],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 14,
                          color: Colors.blueGrey,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ✅ Badge (Pinned/Featured)
            if (isPinned || isFeatured)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isPinned
                        ? Colors.deepOrange
                        : AppColors.secondaryOrange,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.18),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      )
                    ],
                  ),
                  child: Text(
                    isPinned ? '🔥 مهم' : '⭐ مميّز',
                    style: GoogleFonts.cairo(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.0,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  // ─────────────────────────────────────────
  // Archive (No index + local sort + source slot label)
  // ─────────────────────────────────────────

  Widget _buildArchiveList(Color color) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('money')
          .where('isArchived', isEqualTo: true)
          .limit(50)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final docs = snapshot.data!.docs.toList();
        if (docs.isEmpty) {
          return Center(
            child: Text(
              'المكتبة فارغة حالياً',
              style: GoogleFonts.cairo(color: Colors.grey),
            ),
          );
        }

        docs.sort((a, b) {
          final ad = a.data();
          final bd = b.data();
          final aMs = _safeInt(ad['createdAtMs']) != 0
              ? _safeInt(ad['createdAtMs'])
              : _safeInt(ad['updatedAtMs']);
          final bMs = _safeInt(bd['createdAtMs']) != 0
              ? _safeInt(bd['createdAtMs'])
              : _safeInt(bd['updatedAtMs']);
          return bMs.compareTo(aMs);
        });

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (ctx, i) {
            final doc = docs[i];
            final data = doc.data();

            final title = _cleanText((data['title'] ?? '').toString());
            final body = (data['body'] ?? '').toString();

            final date = _dateFromData(data);
            final dateText = intl.DateFormat('dd MMM yyyy', 'ar').format(date);

            final sourceSlot = (data['sourceSlot'] ?? '').toString();
            final sourceLabel = _slotLabel(sourceSlot);

            final sectionKey =
                (data['sectionKey']?.toString().trim().isNotEmpty ?? false)
                    ? data['sectionKey'].toString().trim()
                    : 'money';

            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blueGrey.shade50),
              ),
              child: ListTile(
                onTap: () => _openPreview(
                  context,
                  doc.id,
                  title.isEmpty ? sourceLabel : title,
                  body,
                  sectionKey,
                ),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blueGrey[50],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.history_edu,
                    color: color.withOpacity(0.8),
                    size: 20,
                  ),
                ),
                title: Text(
                  title.isEmpty ? sourceLabel : title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.cairo(
                    fontWeight: FontWeight.w800,
                    fontSize: 12.5,
                    color: AppColors.primaryDeepTeal,
                    height: 1.2,
                  ),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _pill(text: sourceLabel),
                      Text(
                        dateText,
                        style: GoogleFonts.cairo(
                          fontSize: 11,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _pill({required String text}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.secondaryOrange.withOpacity(0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: AppColors.secondaryOrange.withOpacity(0.25),
        ),
      ),
      child: Text(
        text,
        style: GoogleFonts.cairo(
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          color: AppColors.secondaryOrange,
          height: 1.1,
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.cairo(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Future<void> _openPreview(
    BuildContext context,
    String docId,
    String title,
    String body,
    String sectionKey,
  ) async {
    final ref = FirebaseFirestore.instance.collection('money').doc(docId);
    final isMod = await _isModerator();
    title = _cleanText(title);

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.98,
          expand: false,
          builder: (_, controller) => Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  controller: controller,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      Text(
                        title,
                        style: GoogleFonts.cairo(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primaryDeepTeal,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Divider(thickness: 1, color: Color(0xFFEEEEEE)),
                      const SizedBox(height: 15),
                      _buildRichContent(body),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
              if (isMod)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      )
                    ],
                    border:
                        const Border(top: BorderSide(color: Color(0xFFEEEEEE))),
                  ),
                  child: AdminInlineControls(
                    show: isMod,
                    docRef: ref,
                    sectionKey: sectionKey,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _docIdFor(_EconomyFormat type) {
    switch (type) {
      case _EconomyFormat.shortNews:
        return 'short_news';
      case _EconomyFormat.mediumAnalysis:
        return 'medium_analysis';
      case _EconomyFormat.deepDive:
        return 'deep_dive';
    }
  }

  String _sectionKeyFor(_EconomyFormat type) => 'money';

  Future<bool> _isModerator() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final role = (snap.data() ?? {})['role']?.toString().trim();
    return role == 'admin' || role == 'moderator';
  }
}

enum _EconomyFormat { shortNews, mediumAnalysis, deepDive }
