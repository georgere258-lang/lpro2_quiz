// PATH: lib/presentation/screens/know_client_sections_screen.dart
// PURPOSE: Show all sections of "اعرف عميلك" as a 2-column grid
// NAVIGATION: KnowClientScreen → KnowClientSectionsScreen → KnowClientSectionTopicsScreen

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import 'know_client_section_topics_screen.dart';
import '../widgets/lpro_bottom_nav_bar.dart';
import 'main_wrapper.dart';

class KnowClientSectionsScreen extends StatelessWidget {
  const KnowClientSectionsScreen({super.key});

  // ✅ Section names + icons (matching content plan - NO "كل المواضيع")
  static const List<_SectionData> _sections = [
    _SectionData(name: 'أساسيات العميل', icon: Icons.person_outline_rounded),
    _SectionData(name: 'أنماط الشخصيات', icon: Icons.psychology_outlined),
    _SectionData(name: 'الدوافع والاحتياجات', icon: Icons.lightbulb_outline_rounded),
    _SectionData(name: 'الاعتراضات والردود', icon: Icons.question_answer_outlined),
    _SectionData(name: 'التفاوض', icon: Icons.handshake_outlined),
    _SectionData(name: 'إغلاق الصفقة', icon: Icons.check_circle_outline_rounded),
    _SectionData(name: 'متابعة وما بعد البيع', icon: Icons.support_agent_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFBF7),
      appBar: AppBar(
        backgroundColor: AppColors.primaryDeepTeal,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: Text(
          'أقسام اعرف عميلك',
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
        child: GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            childAspectRatio: 1.1,
          ),
          itemCount: _sections.length,
          itemBuilder: (context, index) {
            final section = _sections[index];
            return _SectionCard(
              sectionName: section.name,
              icon: section.icon,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        KnowClientSectionTopicsScreen(sectionName: section.name),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _SectionData {
  final String name;
  final IconData icon;

  const _SectionData({required this.name, required this.icon});
}

class _SectionCard extends StatelessWidget {
  final String sectionName;
  final IconData icon;
  final VoidCallback onTap;

  const _SectionCard({
    required this.sectionName,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.primaryDeepTeal.withValues(alpha: 0.12),
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.secondaryOrange.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 26,
                color: AppColors.secondaryOrange,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              sectionName,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.cairo(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                height: 1.3,
                color: AppColors.primaryDeepTeal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
