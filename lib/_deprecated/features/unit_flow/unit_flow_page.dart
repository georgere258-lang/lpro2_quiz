// PATH: lib/features/unit_flow/unit_flow_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'controller/unit_flow_bloc.dart';
import 'screens/truth_line_screen.dart';
import 'screens/emotional_context_screen.dart';
import 'screens/question_set_screen.dart';
import 'screens/insight_screen.dart';
import 'screens/silence_screen.dart';

import '../../core/curriculum/unit_repository.dart';

class UnitFlowPage extends StatelessWidget {
  final String unitId;

  const UnitFlowPage({
    super.key,
    required this.unitId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => UnitFlowBloc(
        repository: context.read<UnitRepository>(),
        unitId: unitId,
      )..add(StartUnit()),
      child: BlocListener<UnitFlowBloc, UnitFlowState>(
        listenWhen: (previous, current) => current is UnitCompleted,
        listener: (context, state) {
          if (state is UnitCompleted) {
            Navigator.pop(context);
          }
        },
        child: PopScope(
          canPop: false,
          child: Scaffold(
            body: BlocBuilder<UnitFlowBloc, UnitFlowState>(
              builder: (context, state) {
                if (state is TruthLineActive) {
                  return TruthLineScreen(truthLineText: state.text);
                }
                if (state is EmotionalContextActive) {
                  return EmotionalContextScreen(scenarioText: state.scenario);
                }
                if (state is QuestionSetActive) {
                  if (state.questions.isEmpty) {
                    return const Center(
                      child: SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  }
                  return QuestionSetScreen(questions: state.questions);
                }
                if (state is InsightActive) {
                  return InsightScreen(insightText: state.insight);
                }
                if (state is SilenceActive) {
                  return const SilenceScreen();
                }
                return const Center(
                  child: SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
