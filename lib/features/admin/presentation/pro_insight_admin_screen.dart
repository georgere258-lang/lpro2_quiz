import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/pro_insight_service.dart';
import '../../../core/data/models/pro_insight_model.dart';

class ProInsightAdminScreen extends StatelessWidget {
  ProInsightAdminScreen({super.key});

  final ProInsightService _service = ProInsightService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("إدارة: المعلومة بتفرق"),
        centerTitle: true,
        backgroundColor: AppColors.primaryDeepTeal,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.secondaryOrange,
        child: const Icon(Icons.add),
        onPressed: () => _openEditor(context),
      ),
      body: StreamBuilder<List<ProInsightModel>>(
        stream: _service.streamActiveInsights(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final items = snapshot.data!;
          if (items.isEmpty) {
            return const Center(child: Text("لا يوجد محتوى حالياً"));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              return _InsightAdminCard(
                item: items[index],
                onToggle: (v) => _service.toggleActive(items[index].id, v),
                onDelete: () => _service.deleteInsight(items[index].id),
              );
            },
          );
        },
      ),
    );
  }

  void _openEditor(BuildContext context) {
    final hook = TextEditingController();
    final mind = TextEditingController();
    final core = TextEditingController();
    final example = TextEditingController();
    final lock = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("إضافة معلومة جديدة"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              _field(hook, "Hook (جذب الانتباه)"),
              _field(mind, "Mind Reset"),
              _field(core, "Core Insight"),
              _field(example, "مثال واقعي (اختياري)"),
              _field(lock, "Mental Lock (الخلاصة)"),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("إلغاء"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondaryOrange,
            ),
            onPressed: () async {
              final model = ProInsightModel(
                id: '',
                hook: hook.text.trim(),
                mindReset: mind.text.trim(),
                coreInsight: core.text.trim(),
                realityExample: example.text.trim(),
                mentalLock: lock.text.trim(),
                isActive: true,
                createdAt: DateTime.now(),
              );

              await _service.addInsight(model);
              Navigator.pop(context);
            },
            child: const Text("نشر"),
          ),
        ],
      ),
    );
  }

  Widget _field(TextEditingController c, String hint) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: c,
        maxLines: 3,
        textAlign: TextAlign.right,
        decoration: InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}

/* =========================================================
   ADMIN CARD
========================================================= */

class _InsightAdminCard extends StatelessWidget {
  final ProInsightModel item;
  final ValueChanged<bool> onToggle;
  final VoidCallback onDelete;

  const _InsightAdminCard({
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
        borderRadius: BorderRadius.circular(18),
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
          Text(item.hook,
              style:
                  GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
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
