import 'package:audioplayers/audioplayers.dart';

class SoundManager {
  static final AudioPlayer _player = AudioPlayer();

  // تشغيل صوت النجاح
  static Future<void> playSuccess() async {
    await _player.stop(); // إيقاف أي صوت شغال عشان ميسرعوش ورا بعض
    await _player.play(AssetSource('sounds/success.mp3'));
  }

  // تشغيل صوت الخطأ
  static Future<void> playWrong() async {
    await _player.stop();
    await _player.play(AssetSource('sounds/wrong.mp3'));
  }

  // تشغيل صوت النقرة
  static Future<void> playClick() async {
    await _player.stop();
    await _player.play(AssetSource('sounds/click.mp3'));
  }
}
