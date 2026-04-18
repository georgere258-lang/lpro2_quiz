// PATH: lib/features/news_ticker/presentation/news_ticker_widget.dart
// STATUS: ULTRA-OPTIMIZED (Static Stream / Zero Extra Consumption) ✅

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/news_ticker_service.dart';

class NewsTickerWidget extends StatefulWidget {
  final String userName;
  const NewsTickerWidget({super.key, required this.userName});

  @override
  State<NewsTickerWidget> createState() => _NewsTickerWidgetState();
}

class _NewsTickerWidgetState extends State<NewsTickerWidget> {
  final NewsTickerService _service = NewsTickerService();
  late final ScrollController _scrollController;

  // ✅ تعريف الـ Stream هنا لضمان فتحه مرة واحدة فقط عند بداية تشغيل الودجت
  late final Stream<List<Map<String, dynamic>>> _newsStream;

  static const double _pixelsPerSecond = 35.0;
  static const Duration _tick = Duration(milliseconds: 16);

  Timer? _timer;
  List<String> _cachedMessages = const [];
  String _lastSignature = '';
  bool _resetScheduled = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();

    // ✅ تهيئة المستمع اللحظي مرة واحدة فقط عند الدخول
    _newsStream = _service.streamTickerItems();

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
    } catch (_) {}
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
    if (snap.hasError) return _cachedMessages;
    if (!snap.hasData) return _cachedMessages;

    final out = <String>[];
    for (final item in snap.data!) {
      final text = item['text_ar']?.toString().trim();
      if (text != null && text.isNotEmpty) out.add(text);
    }
    return out.isEmpty ? _cachedMessages : out;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      // ✅ نستخدم الـ Stream الثابت المسجل في الذاكرة
      stream: _newsStream,
      builder: (context, snapshot) {
        final messages = _extractMessages(snapshot);
        if (messages.isEmpty) return const SizedBox.shrink();

        if (snapshot.hasData && !snapshot.hasError) {
          _cachedMessages = messages;
        }

        final signature = messages.join(' | ');
        if (signature != _lastSignature) {
          _lastSignature = signature;
          _scheduleResetToStart();
        }

        final looped = [...messages, ...messages, ...messages, ...messages];

        return Container(
          height: 34,
          width: double.infinity,
          color: Colors.transparent,
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
          fontSize: 12.5,
          fontWeight: FontWeight.w800,
          height: 1.2,
          color: const Color(0xFFFDFBF7),
          shadows: [
            Shadow(
              color: Colors.black.withValues(alpha: 0.15),
              offset: const Offset(0, 1),
              blurRadius: 1,
            ),
          ],
        ),
      ),
    );
  }

  Widget _divider() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 22),
      width: 8,
      height: 3,
      decoration: BoxDecoration(
        color: AppColors.secondaryOrange.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
