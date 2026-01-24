// PATH: lib/presentation/screens/know_client_section_topics_screen.dart
// PURPOSE: Show topics belonging to a specific section of "اعرف عميلك"
// NAVIGATION: KnowClientSectionsScreen → KnowClientSectionTopicsScreen → KnowClientArticlesScreen

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import 'know_client_articles_screen.dart';
import '../widgets/lpro_bottom_nav_bar.dart';
import 'main_wrapper.dart';

class KnowClientSectionTopicsScreen extends StatefulWidget {
  final String sectionName;

  const KnowClientSectionTopicsScreen({
    super.key,
    required this.sectionName,
  });

  @override
  State<KnowClientSectionTopicsScreen> createState() =>
      _KnowClientSectionTopicsScreenState();
}

class _KnowClientSectionTopicsScreenState
    extends State<KnowClientSectionTopicsScreen> {
  static const String _collectionName = 'know_your_client';

  // ✅ Admin determined by users/{uid}.role == 'admin'
  bool _isAdmin = false;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _roleSubscription;

  @override
  void initState() {
    super.initState();
    _listenRole();
  }

  @override
  void dispose() {
    _roleSubscription?.cancel();
    super.dispose();
  }

  void _listenRole() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    _roleSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .snapshots()
        .listen(
      (doc) {
        final data = doc.data();
        final role = (data?['role'] ?? '').toString().trim().toLowerCase();
        final isAdmin = (role == 'admin');
        if (mounted) {
          setState(() => _isAdmin = isAdmin);
        }
      },
      onError: (_) {},
    );
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
          widget.sectionName,
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
            final nowMs = DateTime.now().millisecondsSinceEpoch;

            // Filter topics by section (using tags) + visibility rules
            final topics = docs
                .map((d) => _TopicItem.fromDoc(d.id, d.data()))
                .where((e) {
              if (e.title.trim().isEmpty) return false;
              if (!e.tags.contains(widget.sectionName)) return false;

              // Scheduled visibility rule
              final isScheduledFuture =
                  (e.publishAtMs > 0 && e.publishAtMs > nowMs);

              if (!_isAdmin && isScheduledFuture) return false;

              return true;
            }).toList();

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
                final isScheduledFuture =
                    (topic.publishAtMs > 0 && topic.publishAtMs > nowMs);

                return _TopicCard(
                  title: topic.title,
                  isScheduled: _isAdmin && isScheduledFuture,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => KnowClientArticlesScreen(
                          docId: topic.id,
                          title: topic.title,
                        ),
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
  final bool isScheduled;
  final VoidCallback onTap;

  const _TopicCard({
    required this.title,
    required this.isScheduled,
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
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
                  if (isScheduled) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.secondaryOrange.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color:
                              AppColors.secondaryOrange.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Text(
                        "مجدول",
                        style: GoogleFonts.cairo(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: AppColors.secondaryOrange,
                        ),
                      ),
                    ),
                  ],
                ],
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
  final int publishAtMs;
  final List<String> tags;

  _TopicItem({
    required this.id,
    required this.title,
    required this.createdAtMs,
    required this.publishAtMs,
    required this.tags,
  });

  factory _TopicItem.fromDoc(String id, Map<String, dynamic> data) {
    final rawTags = data['tags'];
    final tags = <String>[];
    if (rawTags is List) {
      for (final t in rawTags) {
        final s = t.toString().trim();
        if (s.isNotEmpty) tags.add(s);
      }
    }

    int createdAtMs = 0;
    final ts = data['createdAt'];
    if (ts is Timestamp) createdAtMs = ts.millisecondsSinceEpoch;

    int publishAtMs = 0;
    final pub = data['publishAt'];
    if (pub is Timestamp) publishAtMs = pub.millisecondsSinceEpoch;

    return _TopicItem(
      id: id,
      title: (data['title'] ?? '').toString(),
      createdAtMs: createdAtMs,
      publishAtMs: publishAtMs,
      tags: tags,
    );
  }
}
