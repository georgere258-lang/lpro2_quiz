// PATH: lib/core/constants/firestore_paths.dart
// Firestore collection and document path constants.

class FirestorePaths {
  FirestorePaths._();

  // ─────────────────────────────────────────────────────────────
  // Collections
  // ─────────────────────────────────────────────────────────────

  static const String appConfig = 'app_config';
  static const String homeProCard = 'home_pro_card';
  static const String knowYourClient = 'know_your_client';
  static const String newsTickerItems = 'news_ticker_items';
  static const String proInsight = 'pro_insight';
  static const String quizzes = 'quizzes';
  static const String supportChats = 'support_chats';
  static const String supportTickets = 'support_tickets';
  static const String users = 'users';

  // ─────────────────────────────────────────────────────────────
  // Document / Sub-path constants
  // ─────────────────────────────────────────────────────────────

  static const String currentDoc = 'current';
  static const String history = 'history';

  // Legacy alias (kept for backward compatibility)
  static const String proCardCurrent = homeProCard;

  // ─────────────────────────────────────────────────────────────
  // Section Keys (for AdminControlFields.sectionKey)
  // ─────────────────────────────────────────────────────────────

  static const String sectionKeyProInsight = 'pro_insight';
  static const String sectionKeyKyc = 'kyc';
  static const String sectionKeyRadar = 'radar';
  static const String sectionKeyMoney = 'money';
  static const String sectionKeyProCard = 'pro_card';
}
