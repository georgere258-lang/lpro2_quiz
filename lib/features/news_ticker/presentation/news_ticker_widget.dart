import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/news_ticker_service.dart';

class NewsTickerWidget extends StatefulWidget {
  final String userName; // الترحيب متلغى حالياً
  const NewsTickerWidget({super.key, required this.userName});

  @override
  State<NewsTickerWidget> createState() => _NewsTickerWidgetState();
}

class _NewsTickerWidgetState extends State<NewsTickerWidget> {
  final NewsTickerService _service = NewsTickerService();
  late final ScrollController _scrollController;

  static const double _pixelsPerSecond = 35.0;
  static const Duration _tick = Duration(milliseconds: 16); // ~60fps

  Timer? _timer;

  // ✅ Cache لآخر أخبار سليمة (عشان ميختفوش لو الاستعلام وقع/فرغ لحظة)
  List<String> _cachedMessages = const [];
  String _lastSignature = '';

  bool _resetScheduled = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();

    _timer = Timer.periodic(_tick, (_) => _onTick());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _onTick() {
    if (!mounted) return;
    if (!_scrollController.hasClients) return;

    final position = _scrollController.position;
    final max = position.maxScrollExtent;

    if (max <= 0) return;

    final delta = _pixelsPerSecond * (_tick.inMilliseconds / 1000.0);
    final next = position.pixels + delta;

    try {
      if (next >= max) {
        _scrollController.jumpTo(0);
      } else {
        _scrollController.jumpTo(next);
      }
    } catch (_) {
      // تجاهل
    }
  }

  void _scheduleResetToStart() {
    if (_resetScheduled) return;
    _resetScheduled = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _resetScheduled = false;
      if (!mounted) return;
      if (!_scrollController.hasClients) return;

      try {
        _scrollController.jumpTo(0);
      } catch (_) {}
    });
  }

  List<String> _extractMessages(
      AsyncSnapshot<List<Map<String, dynamic>>> snap) {
    // ✅ لو في Error: نسيب آخر cache بدل ما نفضي الشريط
    if (snap.hasError) {
      debugPrint('NewsTicker stream error: ${snap.error}');
      return _cachedMessages;
    }

    // ✅ لو مفيش Data (loading / dropped): برضه نسيب cache
    if (!snap.hasData) {
      return _cachedMessages;
    }

    final out = <String>[];

    for (final item in snap.data!) {
      final text = item['text_ar']?.toString().trim();
      if (text != null && text.isNotEmpty) out.add(text);
    }

    // ✅ لو الاستعلام رجّع فاضي لحظيًا: لا تمسح الشريط
    if (out.isEmpty) {
      return _cachedMessages;
    }

    return out;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _service.streamTickerItems(),
      builder: (context, snapshot) {
        final messages = _extractMessages(snapshot);

        // لو لأول مرة ولسه مفيش cache حقيقية
        if (messages.isEmpty) {
          return const SizedBox.shrink();
        }

        // ✅ حدّث cache لما يكون في بيانات فعلية
        if (snapshot.hasData && !snapshot.hasError) {
          // (messages هنا مش فاضي)
          _cachedMessages = messages;
        }

        final signature = messages.join(' | ');
        if (signature != _lastSignature) {
          _lastSignature = signature;
          _scheduleResetToStart();
        }

        // كرر المحتوى لضمان scroll
        final looped = [...messages, ...messages, ...messages, ...messages];

        return Container(
          height: 34,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.secondaryOrange,
            border: Border(
              bottom: BorderSide(
                color: Colors.black.withValues(alpha: 0.15),
                width: 1,
              ),
            ),
          ),
          child: IgnorePointer(
            child: ListView.builder(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: looped.length,
              itemBuilder: (context, index) {
                return Row(
                  children: [
                    _buildText(looped[index]),
                    _divider(),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildText(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Text(
        text,
        style: GoogleFonts.cairo(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _divider() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 26),
      width: 10,
      height: 2.5,
      decoration: BoxDecoration(
        color: const Color(0xFF1A535C),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
