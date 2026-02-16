// PATH: lib/core/constants/content_taxonomy.dart
// STATUS: FULL FILE — Canonical Content Taxonomy + Upload Schemas (v1)
//
// الهدف: توثيق ثابت داخل الكود لأسماء الـ Collections + تقسيم الأقسام + Schema الرسمي للرفع
// بحيث أي حد يشتغل على التطبيق يعرف (بدون تخمين) تقسيم المحتوى وصيغ الرفع الفردي/الجماعي.
//
// ملاحظة مهمة:
// - هذا الملف "مرجعي" فقط: لا يعتمد عليه UI مباشرة إلا لو قررت.
// - لا يضيف/يغير أي منطق Firestore، فقط يوحد المعرفة داخل المشروع.

class ContentTaxonomy {
  ContentTaxonomy._();

  // ─────────────────────────────────────────────────────────────
  // Firestore Collections (Canonical)
  // ─────────────────────────────────────────────────────────────
  static const String colProInsight = 'pro_insight';
  static const String colKnowYourClient = 'know_your_client';
  static const String colQuizzes = 'quizzes';
  static const String colMoney = 'money';
  static const String colMarketRadar = 'market_radar';

  // ─────────────────────────────────────────────────────────────
  // Pro Insight (المعلومة بتفرق) — Tags-based Sections (6)
  // ─────────────────────────────────────────────────────────────
  static const List<String> proInsightSections = <String>[
    'البداية الصح',
    'لغة العقارات',
    'سيستم السوق',
    'سيستم الشركات',
    'التعاقدات والإجراءات',
    'دراسة المشاريع',
  ];

  // Schema: pro_insight document
  // ✅ ملاحظة: المعلومة بتفرق شغالة بـ tags (List<String>) وليس sectionKey.
  static const ContentSchema proInsightSchema = ContentSchema(
    collection: colProInsight,
    description:
        'Pro Insight / المعلومة بتفرق — article-style content with tags',
    required: <FieldSpec>[
      FieldSpec('title', FieldType.string),
      FieldSpec('hook', FieldType.string),
      FieldSpec('reset', FieldType.string),
      FieldSpec('core', FieldType.string),
      FieldSpec('example', FieldType.string),
      FieldSpec('lock', FieldType.string),
      FieldSpec('tags', FieldType.stringList),
      FieldSpec('isActive', FieldType.boolean),
      FieldSpec('createdAt', FieldType.timestamp),
      FieldSpec('updatedAt', FieldType.timestamp),
    ],
    optional: <FieldSpec>[
      FieldSpec('article', FieldType.string),
      FieldSpec('level', FieldType.number),
      FieldSpec('isFeatured', FieldType.boolean),
      FieldSpec('featuredOrder', FieldType.number),
    ],
    rules: <String>[
      'tags لازم تحتوي قسم واحد على الأقل من proInsightSections',
      'يفضل tag واحد أساسي (Section) لكل موضوع لتسهيل الفلترة',
    ],
    examples: <String>[
      'رفع مفرد: Map بنفس الحقول المطلوبة',
      'رفع جماعي: List<Map> (Array) كل عنصر وثيقة كاملة',
    ],
  );

  // ─────────────────────────────────────────────────────────────
  // Know Your Client (اعرف عميلك) — sectionKey-based Sections (7)
  // ─────────────────────────────────────────────────────────────
  static const Map<String, String> kycSectionKeyByTag = <String, String>{
    'أساسيات العميل': 'client_basics',
    'أنماط الشخصيات': 'personality_types',
    'الدوافع والاحتياجات': 'motives_needs',
    'الاعتراضات والردود': 'objections_responses',
    'التفاوض': 'negotiation',
    'إغلاق الصفقة': 'closing',
    'متابعة وما بعد البيع': 'after_sale',
  };

  static List<String> get kycTags =>
      kycSectionKeyByTag.keys.toList(growable: false);
  static List<String> get kycSectionKeys =>
      kycSectionKeyByTag.values.toList(growable: false);

  // Schema: know_your_client document
  // ✅ ملاحظة: اعرف عميلك شغال بـ sectionKey (String) داخل الوثيقة.
  static const ContentSchema knowYourClientSchema = ContentSchema(
    collection: colKnowYourClient,
    description:
        'Know Your Client / اعرف عميلك — article-style content with sectionKey',
    required: <FieldSpec>[
      FieldSpec('title', FieldType.string),
      FieldSpec('hook', FieldType.string),
      FieldSpec('reset', FieldType.string),
      FieldSpec('core', FieldType.string),
      FieldSpec('example', FieldType.string),
      FieldSpec('lock', FieldType.string),
      FieldSpec('sectionKey', FieldType.string),
      FieldSpec('isActive', FieldType.boolean),
      FieldSpec('createdAt', FieldType.timestamp),
      FieldSpec('updatedAt', FieldType.timestamp),
    ],
    optional: <FieldSpec>[
      FieldSpec('article', FieldType.string),
      FieldSpec('orderInSection', FieldType.number),
      FieldSpec('isFeatured', FieldType.boolean),
      FieldSpec('featuredOrder', FieldType.number),
    ],
    rules: <String>[
      'sectionKey لازم يكون واحد من kycSectionKeys',
      'يفضل وجود orderInSection للترتيب داخل القسم (اختياري)',
    ],
    examples: <String>[
      'رفع مفرد: Map بنفس الحقول المطلوبة',
      'رفع جماعي: List<Map> (Array) كل عنصر وثيقة كاملة',
    ],
  );

