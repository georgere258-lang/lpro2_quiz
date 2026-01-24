// PATH: lib/presentation/screens/admin_panel.dart
// Admin panel with 6 tabs: Pro | Quiz | News | KYC | Support | Users
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/firestore_paths.dart';
import '../../core/models/admin_control_models.dart';
import '../../core/services/app_config_service.dart';
import '../../features/kyc/models/kyc_item.dart';
import '../../features/kyc/repositories/kyc_repository.dart';
import '../../features/news_ticker/repositories/news_ticker_repository.dart';
import '../../features/pro_card/models/pro_card_banner.dart';
import '../../features/pro_card/repositories/pro_card_repository.dart';
import '../../features/quizzes/models/quiz.dart';
import '../../features/quizzes/repositories/quiz_repository.dart';
import '../../features/support/models/support_ticket.dart';
import '../../features/support/repositories/support_repository.dart';
import '../../features/users/models/user_profile.dart';
import '../../features/users/repositories/users_admin_repository.dart';

class AdminPanel extends StatefulWidget {
  const AdminPanel({super.key});

  @override
  State<AdminPanel> createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  // Repositories
  final ProCardRepository _proCardRepo = ProCardRepository();
  final QuizRepository _quizRepo = QuizRepository();
  final KycRepository _kycRepo = KycRepository();
  final SupportRepository _supportRepo = SupportRepository();
  final UsersAdminRepository _usersRepo = UsersAdminRepository();
  final NewsTickerRepository _tickerRepo = NewsTickerRepository();
  final AppConfigService _configService = AppConfigService();

  // Quiz tab
  String _selectedCategory = QuizCategory.general;
  String _selectedLeague = QuizLeague.bronze;

  // Ticker tab
  final TextEditingController _tickerText = TextEditingController();
  int _tickerPriority = 0;
  bool _tickerNotify = false;

  bool _saving = false;

