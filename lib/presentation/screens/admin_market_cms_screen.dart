// PATH: lib/presentation/screens/admin_market_cms_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/market_content_cms_service.dart';

class AdminMarketCmsScreen extends StatefulWidget {
  final String sectionKey; // 'market_radar' | 'money_economy'
  const AdminMarketCmsScreen({super.key, required this.sectionKey});

  @override
  State<AdminMarketCmsScreen> createState() => _AdminMarketCmsScreenState();
}

class _AdminMarketCmsScreenState extends State<AdminMarketCmsScreen> {
  late final MarketContentCmsService _cms;

  @override
  void initState() {
    super.initState();
    _cms = MarketContentCmsService(FirebaseFirestore.instance);
  }

  String get _title => widget.sectionKey == 'market_radar'
      ? 'CMS — رادار السوق'
      : 'CMS — الاقتصاد والعقار';

  @override
  Widget build(BuildContext context) {
    final col = _cms.col(widget.sectionKey);

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppColors.primaryDeepTeal,
        foregroundColor: Colors.white,
        title:
            Text(_title, style: const TextStyle(fontWeight: FontWeight.w900)),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.secondaryOrange,
        foregroundColor: Colors.white,
        onPressed: () => _openCreate(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('رفع موضوع'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: col.orderBy('orderInSection').snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Text(
                'خطأ في التحميل\n${snap.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white),
              ),
            );
          }

          final docs = snap.data?.docs ?? const [];
          if (docs.isEmpty) {
            return const Center(
              child: Text(
                'لا يوجد مواضيع بعد.',
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 90),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final d = docs[i];
              final data = d.data();

              final title = (data['title'] ?? '').toString();
              final subtitle = (data['subtitle'] ?? '').toString();
              final typeKey = (data['typeKey'] ?? '').toString();
              final isActive = (data['isActive'] as bool?) ?? true;
              final isPinned = (data['isPinned'] as bool?) ?? false;

              return _ItemCard(
                title: title,
                subtitle: subtitle,
                typeKey: typeKey,
                isActive: isActive,
                isPinned: isPinned,
                onToggleActive: () => _cms.toggleActive(
                    sectionKey: widget.sectionKey,
                    docId: d.id,
                    newValue: !isActive),
                onTogglePinned: () => _cms.togglePinned(
                    sectionKey: widget.sectionKey,
                    docId: d.id,
                    newValue: !isPinned),
                onEdit: () => _openEdit(context, d.id, data),
                onDelete: () => _confirmDelete(context, d.id),
                onUp: () => _cms.move(
                    sectionKey: widget.sectionKey, docId: d.id, up: true),
                onDown: () => _cms.move(
                    sectionKey: widget.sectionKey, docId: d.id, up: false),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, String docId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text('هل أنت متأكد؟ لا يمكن التراجع.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB00020),
                foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (ok == true) {
      await _cms.deleteItem(sectionKey: widget.sectionKey, docId: docId);
    }
  }

  Future<void> _openCreate(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (_) => _EditorSheet(
        title: 'رفع موضوع',
        onSubmit: (v) async {
          await _cms.createItem(
            sectionKey: widget.sectionKey,
            title: v.title,
            subtitle: v.subtitle,
            typeKey: v.typeKey,
            payload: v.payload,
            isActive: v.isActive,
            isPinned: v.isPinned,
          );
        },
      ),
    );
  }

  Future<void> _openEdit(
      BuildContext context, String docId, Map<String, dynamic> existing) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (_) => _EditorSheet(
        title: 'تعديل موضوع',
        initial: _EditorValue.fromDoc(existing),
        onSubmit: (v) async {
          await _cms
              .updateItem(sectionKey: widget.sectionKey, docId: docId, patch: {
            'title': v.title,
            'subtitle': v.subtitle,
            'typeKey': v.typeKey,
            'payload': v.payload,
            'isActive': v.isActive,
            'isPinned': v.isPinned,
          });
        },
      ),
    );
  }
}

// ---------------- UI ----------------

class _ItemCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String typeKey;
  final bool isActive;
  final bool isPinned;

  final VoidCallback onTogglePinned;
  final VoidCallback onToggleActive;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onUp;
  final VoidCallback onDown;

  const _ItemCard({
    required this.title,
    required this.subtitle,
    required this.typeKey,
    required this.isActive,
    required this.isPinned,
    required this.onTogglePinned,
    required this.onToggleActive,
    required this.onEdit,
    required this.onDelete,
    required this.onUp,
    required this.onDown,
  });

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.secondaryOrange;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.94),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primaryDeepTeal.withOpacity(0.10)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Badge(
                  text: typeKey.isEmpty ? 'type' : typeKey,
                  color: AppColors.primaryDeepTeal),
              const SizedBox(width: 8),
              if (isPinned) _Badge(text: 'Pinned', color: accent),
              const Spacer(),
              _IconPill(
                icon: Icons.arrow_upward_rounded,
                onTap: onUp,
              ),
              const SizedBox(width: 8),
              _IconPill(
                icon: Icons.arrow_downward_rounded,
                onTap: onDown,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            title.isEmpty ? '(بدون عنوان)' : title,
            style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 16,
                color: Colors.black87),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: Colors.black.withOpacity(0.55)),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _PillBtn(
                label: isActive ? 'ظاهر ✓' : 'مخفي',
                icon: isActive
                    ? Icons.visibility_rounded
                    : Icons.visibility_off_rounded,
                onTap: onToggleActive,
              ),
              _PillBtn(
                label: isPinned ? 'مميز ✓' : 'مميز',
                icon: Icons.star_rounded,
                onTap: onTogglePinned,
              ),
              _PillBtn(
                label: 'تعديل',
                icon: Icons.edit_rounded,
                onTap: onEdit,
              ),
              _PillBtn(
                label: 'حذف',
                icon: Icons.delete_rounded,
                danger: true,
                onTap: onDelete,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final Color color;
  const _Badge({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.20)),
      ),
      child: Text(
        text,
        style:
            TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 12),
      ),
    );
  }
}

