// PATH: lib/features/money/models/money_item.dart
// STATUS: FIXED — Analyzer clean, type-safe Firestore parsing

class MoneyItem {
  final String id;
  final String title;
  final String body;
  final bool isFeatured;
  final bool isImportant;
  final Map<String, dynamic> control;

  MoneyItem({
    required this.id,
    required this.title,
    required this.body,
    required this.isFeatured,
    required this.isImportant,
    required this.control,
  });

  factory MoneyItem.fromFirestore(
    String id,
    Map<String, dynamic> data,
  ) {
    final title = (data['title'] ?? '').toString();
    final body = (data['body'] ?? '').toString();

    if (title.trim().length < 3) {
      throw Exception('عنوان غير صالح (أقل من 3 أحرف)');
    }

    if (body.trim().length < 20) {
      throw Exception('المحتوى قصير جدًا (أقل من 20 حرف)');
    }

    return MoneyItem(
      id: id,
      title: title,
      body: body,
      isFeatured: (data['isFeatured'] as bool?) ?? false,
      isImportant: (data['isImportant'] as bool?) ?? false,

      // ✅ FIX: type-safe map parsing
      control: Map<String, dynamic>.from(
        data['control'] as Map? ?? {},
      ),
    );
  }
}