  static const double _btnW = 200;
  static const double _btnH = 42;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _tickerText.dispose();
    super.dispose();
  }

  // Helpers
  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg, textAlign: TextAlign.right, style: GoogleFonts.cairo())),
    );
  }

  Widget _btnText(String text, {Color color = Colors.white, double size = 13}) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(text, maxLines: 1, style: GoogleFonts.cairo(fontWeight: FontWeight.w900, fontSize: size, color: color)),
    );
  }

  Widget _tf(TextEditingController c, String hint, {int maxLines = 1}) {
    return TextField(
      controller: c,
      maxLines: maxLines,
      textAlign: TextAlign.right,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _centerBtn({required VoidCallback? onPressed, required Widget child, Color? bg}) {
    return Align(
      alignment: Alignment.center,
      child: SizedBox(
        width: _btnW,
        height: _btnH,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(backgroundColor: bg, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          child: child,
        ),
      ),
    );
  }

  Future<bool> _confirm(String title, String content) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(title, style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
            content: Text(content, style: GoogleFonts.cairo()),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('إلغاء', style: GoogleFonts.cairo())),
              TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text('تأكيد', style: GoogleFonts.cairo(color: Colors.red))),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: FittedBox(fit: BoxFit.scaleDown, child: Text("Admin Panel", maxLines: 1, style: GoogleFonts.cairo(fontWeight: FontWeight.w900))),
        backgroundColor: AppColors.primaryDeepTeal,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: TabBar(
            controller: _tabController,
            indicatorColor: AppColors.secondaryOrange,
            isScrollable: true,
            labelPadding: const EdgeInsets.symmetric(horizontal: 12),
            indicatorSize: TabBarIndicatorSize.tab,
            labelStyle: GoogleFonts.cairo(fontWeight: FontWeight.w900, fontSize: 12),
            unselectedLabelStyle: GoogleFonts.cairo(fontWeight: FontWeight.w800, fontSize: 11),
            tabs: const [
              _AdminTabLabel("Pro"),
              _AdminTabLabel("Quiz"),
              _AdminTabLabel("News"),
              _AdminTabLabel("KYC"),
              _AdminTabLabel("Support"),
              _AdminTabLabel("Users"),
            ],
          ),
        ),
      ),
      body: Stack(
        children: [
          TabBarView(
            controller: _tabController,
            children: [
              _buildProTab(),
              _buildQuizTab(),
              _buildTickerTab(),
              _buildKycTab(),
              _buildSupportTab(),
              _buildUsersTab(),
            ],
          ),
          if (_saving) Positioned.fill(child: Container(color: Colors.black12, child: const Center(child: CircularProgressIndicator()))),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // TAB 1: PRO CARD
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildProTab() {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _centerBtn(onPressed: () => _openProEditor(), bg: AppColors.primaryDeepTeal, child: _btnText('تعديل / إنشاء الرسالة', size: 12)),
              const SizedBox(height: 16),
              StreamBuilder<ProCardBanner?>(
                stream: _proCardRepo.watchCurrent(),
                builder: (ctx, snap) {
                  if (!snap.hasData || snap.data == null) {
                    return Center(child: snap.connectionState == ConnectionState.waiting ? const CircularProgressIndicator() : Text('لا توجد رسالة.', style: GoogleFonts.cairo()));
                  }
                  final banner = snap.data!;
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.primaryDeepTeal.withValues(alpha: 0.2))),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _statusBadge(banner.isActive),
                        const SizedBox(height: 10),
                        Text(banner.text, style: GoogleFonts.cairo(fontSize: 14, height: 1.6)),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _smallBtn(banner.isActive ? 'إخفاء' : 'إظهار', Icons.visibility, () async {
                              setState(() => _saving = true);
                              try {
                                await _proCardRepo.toggleActive(!banner.isActive);
                                _snack(banner.isActive ? 'تم الإخفاء ✅' : 'تم الإظهار ✅');
                              } catch (_) {
                                _snack('فشل');
                              } finally {
                                if (mounted) setState(() => _saving = false);
                              }
                            }),
                            const SizedBox(width: 10),
                            _smallBtn('تعديل', Icons.edit, () => _openProEditorWithBanner(banner)),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              _buildAppConfigSection(),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openProEditor() async {
    final textC = TextEditingController();
    bool isActive = true;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (_) => StatefulBuilder(
        builder: (context, setLocal) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 16, right: 16, top: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('رسالة Pro الحية', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
              _tf(textC, 'نص الرسالة...', maxLines: 4),
              SwitchListTile(value: isActive, onChanged: (v) => setLocal(() => isActive = v), title: Text('ظاهر', style: GoogleFonts.cairo(fontSize: 12))),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryDeepTeal), onPressed: () async {
                    final nav = Navigator.of(context);
                    setState(() => _saving = true);
                    try {
                      await _proCardRepo.upsertCurrent(text: textC.text.trim(), isActive: isActive);
                      _snack('تم الحفظ ✅');
                      nav.pop();
                    } catch (_) {
                      _snack('فشل الحفظ.');
                    } finally {
                      if (mounted) setState(() => _saving = false);
                    }
                  }, child: _btnText('حفظ'))),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openProEditorWithBanner(ProCardBanner banner) async {
    final textC = TextEditingController(text: banner.text);
    bool isActive = banner.isActive;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (_) => StatefulBuilder(
        builder: (context, setLocal) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 16, right: 16, top: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('تعديل رسالة Pro', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
              _tf(textC, 'نص الرسالة...', maxLines: 4),
              SwitchListTile(value: isActive, onChanged: (v) => setLocal(() => isActive = v), title: Text('ظاهر', style: GoogleFonts.cairo(fontSize: 12))),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryDeepTeal), onPressed: () async {
                    final nav = Navigator.of(context);
                    setState(() => _saving = true);
                    try {
                      await _proCardRepo.upsertCurrent(text: textC.text.trim(), isActive: isActive, publishAt: banner.publishAt, expireAt: banner.expireAt);
                      _snack('تم الحفظ ✅');
                      nav.pop();
                    } catch (_) {
                      _snack('فشل الحفظ.');
                    } finally {
                      if (mounted) setState(() => _saving = false);
                    }
                  }, child: _btnText('حفظ'))),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppConfigSection() {
    return StreamBuilder<Map<String, dynamic>>(
      stream: _configService.watchCurrent(),
      builder: (context, snap) {
        final config = snap.data ?? AppConfigService.defaults;
        final features = (config['features'] as Map<String, dynamic>?) ?? AppConfigService.defaultFeatures;
        final limits = (config['limits'] as Map<String, dynamic>?) ?? AppConfigService.defaultLimits;
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.withValues(alpha: 0.3))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('App Controls', style: GoogleFonts.cairo(fontWeight: FontWeight.w900, fontSize: 14, color: AppColors.primaryDeepTeal)),
              const Divider(),
              _configSwitch(label: 'Push Notifications', value: features['pushNotificationsEnabled'] == true, onChanged: (v) => _saveFeature('pushNotificationsEnabled', v)),
              _configSwitch(label: 'Support Chat', value: features['supportChatEnabled'] == true, onChanged: (v) => _saveFeature('supportChatEnabled', v)),
              _configSwitch(label: 'Quiz Share', value: features['quizShareEnabled'] == true, onChanged: (v) => _saveFeature('quizShareEnabled', v)),
              const SizedBox(height: 8),
              Text('Limits', style: GoogleFonts.cairo(fontWeight: FontWeight.w800, fontSize: 12)),
              _configLimitRow(label: 'Max Fetch', value: limits['maxFetchPerPage'] ?? 50, onSave: (v) => _saveLimit('maxFetchPerPage', v)),
            ],
          ),
        );
      },
    );
  }

  Widget _configSwitch({required String label, required bool value, required ValueChanged<bool> onChanged}) {
    return SwitchListTile(dense: true, contentPadding: EdgeInsets.zero, title: Text(label, style: GoogleFonts.cairo(fontSize: 12)), value: value, onChanged: onChanged);
  }

  Widget _configLimitRow({required String label, required int value, required ValueChanged<int> onSave}) {
    final controller = TextEditingController(text: value.toString());
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(label, style: GoogleFonts.cairo(fontSize: 11))),
          SizedBox(width: 70, child: TextField(controller: controller, keyboardType: TextInputType.number, textAlign: TextAlign.center, style: GoogleFonts.cairo(fontSize: 12), decoration: InputDecoration(isDense: true, contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8), filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none)))),
          const SizedBox(width: 6),
          SizedBox(width: 50, height: 32, child: ElevatedButton(onPressed: () { final p = int.tryParse(controller.text.trim()); if (p != null && p > 0) onSave(p); }, style: ElevatedButton.styleFrom(padding: EdgeInsets.zero, backgroundColor: AppColors.primaryDeepTeal), child: Text('Save', style: GoogleFonts.cairo(fontSize: 10)))),
        ],
      ),
    );
  }

  Future<void> _saveFeature(String key, bool value) async {
    setState(() => _saving = true);
    try { await _configService.upsertCurrent({'features': {key: value}}); _snack('✅'); } catch (_) { _snack('فشل'); } finally { if (mounted) setState(() => _saving = false); }
  }

  Future<void> _saveLimit(String key, int value) async {
    setState(() => _saving = true);
    try { await _configService.upsertCurrent({'limits': {key: value}}); _snack('✅'); } catch (_) { _snack('فشل'); } finally { if (mounted) setState(() => _saving = false); }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // TAB 2: QUIZZES (using QuizRepository)
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildQuizTab() {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Filters
            Row(
              children: [
                Expanded(child: DropdownButtonFormField<String>(value: _selectedCategory, items: QuizCategory.values.map((c) => DropdownMenuItem(value: c, child: Text(c, style: GoogleFonts.cairo(fontSize: 12)))).toList(), onChanged: (v) => setState(() => _selectedCategory = v ?? _selectedCategory), decoration: _dropDecor())),
                const SizedBox(width: 8),
                Expanded(child: DropdownButtonFormField<String>(value: _selectedLeague, items: QuizLeague.values.map((l) => DropdownMenuItem(value: l, child: Text(l, style: GoogleFonts.cairo(fontSize: 12)))).toList(), onChanged: (v) => setState(() => _selectedLeague = v ?? _selectedLeague), decoration: _dropDecor())),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: StreamBuilder<List<Quiz>>(
                stream: _quizRepo.watchByCategoryLeague(category: _selectedCategory, league: _selectedLeague, includeInactive: true, includeDeleted: false, limit: 50),
                builder: (ctx, snap) {
                  if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                  final quizzes = snap.data!;
                  if (quizzes.isEmpty) return Center(child: Text('لا توجد أسئلة', style: GoogleFonts.cairo()));
                  return ListView.separated(
                    itemCount: quizzes.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (ctx, i) => _quizCard(quizzes[i]),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            _centerBtn(onPressed: () => _openQuizEditor(), bg: AppColors.secondaryOrange, child: _btnText('إضافة سؤال جديد', size: 12)),
          ],
        ),
      ),
    );
  }

  Widget _quizCard(Quiz q) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.black.withValues(alpha: 0.08))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [_statusBadge(q.isActive), const Spacer(), Text('${q.league} • ${q.category}', style: GoogleFonts.cairo(fontSize: 10, color: Colors.grey))]),
          const SizedBox(height: 8),
          Text(q.question, style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          ...q.options.asMap().entries.map((e) => Text('${e.key + 1}. ${e.value}${e.key == q.correctOptionIndex ? ' ✓' : ''}', style: GoogleFonts.cairo(fontSize: 11, color: e.key == q.correctOptionIndex ? Colors.green : Colors.black87))),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _tinyBtn(q.isActive ? 'إخفاء' : 'إظهار', () async { setState(() => _saving = true); try { await _quizRepo.toggleActive(q.id, !q.isActive); _snack('✅'); } catch (_) { _snack('فشل'); } finally { if (mounted) setState(() => _saving = false); } }),
              _tinyBtn('تعديل', () => _openQuizEditor(quiz: q)),
              _tinyBtn('نقل', () => _openMoveQuizDialog(q)),
              _tinyBtn('حذف', () async { if (await _confirm('حذف السؤال؟', 'سيتم إخفاء السؤال نهائياً')) { setState(() => _saving = true); try { await _quizRepo.softDelete(q.id); _snack('تم الحذف ✅'); } catch (_) { _snack('فشل'); } finally { if (mounted) setState(() => _saving = false); } } }),
              _tinyBtn('مشاركة', () { final payload = _quizRepo.buildSharePayload(q); Clipboard.setData(ClipboardData(text: payload['deepLink'])); _snack('تم نسخ الرابط ✅'); }),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _openQuizEditor({Quiz? quiz}) async {
    final qC = TextEditingController(text: quiz?.question ?? '');
    final o0 = TextEditingController(text: quiz?.options.elementAtOrNull(0) ?? '');
    final o1 = TextEditingController(text: quiz?.options.elementAtOrNull(1) ?? '');
    final o2 = TextEditingController(text: quiz?.options.elementAtOrNull(2) ?? '');
    final o3 = TextEditingController(text: quiz?.options.elementAtOrNull(3) ?? '');
    int correct = quiz?.correctOptionIndex ?? 0;
    String cat = quiz?.category ?? _selectedCategory;
    String league = quiz?.league ?? _selectedLeague;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (_) => StatefulBuilder(
        builder: (context, setLocal) => Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 16, right: 16, top: 12),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(quiz == null ? 'إضافة سؤال' : 'تعديل سؤال', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  _tf(qC, 'نص السؤال...', maxLines: 2),
                  const SizedBox(height: 8),
                  _tf(o0, 'اختيار 1'), const SizedBox(height: 6),
                  _tf(o1, 'اختيار 2'), const SizedBox(height: 6),
                  _tf(o2, 'اختيار 3'), const SizedBox(height: 6),
                  _tf(o3, 'اختيار 4'), const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: DropdownButtonFormField<String>(value: cat, items: QuizCategory.values.map((c) => DropdownMenuItem(value: c, child: Text(c, style: GoogleFonts.cairo(fontSize: 12)))).toList(), onChanged: (v) => setLocal(() => cat = v ?? cat), decoration: _dropDecor())),
                      const SizedBox(width: 8),
                      Expanded(child: DropdownButtonFormField<String>(value: league, items: QuizLeague.values.map((l) => DropdownMenuItem(value: l, child: Text(l, style: GoogleFonts.cairo(fontSize: 12)))).toList(), onChanged: (v) => setLocal(() => league = v ?? league), decoration: _dropDecor())),
                    ],
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(value: correct, items: List.generate(4, (i) => DropdownMenuItem(value: i, child: Text('الإجابة الصحيحة: ${i + 1}', style: GoogleFonts.cairo(fontSize: 12)))), onChanged: (v) => setLocal(() => correct = v ?? 0), decoration: _dropDecor()),
                  const SizedBox(height: 12),
                  _centerBtn(
                    onPressed: () async {
                      final nav = Navigator.of(context);
                      final options = [o0.text.trim(), o1.text.trim(), o2.text.trim(), o3.text.trim()].where((o) => o.isNotEmpty).toList();
                      if (qC.text.trim().length < 10 || options.length < 2) { _snack('أكمل البيانات'); return; }
                      setState(() => _saving = true);
                      try {
                        final control = AdminControlFields(isActive: quiz?.isActive ?? true, sectionKey: FirestorePaths.sectionKeyQuiz);
                        final newQuiz = Quiz(id: quiz?.id ?? '', question: qC.text.trim(), options: options, correctOptionIndex: correct.clamp(0, options.length - 1), category: cat, league: league, control: control);
                        newQuiz.validate();
                        if (quiz == null) {
                          await _quizRepo.create(newQuiz);
                        } else {
                          await _quizRepo.update(quiz.id, newQuiz.toFirestore());
                        }
                        _snack('✅');
                        nav.pop();
                      } catch (e) {
                        _snack('خطأ: $e');
                      } finally {
                        if (mounted) setState(() => _saving = false);
                      }
                    },
                    bg: AppColors.primaryDeepTeal,
                    child: _btnText('حفظ'),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openMoveQuizDialog(Quiz q) async {
    String newCat = q.category;
    String newLeague = q.league;
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text('نقل السؤال', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(value: newCat, items: QuizCategory.values.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(), onChanged: (v) => setLocal(() => newCat = v ?? newCat), decoration: _dropDecor()),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(value: newLeague, items: QuizLeague.values.map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(), onChanged: (v) => setLocal(() => newLeague = v ?? newLeague), decoration: _dropDecor()),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text('إلغاء', style: GoogleFonts.cairo())),
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                setState(() => _saving = true);
                try { await _quizRepo.move(q.id, newCategory: newCat, newLeague: newLeague); _snack('تم النقل ✅'); } catch (_) { _snack('فشل'); } finally { if (mounted) setState(() => _saving = false); }
              },
              child: Text('نقل', style: GoogleFonts.cairo(color: AppColors.primaryDeepTeal)),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // TAB 3: NEWS TICKER
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildTickerTab() {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _tf(_tickerText, 'نص الخبر...', maxLines: 2),
            const SizedBox(height: 8),
            _centerBtn(onPressed: _addTickerItem, bg: AppColors.primaryDeepTeal, child: _btnText('إضافة', size: 12)),
            const SizedBox(height: 12),
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _tickerRepo.watchAllForAdmin(),
                builder: (ctx, snap) {
                  if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                  final docs = snap.data!.docs;
                  if (docs.isEmpty) return Center(child: Text('لا توجد أخبار', style: GoogleFonts.cairo()));
                  return ListView.separated(
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (ctx, i) {
                      final d = docs[i].data();
                      final text = (d['text_ar'] ?? '').toString();
                      final isActive = d['isActive'] == true;
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.black.withValues(alpha: 0.08))),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [_statusBadge(isActive), const Spacer()]),
                            const SizedBox(height: 8),
                            Text(text, style: GoogleFonts.cairo(fontSize: 13)),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              children: [
                                _tinyBtn(isActive ? 'إخفاء' : 'إظهار', () => _toggleTickerActive(docs[i].id, isActive)),
                                _tinyBtn('حذف', () => _deleteTicker(docs[i].id)),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addTickerItem() async {
    final text = _tickerText.text.trim();
    if (text.isEmpty) { _snack('اكتب نص الخبر'); return; }
    setState(() => _saving = true);
    try {
      await _tickerRepo.addItem({'text_ar': text, 'priority': _tickerPriority, 'isActive': true, 'notify': _tickerNotify, 'createdAt': FieldValue.serverTimestamp(), 'updatedAt': FieldValue.serverTimestamp(), 'source': 'admin'});
      _snack('✅');
      _tickerText.clear();
    } catch (_) { _snack('فشل'); } finally { if (mounted) setState(() => _saving = false); }
  }

  Future<void> _toggleTickerActive(String id, bool current) async {
    setState(() => _saving = true);
    try { await _tickerRepo.toggleActive(id, current); _snack('✅'); } catch (_) { _snack('فشل'); } finally { if (mounted) setState(() => _saving = false); }
  }

  Future<void> _deleteTicker(String id) async {
    setState(() => _saving = true);
    try { await _tickerRepo.deleteItem(id); _snack('✅'); } catch (_) { _snack('فشل'); } finally { if (mounted) setState(() => _saving = false); }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // TAB 4: KYC (using KycRepository)
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildKycTab() {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _centerBtn(onPressed: () => _openKycEditor(), bg: AppColors.secondaryOrange, child: _btnText('إضافة عنصر جديد', size: 12)),
            const SizedBox(height: 12),
            Expanded(
              child: StreamBuilder<List<KycItem>>(
                stream: _kycRepo.watchAll(),
                builder: (ctx, snap) {
                  if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                  final items = snap.data!;
                  if (items.isEmpty) return Center(child: Text('لا توجد عناصر', style: GoogleFonts.cairo()));
                  return ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (ctx, i) => _kycCard(items[i]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _kycCard(KycItem item) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.black.withValues(alpha: 0.08))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [_statusBadge(item.isActive), const Spacer(), Text('Order: ${item.orderInSection}', style: GoogleFonts.cairo(fontSize: 10, color: Colors.grey))]),
          const SizedBox(height: 8),
          Text(item.title, style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(item.content, maxLines: 2, overflow: TextOverflow.ellipsis, style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey[700])),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _tinyBtn(item.isActive ? 'إخفاء' : 'إظهار', () async { setState(() => _saving = true); try { await _kycRepo.toggleActive(item.id, !item.isActive); _snack('✅'); } catch (_) { _snack('فشل'); } finally { if (mounted) setState(() => _saving = false); } }),
              _tinyBtn('تعديل', () => _openKycEditor(item: item)),
              _tinyBtn('حذف', () async { if (await _confirm('حذف؟', 'سيتم حذف العنصر نهائياً')) { setState(() => _saving = true); try { await _kycRepo.delete(item.id); _snack('✅'); } catch (_) { _snack('فشل'); } finally { if (mounted) setState(() => _saving = false); } } }),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _openKycEditor({KycItem? item}) async {
    final titleC = TextEditingController(text: item?.title ?? '');
    final contentC = TextEditingController(text: item?.content ?? '');
    final imageC = TextEditingController(text: item?.imageUrl ?? '');

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 16, right: 16, top: 12),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(item == null ? 'إضافة عنصر' : 'تعديل عنصر', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _tf(titleC, 'العنوان (3+ حروف)'),
                const SizedBox(height: 8),
                _tf(contentC, 'المحتوى (20+ حرف)', maxLines: 4),
                const SizedBox(height: 8),
                _tf(imageC, 'رابط الصورة (اختياري)'),
                const SizedBox(height: 12),
                _centerBtn(
                  onPressed: () async {
                    final nav = Navigator.of(context);
                    if (titleC.text.trim().length < 3 || contentC.text.trim().length < 20) { _snack('أكمل البيانات'); return; }
                    setState(() => _saving = true);
                    try {
                      final control = AdminControlFields(isActive: item?.isActive ?? true, sectionKey: FirestorePaths.sectionKeyKyc, orderInSection: item?.orderInSection ?? UtcNormalizer.nowUtc().millisecondsSinceEpoch);
                      final newItem = KycItem(id: item?.id ?? '', title: titleC.text.trim(), content: contentC.text.trim(), imageUrl: imageC.text.trim().isEmpty ? null : imageC.text.trim(), control: control);
                      newItem.validate();
                      if (item == null) {
                        await _kycRepo.create(newItem);
                      } else {
                        await _kycRepo.update(item.id, newItem.toFirestore());
                      }
                      _snack('✅');
                      nav.pop();
                    } catch (e) { _snack('خطأ: $e'); } finally { if (mounted) setState(() => _saving = false); }
                  },
                  bg: AppColors.primaryDeepTeal,
                  child: _btnText('حفظ'),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // TAB 5: SUPPORT (using SupportRepository)
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildSupportTab() {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: StreamBuilder<List<SupportTicket>>(
          stream: _supportRepo.watchAllTickets(),
          builder: (ctx, snap) {
            if (!snap.hasData) return const Center(child: CircularProgressIndicator());
            final tickets = snap.data!;
            if (tickets.isEmpty) return Center(child: Text('لا توجد تذاكر', style: GoogleFonts.cairo()));
            return ListView.separated(
              itemCount: tickets.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (ctx, i) => _ticketCard(tickets[i]),
            );
          },
        ),
      ),
    );
  }

  Widget _ticketCard(SupportTicket t) {
    final statusColor = t.status == TicketStatus.open ? Colors.orange : t.status == TicketStatus.resolved ? Colors.green : t.status == TicketStatus.closed ? Colors.grey : Colors.blue;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: statusColor.withValues(alpha: 0.3))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)), child: Text(t.status, style: GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.w700, color: statusColor))),
              const Spacer(),
              Text('${t.messageCount} رسالة', style: GoogleFonts.cairo(fontSize: 10, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 8),
          Text(t.subject, style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w700)),
          Text(t.userName, style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey[600])),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _tinyBtn('استلام', () async {
                final uid = FirebaseAuth.instance.currentUser?.uid;
                if (uid == null) { _snack('سجل الدخول'); return; }
                setState(() => _saving = true);
                try { await _supportRepo.assignTicket(t.id, uid); _snack('✅'); } catch (_) { _snack('فشل'); } finally { if (mounted) setState(() => _saving = false); }
              }),
              _tinyBtn('الحالة', () => _openStatusDialog(t)),
              _tinyBtn('الرسائل', () => _openMessagesSheet(t)),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _openStatusDialog(SupportTicket t) async {
    String newStatus = t.status;
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text('تغيير الحالة', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
          content: DropdownButtonFormField<String>(value: newStatus, items: TicketStatus.values.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(), onChanged: (v) => setLocal(() => newStatus = v ?? newStatus), decoration: _dropDecor()),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text('إلغاء', style: GoogleFonts.cairo())),
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                setState(() => _saving = true);
                try { await _supportRepo.updateStatus(t.id, newStatus); _snack('✅'); } catch (_) { _snack('فشل'); } finally { if (mounted) setState(() => _saving = false); }
              },
              child: Text('حفظ', style: GoogleFonts.cairo(color: AppColors.primaryDeepTeal)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openMessagesSheet(SupportTicket t) async {
    final msgC = TextEditingController();
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text('رسائل التذكرة: ${t.subject}', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Expanded(
                  child: StreamBuilder(
                    stream: _supportRepo.watchMessages(t.id),
                    builder: (ctx, snap) {
                      if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                      final msgs = snap.data!;
                      if (msgs.isEmpty) return Center(child: Text('لا توجد رسائل', style: GoogleFonts.cairo()));
                      return ListView.builder(
                        itemCount: msgs.length,
                        itemBuilder: (ctx, i) {
                          final m = msgs[i];
                          return Align(
                            alignment: m.isAdminMessage ? Alignment.centerLeft : Alignment.centerRight,
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(color: m.isAdminMessage ? AppColors.primaryDeepTeal.withValues(alpha: 0.1) : Colors.grey[200], borderRadius: BorderRadius.circular(12)),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(m.senderName, style: GoogleFonts.cairo(fontSize: 10, fontWeight: FontWeight.w700)),
                                  Text(m.text, style: GoogleFonts.cairo(fontSize: 12)),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _tf(msgC, 'رد...')),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () async {
                        if (msgC.text.trim().isEmpty) return;
                        final user = FirebaseAuth.instance.currentUser;
                        if (user == null) { _snack('سجل الدخول'); return; }
                        try {
                          await _supportRepo.sendMessage(ticketId: t.id, senderId: user.uid, senderName: user.displayName ?? 'Admin', text: msgC.text.trim(), isAdmin: true);
                          msgC.clear();
                        } catch (_) { _snack('فشل'); }
                      },
                      icon: const Icon(Icons.send, color: AppColors.primaryDeepTeal),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // TAB 6: USERS (using UsersAdminRepository)
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildUsersTab() {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: StreamBuilder<List<UserProfile>>(
          stream: _usersRepo.watchAllUsers(limit: 50),
          builder: (ctx, snap) {
            if (!snap.hasData) return const Center(child: CircularProgressIndicator());
            final users = snap.data!;
            if (users.isEmpty) return Center(child: Text('لا يوجد مستخدمين', style: GoogleFonts.cairo()));
            return ListView.separated(
              itemCount: users.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (ctx, i) => _userCard(users[i]),
            );
          },
        ),
      ),
    );
  }

  Widget _userCard(UserProfile u) {
    final roleColor = u.role == UserRole.admin ? Colors.purple : u.role == UserRole.moderator ? Colors.blue : Colors.grey;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: u.isBlocked ? Colors.red.withValues(alpha: 0.05) : Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: u.isBlocked ? Colors.red.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.08))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: roleColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)), child: Text(u.role, style: GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.w700, color: roleColor))),
              if (u.isBlocked) ...[const SizedBox(width: 6), Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)), child: Text('محظور', style: GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.red)))],
            ],
          ),
          const SizedBox(height: 8),
          Text(u.name ?? 'بدون اسم', style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w700)),
          Text(u.email, style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey[600])),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _tinyBtn(u.isBlocked ? 'إلغاء الحظر' : 'حظر', () => u.isBlocked ? _unblockUser(u) : _openBlockDialog(u)),
              _tinyBtn('الدور', () => _openRoleDialog(u)),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _openBlockDialog(UserProfile u) async {
    final reasonC = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('حظر المستخدم', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${u.name ?? u.email}', style: GoogleFonts.cairo()),
            const SizedBox(height: 8),
            _tf(reasonC, 'سبب الحظر'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('إلغاء', style: GoogleFonts.cairo())),
          TextButton(
            onPressed: () async {
              if (reasonC.text.trim().isEmpty) { _snack('اكتب السبب'); return; }
              Navigator.pop(ctx);
              final adminUid = FirebaseAuth.instance.currentUser?.uid;
              if (adminUid == null) { _snack('سجل الدخول'); return; }
              setState(() => _saving = true);
              try { await _usersRepo.blockUser(u.uid, reasonC.text.trim(), adminUid); _snack('تم الحظر ✅'); } catch (_) { _snack('فشل'); } finally { if (mounted) setState(() => _saving = false); }
            },
            child: Text('حظر', style: GoogleFonts.cairo(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _unblockUser(UserProfile u) async {
    if (!await _confirm('إلغاء الحظر؟', 'سيتم إلغاء حظر ${u.name ?? u.email}')) return;
    setState(() => _saving = true);
    try { await _usersRepo.unblockUser(u.uid); _snack('تم إلغاء الحظر ✅'); } catch (_) { _snack('فشل'); } finally { if (mounted) setState(() => _saving = false); }
  }

  Future<void> _openRoleDialog(UserProfile u) async {
    String newRole = u.role;
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text('تغيير الدور', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
          content: DropdownButtonFormField<String>(value: newRole, items: UserRole.values.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(), onChanged: (v) => setLocal(() => newRole = v ?? newRole), decoration: _dropDecor()),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text('إلغاء', style: GoogleFonts.cairo())),
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                setState(() => _saving = true);
                try { await _usersRepo.updateRole(u.uid, newRole); _snack('✅'); } catch (_) { _snack('فشل'); } finally { if (mounted) setState(() => _saving = false); }
              },
              child: Text('حفظ', style: GoogleFonts.cairo(color: AppColors.primaryDeepTeal)),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // SHARED WIDGETS
  // ══════════════════════════════════════════════════════════════════════════
  Widget _statusBadge(bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: isActive ? Colors.green.withValues(alpha: 0.15) : Colors.red.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(999)),
      child: Text(isActive ? 'ظاهر' : 'مخفي', style: GoogleFonts.cairo(fontWeight: FontWeight.w900, fontSize: 11, color: isActive ? Colors.green[800] : Colors.red[800])),
    );
  }

  Widget _smallBtn(String text, IconData icon, VoidCallback onPressed) {
    return SizedBox(
      width: 100,
      height: 36,
      child: ElevatedButton.icon(onPressed: onPressed, icon: Icon(icon, size: 16), label: _btnText(text, size: 11)),
    );
  }

  Widget _tinyBtn(String text, VoidCallback onPressed) {
    return SizedBox(
      height: 32,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12), backgroundColor: AppColors.primaryDeepTeal.withValues(alpha: 0.9), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
        child: Text(text, style: GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.w700)),
      ),
    );
  }

  InputDecoration _dropDecor() {
    return InputDecoration(filled: true, fillColor: Colors.grey[100], border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10));
  }
}

class _AdminTabLabel extends StatelessWidget {
  final String text;
  const _AdminTabLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Tab(child: Center(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 6), child: FittedBox(fit: BoxFit.scaleDown, child: Text(text, maxLines: 1)))));
  }
}