class _IconPill extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _IconPill({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(999),
          border:
              Border.all(color: AppColors.primaryDeepTeal.withOpacity(0.10)),
        ),
        child: Icon(icon, size: 18, color: AppColors.primaryDeepTeal),
      ),
    );
  }
}

class _PillBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool danger;
  final VoidCallback onTap;

  const _PillBtn({
    required this.label,
    required this.icon,
    required this.onTap,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final bg = danger ? const Color(0xFFFFE6E6) : Colors.white;
    final fg = danger ? const Color(0xFFB00020) : AppColors.primaryDeepTeal;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: fg.withOpacity(0.12)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: fg),
            const SizedBox(width: 8),
            Text(label,
                style: TextStyle(
                    color: fg, fontWeight: FontWeight.w900, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

// ---------------- Editor Sheet ----------------

class _EditorValue {
  final String title;
  final String subtitle;
  final String typeKey;
  final bool isActive;
  final bool isPinned;

  // payload: حط أي Structure انت عايزه (أقسام/عناوين/نقاط..)
  // حالياً: نخليه بسيط جدًا علشان الرفع يشتغل فوراً
  final Map<String, dynamic> payload;

  const _EditorValue({
    required this.title,
    required this.subtitle,
    required this.typeKey,
    required this.isActive,
    required this.isPinned,
    required this.payload,
  });

  static _EditorValue fromDoc(Map<String, dynamic> d) {
    return _EditorValue(
      title: (d['title'] ?? '').toString(),
      subtitle: (d['subtitle'] ?? '').toString(),
      typeKey: (d['typeKey'] ?? '').toString(),
      isActive: (d['isActive'] as bool?) ?? true,
      isPinned: (d['isPinned'] as bool?) ?? false,
      payload: (d['payload'] as Map?)?.cast<String, dynamic>() ??
          <String, dynamic>{},
    );
  }
}

class _EditorSheet extends StatefulWidget {
  final String title;
  final _EditorValue? initial;
  final Future<void> Function(_EditorValue v) onSubmit;

  const _EditorSheet(
      {required this.title, required this.onSubmit, this.initial});

  @override
  State<_EditorSheet> createState() => _EditorSheetState();
}

class _EditorSheetState extends State<_EditorSheet> {
  late final TextEditingController _title;
  late final TextEditingController _subtitle;
  late final TextEditingController _typeKey;
  late final TextEditingController _body; // نص حر مؤقتًا داخل payload

  bool _isActive = true;
  bool _isPinned = false;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final init = widget.initial;
    _title = TextEditingController(text: init?.title ?? '');
    _subtitle = TextEditingController(text: init?.subtitle ?? '');
    _typeKey = TextEditingController(text: init?.typeKey ?? 'quick');
    _body =
        TextEditingController(text: (init?.payload['body'] ?? '').toString());
    _isActive = init?.isActive ?? true;
    _isPinned = init?.isPinned ?? false;
  }

  @override
  void dispose() {
    _title.dispose();
    _subtitle.dispose();
    _typeKey.dispose();
    _body.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 46,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(widget.title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w900, fontSize: 18)),
              const SizedBox(height: 14),
              _Field(label: 'العنوان', controller: _title),
              const SizedBox(height: 10),
              _Field(label: 'الوصف (سطر/سطرين)', controller: _subtitle),
              const SizedBox(height: 10),
              _Field(
                  label: 'Type Key (quick/medium/deep/case/zone)',
                  controller: _typeKey),
              const SizedBox(height: 10),
              _Field(
                label: 'Body (محتوى تجريبي الآن)',
                controller: _body,
                maxLines: 6,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: SwitchListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      value: _isActive,
                      onChanged: (v) => setState(() => _isActive = v),
                      title: const Text('ظاهر',
                          style: TextStyle(fontWeight: FontWeight.w900)),
                    ),
                  ),
                  Expanded(
                    child: SwitchListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      value: _isPinned,
                      onChanged: (v) => setState(() => _isPinned = v),
                      title: const Text('مميز',
                          style: TextStyle(fontWeight: FontWeight.w900)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondaryOrange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.check_rounded),
                  label: Text(_saving ? 'جارٍ الحفظ...' : 'حفظ',
                      style: const TextStyle(fontWeight: FontWeight.w900)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    final title = _title.text.trim();
    if (title.isEmpty) return;

    setState(() => _saving = true);

    final v = _EditorValue(
      title: title,
      subtitle: _subtitle.text.trim(),
      typeKey: _typeKey.text.trim().isEmpty ? 'quick' : _typeKey.text.trim(),
      isActive: _isActive,
      isPinned: _isPinned,
      payload: {
        'body': _body.text.trim(),
      },
    );

    try {
      await widget.onSubmit(v);
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _Field extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final int maxLines;

  const _Field({
    required this.label,
    required this.controller,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.black.withOpacity(0.04),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }
}