  // ─────────────────────────────────────────────────────────────
  // Quizzes (الدوريات) — category-based Leagues + difficulty 1..5
  // ─────────────────────────────────────────────────────────────
  static const List<String> quizLeagues = <String>[
    'دوري النجوم',
    'دوري المحترفين',
  ];

  static const int quizDifficultyMin = 1;
  static const int quizDifficultyMax = 5;

  // Schema: quizzes question document
  static const ContentSchema quizzesSchema = ContentSchema(
    collection: colQuizzes,
    description: 'Quizzes / الدوريات — question bank (category + difficulty)',
    required: <FieldSpec>[
      FieldSpec('category', FieldType.string),
      FieldSpec('question', FieldType.string),
      FieldSpec('options', FieldType.stringList),
      FieldSpec('correctAnswer', FieldType.number),
      FieldSpec('difficulty', FieldType.number),
      FieldSpec('isActive', FieldType.boolean),
      FieldSpec('createdAt', FieldType.timestamp),
    ],
    optional: <FieldSpec>[
      FieldSpec('questionKey', FieldType.string),
    ],
    rules: <String>[
      'category لازم تكون واحدة من quizLeagues',
      'options لازم تكون 4 عناصر بالظبط',
      'correctAnswer لازم يكون 0..3 (Zero-based Index)',
      'difficulty لازم يكون بين 1..5',
    ],
    examples: <String>[
      'رفع مفرد: Map بنفس الحقول المطلوبة',
      'رفع جماعي: List<Map> (Array) كل عنصر وثيقة كاملة',
    ],
  );

  // ─────────────────────────────────────────────────────────────
  // Upload Payload Helpers (Static builders)
  // ─────────────────────────────────────────────────────────────

  /// ✅ صيغة رفع سؤال مفرد (Map)
  /// ملاحظة: createdAt يُفضل serverTimestamp من الـ UI/Repository.
  static Map<String, dynamic> buildQuizQuestion({
    required String category,
    required String question,
    required List<String> options,
    required int correctAnswer,
    required int difficulty,
    required bool isActive,
    String? questionKey,
    dynamic createdAt, // Timestamp / FieldValue.serverTimestamp()
  }) {
    return <String, dynamic>{
      'category': category,
      'question': question,
      'options': options,
      'correctAnswer': correctAnswer,
      'difficulty': difficulty,
      'isActive': isActive,
      if (questionKey != null) 'questionKey': questionKey,
      'createdAt': createdAt,
    };
  }

  /// ✅ صيغة رفع موضوع مفرد (Pro Insight) — tags-based
  static Map<String, dynamic> buildProInsightItem({
    required String title,
    required String hook,
    required String reset,
    required String core,
    required String example,
    required String lock,
    required List<String> tags,
    required bool isActive,
    dynamic createdAt, // Timestamp / FieldValue.serverTimestamp()
    dynamic updatedAt, // Timestamp / FieldValue.serverTimestamp()
    String? article,
    num? level,
    bool? isFeatured,
    num? featuredOrder,
  }) {
    return <String, dynamic>{
      'title': title,
      'hook': hook,
      'reset': reset,
      'core': core,
      'example': example,
      'lock': lock,
      'tags': tags,
      'isActive': isActive,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      if (article != null) 'article': article,
      if (level != null) 'level': level,
      if (isFeatured != null) 'isFeatured': isFeatured,
      if (featuredOrder != null) 'featuredOrder': featuredOrder,
    };
  }

  /// ✅ صيغة رفع موضوع مفرد (Know Your Client) — sectionKey-based
  static Map<String, dynamic> buildKycItem({
    required String title,
    required String hook,
    required String reset,
    required String core,
    required String example,
    required String lock,
    required String sectionKey,
    required bool isActive,
    dynamic createdAt, // Timestamp / FieldValue.serverTimestamp()
    dynamic updatedAt, // Timestamp / FieldValue.serverTimestamp()
    String? article,
    num? orderInSection,
    bool? isFeatured,
    num? featuredOrder,
  }) {
    return <String, dynamic>{
      'title': title,
      'hook': hook,
      'reset': reset,
      'core': core,
      'example': example,
      'lock': lock,
      'sectionKey': sectionKey,
      'isActive': isActive,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      if (article != null) 'article': article,
      if (orderInSection != null) 'orderInSection': orderInSection,
      if (isFeatured != null) 'isFeatured': isFeatured,
      if (featuredOrder != null) 'featuredOrder': featuredOrder,
    };
  }
}

// ─────────────────────────────────────────────────────────────
// Models (Pure metadata)
// ─────────────────────────────────────────────────────────────

enum FieldType { string, number, boolean, timestamp, stringList }

class FieldSpec {
  final String key;
  final FieldType type;
  const FieldSpec(this.key, this.type);
}

class ContentSchema {
  final String collection;
  final String description;
  final List<FieldSpec> required;
  final List<FieldSpec> optional;
  final List<String> rules;
  final List<String> examples;

  const ContentSchema({
    required this.collection,
    required this.description,
    required this.required,
    required this.optional,
    required this.rules,
    required this.examples,
  });
}
