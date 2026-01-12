import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SilenceScreen extends StatefulWidget {
  const SilenceScreen({super.key});

  @override
  State<SilenceScreen> createState() => _SilenceScreenState();
}

class _SilenceScreenState extends State<SilenceScreen> {
  @override
  void initState() {
    super.initState();
    // بدء مؤقت الإنهاء التلقائي للوحدة
    _startFinalTimer();
  }

  void _startFinalTimer() {
    // التزام بمدة زمنية محددة قبل إغلاق الوحدة نهائياً (4 ثوانٍ)
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        // إرسال حدث الإنهاء للمتحكم (Bloc)
        // ملاحظة: سيقوم الـ Bloc هنا بتبديل الحالة إلى UnitCompleted
        context.read<UnitFlowBloc>().add(NextStep());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      // الشاشة فارغة تماماً لضمان حالة "الصمت البصري"
      backgroundColor: Colors.white,
      body: Center(
        child: SizedBox.shrink(),
      ),
    );
  }
}
