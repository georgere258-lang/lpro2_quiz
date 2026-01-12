class FactArticle {
  final String id;
  final String title;
  final String hook;
  final String reset;
  final String insight;
  final String example;
  final String lock;
  final String? category; // 👈 اختياري

  const FactArticle({
    required this.id,
    required this.title,
    required this.hook,
    required this.reset,
    required this.insight,
    required this.example,
    required this.lock,
    this.category,
  });
}
