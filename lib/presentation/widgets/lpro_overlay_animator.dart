import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class LProOverlayAnimator extends StatelessWidget {
  final bool isSuccess;

  const LProOverlayAnimator({super.key, required this.isSuccess});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Lottie.asset(
        isSuccess ? 'assets/lottie/success.json' : 'assets/lottie/error.json',
        width: 200,
        height: 200,
        repeat: false, // يعمل مرة واحدة فقط
      ),
    );
  }
}
