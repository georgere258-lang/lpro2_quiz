// PATH: lib/presentation/screens/fact_section_topics_screen.dart
// PURPOSE: Show topics belonging to a specific section
// NAVIGATION: FactSectionsScreen → FactSectionTopicsScreen → FactArticlesScreen

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import 'fact_articles_screen.dart';
import '../widgets/lpro_bottom_nav_bar.dart';
import 'main_wrapper.dart';

class FactSectionTopicsScreen extends StatelessWidget {
  final String sectionName;

  const FactSectionTopicsScreen({
    super.key,
    required this.sectionName,
  });

  static const String _collectionName = 'pro_insight';

  // ✅ Normalize tags to match the content plan sections
  String _normalizeTag(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return t;
    if (t == 'سيستم الشركة') return 'سيستم الشركات';
    return t;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFBF7),
      appBar: AppBar(
        backgroundColor: AppColors.primaryDeepTeal,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: Text(
          sectionName,
          style: GoogleFonts.cairo(fontWeight: FontWeight.w900, fontSize: 18),
        ),
      ),
      bottomNavigationBar: LProBottomNavBar(
        activeIndex: 0,
        onTap: (index) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (_) => MainWrapper(initialIndex: index),
            ),
            (route) => false,
          );
        },
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection(_collectionName)
              .where('isActive', isEqualTo: true)
              .snapshots(),
          builder: (context, snap) {
            if (snap.hasError) {
              return _centerMsg("حصل خطأ في تحميل المواضيع.");
            }
            if (!snap.hasData) {
              return const Center(
                child: SizedBox(
                  width: 34,
                  height: 34,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              );
            }

            final docs = snap.data!.docs;

            // Filter topics by section (using tags)
            final normalizedSection = _normalizeTag(sectionName);
            final topics = docs
                .map((d) => _TopicItem.fromDoc(d.id, d.data(), _normalizeTag))
                .where((e) =>
                    e.title.trim().isNotEmpty &&
                    e.tags.contains(normalizedSection))
                .toList();

            // Sort by createdAt descending (newest first)
            topics.sort((a, b) => b.createdAtMs.compareTo(a.createdAtMs));

            if (topics.isEmpty) {
              return _centerMsg("لا توجد مواضيع في هذا القسم الآن.");
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: topics.length,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                final topic = topics[index];
                return _TopicCard(
                  title: topic.title,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FactArticlesScreen(title: topic.title),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _centerMsg(String text) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: GoogleFonts.cairo(
            fontSize: 13,
            height: 1.7,
            fontWeight: FontWeight.w900,
            color: AppColors.primaryDeepTeal,
          ),
        ),
      ),
    );
  }
}

class _TopicCard extends StatelessWidget {
  final String title;
  final VoidCallback onTap;

  const _TopicCard({
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.primaryDeepTeal.withValues(alpha: 0.10),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryDeepTeal.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.secondaryOrange.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: AppColors.secondaryOrange,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                textAlign: TextAlign.right,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.cairo(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  height: 1.4,
                  color: AppColors.primaryDeepTeal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopicItem {
  final String id;
  final String title;
  final int createdAtMs;
  final List<String> tags;

  _TopicItem({
    required this.id,
    required this.title,
    required this.createdAtMs,
    required this.tags,
  });

  factory _TopicItem.fromDoc(
    String id,
    Map<String, dynamic> data,
    String Function(String raw) normalizeTag,
  ) {
    final rawTags = data['tags'];
    final tags = <String>[];
    if (rawTags is List) {
      for (final t in rawTags) {
        final s = normalizeTag(t.toString());
        if (s.trim().isNotEmpty) tags.add(s.trim());
      }
    }

    int createdAtMs = 0;
    final ts = data['createdAt'];
    if (ts is Timestamp) createdAtMs = ts.millisecondsSinceEpoch;

    return _TopicItem(
      id: id,
      title: (data['title'] ?? '').toString(),
      createdAtMs: createdAtMs,
      tags: tags,
    );
  }
}
