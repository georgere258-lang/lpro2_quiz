// PATH: lib/features/news_ticker/presentation/news_ticker_widget.dart
// STATUS: ULTRA-PREMIUM UPGRADE (Visual Depth & Digital Gradient)

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
      stream: _service.streamTickerItems(),
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
          // ✅ التحسين الجوهري: إضافة تدرج لوني وعمق بصري للشريط
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.secondaryOrange, // لون الأساس
                AppColors.secondaryOrange.withValues(alpha: 0.85), // تدرج للعمق
              ],
            ),
            boxShadow: [
              // ظل علوي داخلي خفيف لإعطاء إيحاء بالاحتواء (Inset Effect)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                offset: const Offset(0, 1),
                blurRadius: 2,
                spreadRadius: 0,
              ),
            ],
            border: Border(
              bottom: BorderSide(
                color: Colors.black.withValues(alpha: 0.1),
                width: 0.5,
              ),
            ),
          ),
          child: Stack(
            children: [
              // الطبقة الشفافة العلوية لزيادة اللمعان (Premium Sheen)
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.0, 0.5],
                    colors: [
                      Colors.white.withValues(alpha: 0.12),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              IgnorePointer(
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
            ],
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
          fontSize: 12.5, // تكبير طفيف جداً للوضوح
          fontWeight: FontWeight.w800,
          color: Colors.white,
          // إضافة ظل خفيف جداً للنص لزيادة التباين
          shadows: [
            Shadow(
              color: Colors.black.withValues(alpha: 0.2),
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
      margin: const EdgeInsets.symmetric(
          horizontal: 22), // تقليل المسافة لرشاقة أكبر
      width: 8,
      height: 3,
      decoration: BoxDecoration(
        // استخدام تدرج داخل الفاصل لجعله يبدو "محفوراً"
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1A535C),
            const Color(0xFF1A535C).withValues(alpha: 0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.1),
            offset: const Offset(0, 1),
          ),
        ],
      ),
    );
  }
}
