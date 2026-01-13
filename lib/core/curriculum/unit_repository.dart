// PATH: lib/core/curriculum/unit_repository.dart

import 'unit_model.dart';

/// ===============================
/// Repository Contract
/// ===============================
abstract class UnitRepository {
  Future<UnitModel> getUnitById(String unitId);
}

/// ===============================
/// Local Placeholder Implementation
/// (مرحلة أولى – بدون Firebase – Zero Cost)
/// ===============================
class LocalUnitRepository implements UnitRepository {
  @override
  Future<UnitModel> getUnitById(String unitId) async {
    // Placeholder منسق — لا محتوى فعلي الآن
    return const UnitModel(
      id: 'unit_demo',
      truthLine: 'الحقيقة اللي محدش بيحب يسمعها…',
      emotionalContext:
          'في لحظة ما، كل واحد فينا حس إنه تايه ومش فاهم هو ماشي صح ولا غلط.',
      closingInsight:
          'الفرق الحقيقي مش في المعلومة… الفرق في القرار اللي هتاخده بعدها.',
      questions: [
        Question(
          id: 'q1',
          text: 'إيه أكتر حاجة معطلاك دلوقتي؟',
          options: [
            'الخوف من الغلط',
            'قلة الخبرة',
            'الضغط المادي',
            'عدم وضوح الطريق',
          ],
        ),
      ],
    );
  }
}
