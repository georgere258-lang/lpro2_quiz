import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/data/models/admin_news_item.dart';
import '../../../core/services/admin_news_service.dart';

class AdminNewsManagementScreen extends StatelessWidget {
  AdminNewsManagementScreen({super.key});

  final AdminNewsService _service = AdminNewsService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("إدارة شريط الأخبار"),
        centerTitle: true,
        backgroundColor: AppColors.primaryDeepTeal,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.secondaryOrange,
        child: const Icon(Icons.add),
        onPressed: () {
          _openAddDialog(context);
        },
      ),
      body: StreamBuilder<List<AdminNewsItem>>(
        stream: _service.streamAllNews(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final items = snapshot.data ?? [];

          if (items.isEmpty) {
            return Center(
              child: Text(
                "لا توجد أخبار حالياً",
                style: GoogleFonts.cairo(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              return _NewsCard(
                item: items[index],
                onToggle: (value) =>
                    _service.toggleActive(items[index].id, value),
                onDelete: () => _service.deleteNews(items[index].id),
              );
            },
          );
        },
      ),
    );
  }

  void _openAddDialog(BuildContext context) {
    final TextEditingController arController = TextEditingController();
    final TextEditingController enController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("إضافة خبر جديد"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              _buildField(arController, "النص العربي"),
              const SizedBox(height: 12),
              _buildField(enController, "النص الإنجليزي"),
            ],
          ),
        ),
        actions: [
          TextButton(
            child: const Text("إلغاء"),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondaryOrange,
            ),
            child: const Text("نشر"),
            onPressed: () async {
              final item = AdminNewsItem(
                id: '',
                textAr: arController.text.trim(),
                textEn: enController.text.trim(),
                isActive: true,
                withNotification: false,
                priority: 0,
                createdAt: DateTime.now(),
              );

              await _service.addNews(item);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildField(TextEditingController controller, String hint) {
    return TextField(
      controller: controller,
      maxLines: 3,
      textAlign: TextAlign.right,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

/* =========================================================
   NEWS CARD
========================================================= */

class _NewsCard extends StatelessWidget {
  final AdminNewsItem item;
  final ValueChanged<bool> onToggle;
  final VoidCallback onDelete;

  const _NewsCard({
    required this.item,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.textAr,
            style: GoogleFonts.cairo(
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
          if (item.textEn.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              item.textEn,
              style: GoogleFonts.cairo(
                fontSize: 11,
                color: Colors.grey[700],
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Switch(
                value: item.isActive,
                activeThumbColor: AppColors.secondaryOrange,
                onChanged: onToggle,
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: onDelete,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
