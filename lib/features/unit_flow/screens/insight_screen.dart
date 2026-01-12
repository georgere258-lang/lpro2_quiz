import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class InsightScreen extends StatefulWidget {
  final String insightText;

  const InsightScreen({
    super.key,
    required this.insightText,
  });

  @override
  State<InsightScreen> createState() => _InsightScreenState();
}

class _InsightScreenState extends State<InsightScreen> {
  @override
  void initState() {
    super.initState();
    // تنفيذ الانتقال التلقائي بعد مرور الحد الأدنى للزمن (3 ثواني)
    _startAutoNavigation();
  }

  void _startAutoNavigation() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        // إرسال حدث للمتحكم للانتقال إلى شاشة الصمت (SilenceScreen)
        context.read<UnitFlowBloc>().add(NextStepEvent());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // الشاشة صامتة تماماً بدون AppBar أو أزرار تفاعل
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Center(
            child: Text(
              widget.insightText,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                height: 1.6,
                fontStyle: FontStyle.italic,
                color: Colors.black87,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
