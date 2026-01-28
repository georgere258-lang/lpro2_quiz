// PATH: lib/core/utils/seed_know_your_client_v2.dart
// PURPOSE: Seed Premium Know Your Client topics with a "Run Once" safety lock.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/firestore_paths.dart';

class SeedKnowYourClientV2 {
  // ✅ رقم النسخة لضمان الرفع مرة واحدة لكل تحديث
  static const int seedVersion = 2;
  static const String _prefKey = 'has_seeded_kyc_v2';

  static const String _col =
      FirestorePaths.knowYourClient; // 'know_your_client'

  /// الوظيفة الرئيسية: رفع البيانات مع فحص الأمان
  static Future<void> run() async {
    final prefs = await SharedPreferences.getInstance();

    // 1. الفحص: هل تم الرفع مسبقاً؟
    final bool alreadySeeded = prefs.getBool(_prefKey) ?? false;
    if (alreadySeeded) {
      print(
          "KYC Seed: Data already seeded for version $seedVersion. Skipping...");
      return;
    }

    print("KYC Seed: Starting data upload for version $seedVersion...");

    final colRef = FirebaseFirestore.instance.collection(_col);
    final batch = FirebaseFirestore.instance.batch();

    // 2. قائمة المواضيع "البريميوم" (يمكنك إضافة أي مواضيع جديدة هنا مستقبلاً)
    final items = <Map<String, dynamic>>[
      _topic(
        docId: 'kyc_status_psychology', // ID ثابت لمنع التكرار
        sectionKey: 'client_basics',
        tagArabic: 'أساسيات العميل',
        title: 'سيكولوجية "المكانة" عند نخبة المجتمع',
        hook: 'الأثرياء لا يشترون جدرانًا، بل يشترون تذكرة دخول لنادٍ مغلق.',
        reset:
            'خرافة: العميل الثري يبحث دائماً عن السعر الأرخص. الحقيقة: هو يبحث عن القيمة التي ترفع من قدره أمام أقرانه.',
        core: 'بع له "المجتمع" (Community) قبل أن تبيع له "الوحدة".',
        example:
            'عميل يرفض فيلا بمساحة أكبر في منطقة هادئة، ويختار توين هاوس أصغر داخل "كمبوند" يضم نخبة من رجال الأعمال.',
        lock:
            'استخدم عبارة: "هذا المشروع يضم صفوة المجتمع في مصر، وستكون جاراً لأسماء مرموقة".',
        orderInSection: 1,
      ),
      _topic(
        docId: 'kyc_disc_con_profile',
        sectionKey: 'personality_types',
        tagArabic: 'أنماط الشخصيات',
        title: 'العميل "المتوجس": فك شفرة التحليل السلوكي',
        hook:
            'العميل الذي يسأل عن أدق التفاصيل التقنية ليس "متعباً"، بل هو شخص "C" في نموذج DISC.',
        reset: 'خطأ: محاولة إقناع العميل المحلل بالعاطفة أو بجمال المنظر فقط.',
        core: 'الثقة مع المحلل تبنى بالوثائق، وليس بالوعود الشفهية.',
        example:
            'مستثمر في الشيخ زايد يطلب الاطلاع على قرار التخصيص، وتراخيص البناء قبل مناقشة السعر.',
        lock:
            'جهز "فولدر" يحتوي على كل الأوراق القانونية والمخططات المعتمدة قبل موعد المقابلة.',
        orderInSection: 1,
      ),
      // ... يمكنك إضافة باقي الـ 7 مواضيع هنا بنفس النسق
    ];

    // 3. تجهيز الرفع الجماعي
    for (final item in items) {
      final docId = item['docId'] as String;
      final docRef = colRef.doc(docId);
      batch.set(docRef, item, SetOptions(merge: true));
    }

    // 4. التنفيذ النهائي وحفظ "علامة النجاح"
    try {
      await batch.commit();
      await prefs.setBool(
          _prefKey, true); // ✅ قفل الأمان: لن يعمل الكود مرة أخرى
      print("KYC Seed: Success! Version $seedVersion uploaded and locked.");
    } catch (e) {
      print("KYC Seed Error: $e");
    }
  }

  static Map<String, dynamic> _topic({
    required String docId,
    required String sectionKey,
    required String tagArabic,
    required String title,
    required String hook,
    required String reset,
    required String core,
    required String example,
    required String lock,
    required int orderInSection,
  }) {
    return {
      'docId': docId,
      'title': title,
      'hook': hook,
      'reset': reset,
      'core': core,
      'example': example,
      'lock': lock,
      'tags': [tagArabic],
      'sectionKey': sectionKey,
      'orderInSection': orderInSection,
      'seedVersion': seedVersion,
      'isActive': true,
      'isFeatured': false, // يمكن تعديلها يدوياً لاحقاً
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
