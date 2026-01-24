// PATH: lib/presentation/screens/fact_sections_screen.dart
// PURPOSE: Show all sections of "المعلومة بتفرق" as a list
// NAVIGATION: FactScreen → FactSectionsScreen → FactSectionTopicsScreen

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import 'fact_section_topics_screen.dart';

class FactSectionsScreen extends StatelessWidget {
  const FactSectionsScreen({super.key});

  // ✅ Section names (same as content plan)
  static const List<String> _sections = [
    'البداية الصح',
    'لغة العقارات',
    'سيستم السوق',
    'سيستم الشركات',
    'التعاقدات والإجراءات',
    'دراسة المشاريع',
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
          'أقسام المعلومة بتفرق',
          style: GoogleFonts.cairo(fontWeight: FontWeight.w900, fontSize: 18),
        ),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: _sections.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final sectionName = _sections[index];
            return _SectionCard(
              sectionName: sectionName,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        FactSectionTopicsScreen(sectionName: sectionName),
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

class _SectionCard extends StatelessWidget {
  final String sectionName;
  final VoidCallback onTap;

  const _SectionCard({
    required this.sectionName,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: AppColors.primaryDeepTeal.withValues(alpha: 0.10),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                sectionName,
                textAlign: TextAlign.right,
                style: GoogleFonts.cairo(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primaryDeepTeal,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.secondaryOrange.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: AppColors.secondaryOrange,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
