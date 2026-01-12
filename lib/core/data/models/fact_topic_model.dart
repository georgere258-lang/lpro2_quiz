class FactTopicModel {
  final String id;
  final String title;
  final String description;
  final String icon;
  final int order;
  final bool isActive;

  FactTopicModel({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.order,
    required this.isActive,
  });

  factory FactTopicModel.fromMap(Map<String, dynamic> data, String id) {
    return FactTopicModel(
      id: id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      icon: data['icon'] ?? '',
      order: data['order'] ?? 0,
      isActive: data['isActive'] ?? true,
    );
  }
}
