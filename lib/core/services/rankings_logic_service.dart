import 'news_ticker_service.dart';

class RankingsLogicService {
  final NewsTickerService _newsService = NewsTickerService();

  Future<void> onUserRankUpdated({
    required String userName,
    required String leagueName,
    required int newRank,
  }) async {
    final text = "🔥 $userName ارتقى إلى المركز $newRank في $leagueName";

    await _newsService.publishNews(
      textAr: text,
      priority: 5,
      notify: true,
    );
  }
}
