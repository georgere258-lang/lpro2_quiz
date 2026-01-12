import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class EmotionalContextScreen extends StatelessWidget {
  final String scenarioText;

  const EmotionalContextScreen({
    super.key,
    required this.scenarioText,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: Text(
                      scenarioText,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 19,
                        height: 1.7,
                        fontWeight: FontWeight.w400,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              // زر هادئ للانتقال الإرادي بعد القراءة
              TextButton(
                onPressed: () {
                  context.read<UnitFlowBloc>().add(NextStep());
                },
                child: const Text(
                  "متابعة",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.blueGrey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
