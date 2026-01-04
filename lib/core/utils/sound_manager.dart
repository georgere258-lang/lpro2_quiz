import 'package:audioplayers/audioplayers.dart';

class SoundManager {
  static final AudioPlayer _player = AudioPlayer();

  // تهيئة الإعدادات (تستدعى في main.dart)
  static void init() {
    _player.setReleaseMode(ReleaseMode.stop);
  }

  // دالة تشغيل صوت الإجابة الصحيحة
  static void playCorrect() async {
    try {
      await _player.stop(); // إيقاف أي صوت حالي
      await _player.setVolume(0.8); // مستوى صوت متوازن للنجاح
      await _player.play(AssetSource('sounds/correct.mp3'));
    } catch (e) {
      print("Sound Play Error: $e");
    }
  }

  // دالة تشغيل صوت الإجابة الخاطئة (معدلة لرفع الشدة)
  static void playWrong() async {
    try {
      await _player.stop(); // إيقاف فوري لضمان انطلاق صوت التنبيه
      await _player.setVolume(1.0); // رفع الصوت للحد الأقصى (100%)
      await _player.play(AssetSource('sounds/wrong.mp3'));
    } catch (e) {
      print("Sound Play Error: $e");
    }
  }

  // صوت النقر العام في التطبيق
  static void playTap() async {
    try {
      await _player.setVolume(0.4);
      await _player.play(AssetSource('sounds/tap.mp3'));
    } catch (e) {
      print("Sound Play Error: $e");
    }
  }
}
