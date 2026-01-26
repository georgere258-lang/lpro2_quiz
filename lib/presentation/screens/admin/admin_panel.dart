// PATH: lib/presentation/screens/admin/admin_panel.dart
// Admin panel with 7 tabs: Content | Pro | Quiz | News | KYC | Support | Users

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/app_config_service.dart';
import '../../../features/kyc/repositories/kyc_repository.dart';
import '../../../features/news_ticker/repositories/news_ticker_repository.dart';
import '../../../features/pro_card/repositories/pro_card_repository.dart';
import '../../../features/support/repositories/support_repository.dart';
import '../../../features/users/repositories/users_admin_repository.dart';
import '../../../features/leaderboards/repositories/leaderboards_repository.dart';
import 'tabs/admin_content_tab.dart';
import 'tabs/admin_kyc_tab.dart';
import 'tabs/admin_news_tab.dart';
import 'tabs/admin_pro_tab.dart';
import 'tabs/admin_quiz_tab.dart';
import 'tabs/admin_support_tab.dart';
import 'tabs/admin_users_tab.dart';
import 'widgets/admin_shared_widgets.dart';

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
  final KycRepository _kycRepo = KycRepository();
  final SupportRepository _supportRepo = SupportRepository();
  final UsersAdminRepository _usersRepo = UsersAdminRepository();
  final NewsTickerRepository _tickerRepo = NewsTickerRepository();
  final AppConfigService _configService = AppConfigService();
  final LeaderboardsRepository _leaderboardsRepo = LeaderboardsRepository();

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(msg,
              textAlign: TextAlign.right, style: GoogleFonts.cairo())),
    );
  }

  void _setSaving(bool value) {
    if (mounted) setState(() => _saving = value);
  }

  Future<bool> _confirm(String title, String content) async {
    return await adminConfirmDialog(context, title, content);
  }

  Future<void> _refreshLeaderboards() async {
    _setSaving(true);
    try {
      await _leaderboardsRepo.refreshTop10AsAdmin();
      _snack('تم تحديث الترتيب ✅');
    } catch (e) {
      _snack('خطأ: $e');
    } finally {
      _setSaving(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text("Admin Panel",
                maxLines: 1,
                style: GoogleFonts.cairo(fontWeight: FontWeight.w900))),
        backgroundColor: AppColors.primaryDeepTeal,
        actions: [
          IconButton(
            icon: const Icon(Icons.leaderboard, color: Colors.white),
            tooltip: 'تحديث الترتيب',
            onPressed: _refreshLeaderboards,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: TabBar(
            controller: _tabController,
            indicatorColor: AppColors.secondaryOrange,
            isScrollable: true,
            labelPadding: const EdgeInsets.symmetric(horizontal: 12),
            indicatorSize: TabBarIndicatorSize.tab,
            labelStyle:
                GoogleFonts.cairo(fontWeight: FontWeight.w900, fontSize: 12),
            unselectedLabelStyle:
                GoogleFonts.cairo(fontWeight: FontWeight.w800, fontSize: 11),
            tabs: const [
              AdminTabLabel("Content"),
              AdminTabLabel("Pro"),
              AdminTabLabel("Quiz"),
              AdminTabLabel("News"),
              AdminTabLabel("KYC"),
              AdminTabLabel("Support"),
              AdminTabLabel("Users"),
            ],
          ),
        ),
      ),
      body: Stack(
        children: [
          TabBarView(
            controller: _tabController,
            children: [
              AdminContentTab(
                setSaving: _setSaving,
                snack: _snack,
              ),
              AdminProTab(
                proCardRepo: _proCardRepo,
                configService: _configService,
                setSaving: _setSaving,
                snack: _snack,
              ),
              const AdminQuizTab(),
              AdminNewsTab(
                tickerRepo: _tickerRepo,
                setSaving: _setSaving,
                snack: _snack,
              ),
              AdminKycTab(
                kycRepo: _kycRepo,
                setSaving: _setSaving,
                snack: _snack,
                confirm: _confirm,
              ),
              AdminSupportTab(
                supportRepo: _supportRepo,
                setSaving: _setSaving,
                snack: _snack,
              ),
              AdminUsersTab(
                usersRepo: _usersRepo,
                setSaving: _setSaving,
                snack: _snack,
                confirm: _confirm,
              ),
            ],
          ),
          if (_saving)
            Positioned.fill(
                child: Container(
                    color: Colors.black12,
                    child: const Center(child: CircularProgressIndicator()))),
        ],
      ),
    );
  }
}
