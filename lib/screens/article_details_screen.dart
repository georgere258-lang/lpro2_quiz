import 'package:flutter/material.dart';

class ArticleDetailsScreen extends StatelessWidget {
  final String title;
  final String content;

  const ArticleDetailsScreen({
    super.key, 
    required this.title, 
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: const Color(0xFF102A43),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF102A43),
              ),
            ),
            const SizedBox(height: 10),
            const Divider(),
            const SizedBox(height: 15),
            Text(
              content,
              style: const TextStyle(
                fontSize: 18,
                height: 1.8,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}