import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'screens/truth_line_screen.dart';
import 'screens/emotional_context_screen.dart';
import 'screens/question_set_screen.dart';
import 'screens/insight_screen.dart';
import 'screens/silence_screen.dart';
import '../../../core/curriculum/unit_repository.dart';

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
            // إغلاق الصفحة بهدوء فور اكتمال الوحدة
            Navigator.pop(context);
          }
        },
        child: PopScope(
          canPop: false, // منع الخروج العشوائي للحفاظ على سلامة التدفق
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
                  return QuestionSetScreen(questions: state.questions);
                }
                if (state is InsightActive) {
                  return InsightScreen(insightText: state.insight);
                }
                if (state is SilenceActive) {
                  return const SilenceScreen();
                }
                // حالة التحميل الأولية
                return const Center(child: CircularProgressIndicator());
              },
            ),
          ),
        ),
      ),
    );
  }
}
