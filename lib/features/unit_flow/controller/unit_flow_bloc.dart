// PATH: lib/features/unit_flow/controller/unit_flow_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/curriculum/unit_model.dart';
import '../../../core/curriculum/unit_repository.dart';

/// EVENTS
abstract class UnitFlowEvent {}

class StartUnit extends UnitFlowEvent {}

class NextStep extends UnitFlowEvent {}

/// للتوافق مع كودك الحالي في InsightScreen
class NextStepEvent extends UnitFlowEvent {}

class SubmitAnswers extends UnitFlowEvent {
  final Map<String, int> answers; // {questionId: selectedOptionIndex}
  SubmitAnswers(this.answers);
}

/// STATES
abstract class UnitFlowState {}

class UnitLoading extends UnitFlowState {}

class TruthLineActive extends UnitFlowState {
  final String text;
  TruthLineActive(this.text);
}

class EmotionalContextActive extends UnitFlowState {
  final String scenario;
  EmotionalContextActive(this.scenario);
}

class QuestionSetActive extends UnitFlowState {
  final List<Question> questions;
  QuestionSetActive(this.questions);
}

class InsightActive extends UnitFlowState {
  final String insight;
  InsightActive(this.insight);
}

class SilenceActive extends UnitFlowState {}

class UnitCompleted extends UnitFlowState {}

/// BLOC
class UnitFlowBloc extends Bloc<UnitFlowEvent, UnitFlowState> {
  final UnitRepository repository;
  final String unitId;

  UnitModel? _unit;

  UnitFlowBloc({
    required this.repository,
    required this.unitId,
  }) : super(UnitLoading()) {
    on<StartUnit>(_onStartUnit);
    on<NextStep>(_onNextStep);
    on<NextStepEvent>(_onNextStepEvent);
    on<SubmitAnswers>(_onSubmitAnswers);
  }

  Future<void> _onStartUnit(
      StartUnit event, Emitter<UnitFlowState> emit) async {
    emit(UnitLoading());

    _unit = await repository.getUnitById(unitId);

    emit(TruthLineActive(_unit!.truthLine));
  }

  void _onNextStep(NextStep event, Emitter<UnitFlowState> emit) {
    final unit = _unit;
    if (unit == null) {
      emit(UnitLoading());
      return;
    }

    final current = state;

    if (current is TruthLineActive) {
      emit(EmotionalContextActive(unit.emotionalContext));
      return;
    }

    if (current is EmotionalContextActive) {
      emit(QuestionSetActive(unit.questions));
      return;
    }

    if (current is SilenceActive) {
      emit(UnitCompleted());
      return;
    }

    // لو وصلنا لهنا، نرجّع للتحميل بأمان
    emit(UnitLoading());
  }

  void _onNextStepEvent(NextStepEvent event, Emitter<UnitFlowState> emit) {
    // نفس سلوك NextStep لكن للمرحلة بين Insight -> Silence
    final unit = _unit;
    if (unit == null) {
      emit(UnitLoading());
      return;
    }

    final current = state;
    if (current is InsightActive) {
      emit(SilenceActive());
      return;
    }

    // fallback آمن
    emit(UnitLoading());
  }

  void _onSubmitAnswers(SubmitAnswers event, Emitter<UnitFlowState> emit) {
    final unit = _unit;
    if (unit == null) {
      emit(UnitLoading());
      return;
    }

    // لا تقييم/عقاب الآن — مجرد انتقال للتثبيت (Insight)
    emit(InsightActive(unit.closingInsight));
  }
}
