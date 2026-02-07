class HomeProCardData {
  final String type; // 'text' | 'image'
  final String? text;
  final String? imageUrl;

  HomeProCardData({
    required this.type,
    this.text,
    this.imageUrl,
  });

  factory HomeProCardData.fromMap(Map<String, dynamic> data) {
    return HomeProCardData(
      type: (data['type'] ?? 'text').toString(),
      text: data['text']?.toString(),
      imageUrl: data['imageUrl']?.toString(),
    );
  }

  bool get isText => type == 'text';
  bool get isImage => type == 'image';
}
