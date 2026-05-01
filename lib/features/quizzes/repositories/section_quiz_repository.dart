// PATH: lib/features/quizzes/repositories/section_quiz_repository.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hive_flutter/hive_flutter.dart';
import '../models/user_question_record.dart';
import 'package:hive/hive.dart';
import '../models/section_quiz_model.dart';

class SectionQuizRepository {
  final String _baseUrl =
      'https://raw.githubusercontent.com/georgere258-lang/lpro-academy-data/refs/heads/main/';

  static const String _settingsBoxName = 'app_settings';
  static const String _recordsBoxName = 'question_records';

  Future<List<SectionQuiz>> getQuestions(String category) async {
    final bool isMarket = category == 'سوق العقار';
    final String fileName = isMarket ? 'market.json' : 'sales.json';
    final String versionKey = isMarket ? 'market_version' : 'sales_version';

    final settingsBox = await Hive.openBox(_settingsBoxName);
    final Box<UserQuestionRecord> recordsBox =
        await Hive.openBox<UserQuestionRecord>(_recordsBoxName);

    try {
      final versionRes =
          await http.get(Uri.parse('${_baseUrl}versioning.json'));

      if (versionRes.statusCode == 200) {
        final Map<String, dynamic> versionData = json.decode(versionRes.body);
        final int remoteVersion = versionData[versionKey] ?? 0;
        final int localVersion =
            settingsBox.get('ver_$category', defaultValue: 0);

        String jsonString;

        if (remoteVersion > localVersion) {
          final response = await http.get(Uri.parse('$_baseUrl$fileName'));
          if (response.statusCode == 200) {
            jsonString = response.body;
            await settingsBox.put('cache_$category', jsonString);
            await settingsBox.put('ver_$category', remoteVersion);
          } else {
            jsonString = settingsBox.get('cache_$category', defaultValue: '[]');
          }
        } else {
          jsonString = settingsBox.get('cache_$category', defaultValue: '[]');
        }

        final List<dynamic> data = json.decode(jsonString);
        List<SectionQuiz> allQuestions =
            data.map((q) => SectionQuiz.fromJson(q)).toList();

        // تطبيق خوارزمية المنخل الذكي (3-1-1)
        return _pickSmartQuestions(allQuestions, recordsBox);
      } else {
        final cached = settingsBox.get('cache_$category', defaultValue: '[]');
        return (json.decode(cached) as List)
            .map((q) => SectionQuiz.fromJson(q))
            .toList();
      }
    } catch (e) {
      return [];
    }
  }

  /// خوارزمية المنخل الذكي: تفرض نسبة (3 جديد + 1 خطأ + 1 مراجعة)
  List<SectionQuiz> _pickSmartQuestions(
      List<SectionQuiz> all, Box<UserQuestionRecord> box) {
    final now = DateTime.now();
    List<SectionQuiz> selected = [];

    // 1. جلب 3 نقاط جديدة (لم يسبق حلها)
    final unseen = all.where((q) => !box.containsKey(q.id)).toList();
    unseen.shuffle();
    selected.addAll(unseen.take(3));

    // 2. جلب نقطة واحدة من خزنة الأخطاء (التي حان وقت مراجعتها)
    final dueMistakes = all.where((q) {
      final r = box.get(q.id);
      return r != null &&
          r.wasCorrect == false &&
          now.difference(r.lastSeen).inDays >= r.dueInDays &&
          !selected.contains(q);
    }).toList();
    dueMistakes.shuffle();
    selected.addAll(dueMistakes.take(1));

    // 3. جلب نقطة واحدة من المراجعة الدورية (إجابات صحيحة قديمة لتثبيتها)
    final dueReview = all.where((q) {
      final r = box.get(q.id);
      return r != null &&
          r.wasCorrect == true &&
          now.difference(r.lastSeen).inDays >= r.dueInDays &&
          !selected.contains(q);
    }).toList();
    dueReview.shuffle();
    selected.addAll(dueReview.take(1));

    // 4. شبكة الأمان (Safety Net): إذا لم تكتمل الـ 5 نقاط (بسبب قلة الأخطاء أو المراجعات)
    // نقوم بملء المتبقي من أي أسئلة لم يتم اختيارها بعد
    if (selected.length < 5) {
      final remaining = all.where((q) => !selected.contains(q)).toList();
      remaining.shuffle();
      selected.addAll(remaining.take(5 - selected.length));
    }

    // الخطوة الأخيرة: بعثرة الـ 5 المختارين لكي لا يعرف الموظف ترتيب (الجديد/القديم)
    selected.shuffle();
    return selected;
  }
}
