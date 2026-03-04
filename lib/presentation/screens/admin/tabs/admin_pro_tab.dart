// PATH: lib/presentation/screens/admin/tabs/admin_pro_tab.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/app_config_service.dart';
import '../../../../features/pro_card/models/pro_card_banner.dart';
import '../../../../features/pro_card/repositories/pro_card_repository.dart';
import '../widgets/admin_shared_widgets.dart';

class AdminProTab extends StatelessWidget {
  final ProCardRepository proCardRepo;
  final AppConfigService configService;
  final void Function(bool) setSaving;
  final void Function(String) snack;

  const AdminProTab({
    super.key,
    required this.proCardRepo,
    required this.configService,
    required this.setSaving,
    required this.snack,
  });

  static const String _homeProCardCollection = 'home_pro_card';
  static const String _homeProCardDocId = 'current';

  Future<Map<String, dynamic>> _loadPushMeta() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection(_homeProCardCollection)
          .doc(_homeProCardDocId)
          .get();
      final data = snap.data();
      if (data == null) return <String, dynamic>{};
      return data;
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  Future<void> _savePushMeta({
    required bool notify,
    required String pushTitle,
    required String pushBody,
  }) async {
    await FirebaseFirestore.instance
        .collection(_homeProCardCollection)
        .doc(_homeProCardDocId)
        .set(
      {
        'notify': notify,
        if (pushTitle.trim().isNotEmpty) 'pushTitle': pushTitle.trim(),
        if (pushBody.trim().isNotEmpty) 'pushBody': pushBody.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  String _defaultPushTitle() => 'معلومة Pro';

  String _defaultPushBodyForType(ProCardContentType type) {
    if (type == ProCardContentType.image) return 'تم نشر صورة جديدة';
    return 'تم نشر محتوى جديد';
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              adminCenterBtn(
                onPressed: () => _openProEditor(context),
                bg: AppColors.primaryDeepTeal,
                child: adminBtnText('تعديل / إنشاء الرسالة', size: 16),
              ),
              const SizedBox(height: 16),
              StreamBuilder<ProCardBanner?>(
                stream: proCardRepo.watchCurrent(),
                builder: (ctx, snap) {
                  if (!snap.hasData || snap.data == null) {
                    return Center(
                      child: snap.connectionState == ConnectionState.waiting
                          ? const CircularProgressIndicator()
                          : Text('لا توجد رسالة.', style: GoogleFonts.cairo()),
                    );
                  }
                  final banner = snap.data!;
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.primaryDeepTeal.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        adminStatusBadge(banner.isActive),
                        const SizedBox(height: 10),
                        if (banner.isImage)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'نوع المحتوى: صورة',
                                style: GoogleFonts.cairo(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 10),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: AspectRatio(
                                  aspectRatio: 16 / 9,
                                  child: Image.network(
                                    banner.imageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      color: Colors.grey[100],
                                      alignment: Alignment.center,
                                      child: Text(
                                        'فشل تحميل الصورة',
                                        style: GoogleFonts.cairo(
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          )
                        else
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'نوع المحتوى: نص',
                                style: GoogleFonts.cairo(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                banner.text,
                                style: GoogleFonts.cairo(
                                  fontSize: 14,
                                  height: 1.6,
                                ),
                              ),
                            ],
                          ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            adminSmallBtn(
                              banner.isActive ? 'إخفاء' : 'إظهار',
                              Icons.visibility,
                              () async {
                                setSaving(true);
                                try {
                                  await proCardRepo
                                      .toggleActive(!banner.isActive);
                                  snack(banner.isActive
                                      ? 'تم الإخفاء ✅'
                                      : 'تم الإظهار ✅');
                                } catch (_) {
                                  snack('فشل');
                                } finally {
                                  setSaving(false);
                                }
                              },
                            ),
                            const SizedBox(width: 10),
                            adminSmallBtn(
                              'تعديل',
                              Icons.edit,
                              () => _openProEditorWithBanner(context, banner),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              _buildAppConfigSection(context),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openProEditor(BuildContext context) async {
    final textC = TextEditingController();
    final imageUrlC = TextEditingController();
    final pushTitleC = TextEditingController();
    final pushBodyC = TextEditingController();

    bool notify = false;
    bool isActive = true;
    ProCardContentType type = ProCardContentType.text;

    final meta = await _loadPushMeta();
    pushTitleC.text = (meta['pushTitle'] ?? '').toString();
    pushBodyC.text = (meta['pushBody'] ?? '').toString();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (context, setLocal) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 12,
          ),
          child: Column(
            key: const ValueKey('pro_editor_new'),
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'رسالة Pro الحية',
                style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<ProCardContentType>(
                      value: ProCardContentType.text,
                      groupValue: type,
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (v) => setLocal(() {
                        type = v!;
                        if (pushBodyC.text.trim().isEmpty) {
                          pushBodyC.text = _defaultPushBodyForType(type);
                        }
                      }),
                      title: Text('نص', style: GoogleFonts.cairo(fontSize: 12)),
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<ProCardContentType>(
                      value: ProCardContentType.image,
                      groupValue: type,
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (v) => setLocal(() {
                        type = v!;
                        if (pushBodyC.text.trim().isEmpty) {
                          pushBodyC.text = _defaultPushBodyForType(type);
                        }
                      }),
                      title:
                          Text('صورة', style: GoogleFonts.cairo(fontSize: 12)),
                    ),
                  ),
                ],
              ),
              if (type == ProCardContentType.text)
                adminTextField(textC, 'نص الرسالة...', maxLines: 4)
              else
                adminTextField(imageUrlC, 'رابط الصورة (https://)...',
                    maxLines: 2),
              SwitchListTile(
                value: isActive,
                onChanged: (v) => setLocal(() => isActive = v),
                title: Text('ظاهر', style: GoogleFonts.cairo(fontSize: 12)),
              ),
              const SizedBox(height: 6),
              SwitchListTile(
                value: notify,
                onChanged: (v) => setLocal(() => notify = v),
                title:
                    Text('إرسال إشعار', style: GoogleFonts.cairo(fontSize: 12)),
              ),
              adminTextField(pushTitleC, 'عنوان الإشعار (اختياري)',
                  maxLines: 1),
              const SizedBox(height: 8),
              adminTextField(pushBodyC, 'نص الإشعار (اختياري)', maxLines: 2),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryDeepTeal,
                      ),
                      onPressed: () async {
                        // إغلاق الكيبورد فوراً لمنع تعارض الـ MediaQuery
                        FocusScope.of(context).unfocus();

                        final nav = Navigator.of(context);
                        setSaving(true);
                        try {
                          await proCardRepo.upsertCurrent(
                            contentType: type,
                            text: textC.text.trim(),
                            imageUrl: imageUrlC.text.trim(),
                            isActive: isActive,
                          );

                          final title = pushTitleC.text.trim().isNotEmpty
                              ? pushTitleC.text.trim()
                              : _defaultPushTitle();

                          String body = pushBodyC.text.trim();
                          if (body.isEmpty) {
                            body = (type == ProCardContentType.text &&
                                    textC.text.trim().isNotEmpty)
                                ? textC.text.trim()
                                : _defaultPushBodyForType(type);
                          }

                          await _savePushMeta(
                            notify: notify,
                            pushTitle: title,
                            pushBody: body,
                          );

                          snack('تم الحفظ ✅');
                          nav.pop();
                        } catch (_) {
                          snack('فشل الحفظ.');
                        } finally {
                          setSaving(false);
                        }
                      },
                      child: adminBtnText('حفظ'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );

    // ✅ التعديل الجوهري: تأخير الـ Dispose لضمان انتهاء الأنميشن وإغلاق النافذة تماماً
    // هذا يمنع خطأ "used after being disposed" بنسبة 100%
    await Future.delayed(const Duration(milliseconds: 500));
    textC.dispose();
    imageUrlC.dispose();
    pushTitleC.dispose();
    pushBodyC.dispose();
  }

  Future<void> _openProEditorWithBanner(
      BuildContext context, ProCardBanner banner) async {
    final textC = TextEditingController(text: banner.text);
    final imageUrlC = TextEditingController(text: banner.imageUrl);
    final pushTitleC = TextEditingController();
    final pushBodyC = TextEditingController();

    bool notify = false;
    bool isActive = banner.isActive;
    ProCardContentType type = banner.contentType;

    final meta = await _loadPushMeta();
    pushTitleC.text = (meta['pushTitle'] ?? '').toString();
    pushBodyC.text = (meta['pushBody'] ?? '').toString();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (context, setLocal) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 12,
          ),
          child: Column(
            key: ValueKey('pro_editor_${banner.id}'),
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'تعديل رسالة Pro',
                style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<ProCardContentType>(
                      value: ProCardContentType.text,
                      groupValue: type,
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (v) => setLocal(() {
                        type = v!;
                        if (pushBodyC.text.trim().isEmpty) {
                          pushBodyC.text = _defaultPushBodyForType(type);
                        }
                      }),
                      title: Text('نص', style: GoogleFonts.cairo(fontSize: 12)),
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<ProCardContentType>(
                      value: ProCardContentType.image,
                      groupValue: type,
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (v) => setLocal(() {
                        type = v!;
                        if (pushBodyC.text.trim().isEmpty) {
                          pushBodyC.text = _defaultPushBodyForType(type);
                        }
                      }),
                      title:
                          Text('صورة', style: GoogleFonts.cairo(fontSize: 12)),
                    ),
                  ),
                ],
              ),
              if (type == ProCardContentType.text)
                adminTextField(textC, 'نص الرسالة...', maxLines: 4)
              else
                adminTextField(imageUrlC, 'رابط الصورة (https://)...',
                    maxLines: 2),
              SwitchListTile(
                value: isActive,
                onChanged: (v) => setLocal(() => isActive = v),
                title: Text('ظاهر', style: GoogleFonts.cairo(fontSize: 12)),
              ),
              const SizedBox(height: 6),
              SwitchListTile(
                value: notify,
                onChanged: (v) => setLocal(() => notify = v),
                title:
                    Text('إرسال إشعار', style: GoogleFonts.cairo(fontSize: 12)),
              ),
              adminTextField(pushTitleC, 'عنوان الإشعار (اختياري)',
                  maxLines: 1),
              const SizedBox(height: 8),
              adminTextField(pushBodyC, 'نص الإشعار (اختياري)', maxLines: 2),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryDeepTeal,
                      ),
                      onPressed: () async {
                        FocusScope.of(context).unfocus();
                        final nav = Navigator.of(context);
                        setSaving(true);
                        try {
                          await proCardRepo.upsertCurrent(
                            contentType: type,
                            text: textC.text.trim(),
                            imageUrl: imageUrlC.text.trim(),
                            isActive: isActive,
                            publishAt: banner.publishAt,
                            expireAt: banner.expireAt,
                          );

                          final title = pushTitleC.text.trim().isNotEmpty
                              ? pushTitleC.text.trim()
                              : _defaultPushTitle();

                          String body = pushBodyC.text.trim();
                          if (body.isEmpty) {
                            body = (type == ProCardContentType.text &&
                                    textC.text.trim().isNotEmpty)
                                ? textC.text.trim()
                                : _defaultPushBodyForType(type);
                          }

                          await _savePushMeta(
                            notify: notify,
                            pushTitle: title,
                            pushBody: body,
                          );

                          snack('تم الحفظ ✅');
                          nav.pop();
                        } catch (_) {
                          snack('فشل الحفظ.');
                        } finally {
                          setSaving(false);
                        }
                      },
                      child: adminBtnText('حفظ'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );

    // ✅ تأخير الـ Dispose هنا أيضاً لنفس السبب
    await Future.delayed(const Duration(milliseconds: 500));
    textC.dispose();
    imageUrlC.dispose();
    pushTitleC.dispose();
    pushBodyC.dispose();
  }

  Widget _buildAppConfigSection(BuildContext context) {
    return StreamBuilder<Map<String, dynamic>>(
      stream: configService.watchCurrent(),
      builder: (context, snap) {
        final config = snap.data ?? AppConfigService.defaults;
        final features = (config['features'] as Map<String, dynamic>?) ??
            AppConfigService.defaultFeatures;
        final limits = (config['limits'] as Map<String, dynamic>?) ??
            AppConfigService.defaultLimits;
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'App Controls',
                style: GoogleFonts.cairo(
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  color: AppColors.primaryDeepTeal,
                ),
              ),
              const Divider(),
              _configSwitch(
                label: 'Push Notifications',
                value: features['pushNotificationsEnabled'] == true,
                onChanged: (v) => _saveFeature('pushNotificationsEnabled', v),
              ),
              _configSwitch(
                label: 'Support Chat',
                value: features['supportChatEnabled'] == true,
                onChanged: (v) => _saveFeature('supportChatEnabled', v),
              ),
              _configSwitch(
                label: 'Quiz Share',
                value: features['quizShareEnabled'] == true,
                onChanged: (v) => _saveFeature('quizShareEnabled', v),
              ),
              const SizedBox(height: 8),
              Text(
                'Limits',
                style: GoogleFonts.cairo(
                    fontWeight: FontWeight.w800, fontSize: 12),
              ),
              _configLimitRow(
                label: 'Max Fetch',
                value: limits['maxFetchPerPage'] ?? 50,
                onSave: (v) => _saveLimit('maxFetchPerPage', v),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _configSwitch({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: Text(label, style: GoogleFonts.cairo(fontSize: 12)),
      value: value,
      onChanged: onChanged,
    );
  }

  Widget _configLimitRow({
    required String label,
    required int value,
    required ValueChanged<int> onSave,
  }) {
    final controller = TextEditingController(text: value.toString());
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(label, style: GoogleFonts.cairo(fontSize: 11)),
          ),
          SizedBox(
            width: 70,
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(fontSize: 12),
              decoration: InputDecoration(
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 50,
            height: 32,
            child: ElevatedButton(
              onPressed: () {
                final p = int.tryParse(controller.text.trim());
                if (p != null && p > 0) onSave(p);
              },
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.zero,
                backgroundColor: AppColors.primaryDeepTeal,
              ),
              child: Text('Save', style: GoogleFonts.cairo(fontSize: 10)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveFeature(String key, bool value) async {
    setSaving(true);
    try {
      await configService.upsertCurrent({
        'features': {key: value}
      });
      snack('✅');
    } catch (_) {
      snack('فشل');
    } finally {
      setSaving(false);
    }
  }

  Future<void> _saveLimit(String key, int value) async {
    setSaving(true);
    try {
      await configService.upsertCurrent({
        'limits': {key: value}
      });
      snack('✅');
    } catch (_) {
      snack('فشل');
    } finally {
      setSaving(false);
    }
  }
}
