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
  late ScrollController _scrollController;
  bool _showWelcome = true;

  // السرعة: كلما زاد الرقم زادت السرعة (بكسل في الثانية)
  // القيمة 50 مثالية جداً للقراءة المريحة
  static const double _pixelsPerSecond = 50.0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();

    // إخفاء الترحيب بعد 3 دقائق كما طلبت
    Future.delayed(const Duration(minutes: 3), () {
      if (mounted) setState(() => _showWelcome = false);
    });

    // بدء الحركة بعد استقرار الواجهة
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startScrolling();
    });
  }

  void _startScrolling() {
    if (!_scrollController.hasClients) return;

    // الحصول على أقصى مسافة للتمرير
    double maxScroll = _scrollController.position.maxScrollExtent;

    // حساب الوقت بناءً على المسافة والسرعة الثابتة (Time = Distance / Speed)
    // هذا يضمن ثبات السرعة مهما كان طول النص
    int durationInSeconds = (maxScroll / _pixelsPerSecond).floor();

    _scrollController
        .animateTo(
      maxScroll,
      duration: Duration(seconds: durationInSeconds),
      curve: Curves.linear, // حركة خطية ثابتة بدون تسارع
    )
        .then((_) {
      if (mounted) {
        _scrollController.jumpTo(0); // العودة للبداية فجأة
        _startScrolling(); // إعادة التكرار
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.secondaryOrange,
        border: Border(
          bottom: BorderSide(
            color: Colors.black.withOpacity(0.15),
            width: 1,
          ),
        ),
      ),
      child: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _service.streamTickerItems(),
        builder: (context, snapshot) {
          final List<String> messages = [];

          if (_showWelcome) {
            messages.add("✨ أهلاً بك يا ${widget.userName} في L Pro ✨");
          }

          if (snapshot.hasData) {
            for (final item in snapshot.data!) {
              final text = item['text_ar']?.toString().trim();
              if (text != null && text.isNotEmpty) {
                messages.add(text);
              }
            }
          }

          if (messages.isEmpty) return const SizedBox.shrink();

          // نكرر المحتوى لضمان وجود مسافة كافية للتمرير المستمر
          final looped = [...messages, ...messages, ...messages];

          return IgnorePointer(
            // لمنع المستخدم من لمس الشريط وتعطيل الحركة
            child: ListView.builder(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
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
          );
        },
      ),
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
