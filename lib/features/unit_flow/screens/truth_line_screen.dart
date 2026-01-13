// PATH: lib/features/unit_flow/screens/truth_line_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../controller/unit_flow_bloc.dart';

class TruthLineScreen extends StatefulWidget {
  final String truthLineText;

  const TruthLineScreen({
    super.key,
    required this.truthLineText,
  });

  @override
  State<TruthLineScreen> createState() => _TruthLineScreenState();
}

class _TruthLineScreenState extends State<TruthLineScreen> {
  @override
  void initState() {
    super.initState();
    // بدء الانتقال التلقائي الإلزامي بعد ثانيتين
    _initiateAutoTransition();
  }

  void _initiateAutoTransition() {
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        // إرسال حدث الانتقال إلى الخطوة الثانية (EmotionalContextScreen)
        context.read<UnitFlowBloc>().add(NextStep());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // الشاشة صامتة تماماً لضمان التركيز الذهني
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Center(
            child: Text(
              widget.truthLineText,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                height: 1.5,
                color: Colors.black,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
