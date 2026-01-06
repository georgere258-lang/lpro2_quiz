import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class SoundManager {
  static bool isMuted = false;
  // مشغل واحد ثابت نستخدمه في كل التطبيق
  static final AudioPlayer _player = AudioPlayer();

  static void init() {
    debugPrint("🔊 Sound Engine Initialized");
  }

  static Future<void> _playSound(String fileName) async {
    if (isMuted) return;
    try {
      // إيقاف أي صوت شغال حالياً قبل البدء
      await _player.stop();
      // تشغيل الصوت من المسار المعرف في الـ pubspec
      await _player.play(AssetSource('sounds/$fileName'));
    } catch (e) {
      debugPrint("❌ Audio Error ($fileName): $e");
    }
  }

  static Future<void> playTap() async => await _playSound('click.mp3');
  static Future<void> playCorrect() async => await _playSound('success.mp3');
  static Future<void> playWrong() async => await _playSound('wrong.mp3');
}
