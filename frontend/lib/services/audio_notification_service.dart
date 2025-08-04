import 'package:audioplayers/audioplayers.dart';

class AudioNotificationService {
  final AudioPlayer _audioPlayer = AudioPlayer();

  Future<void> playNewOrderSound() async {
    try {
      await _audioPlayer.play(AssetSource('sounds/new_order.m4a'));
    } catch (e) {
      // ignore: avoid_print
      print("Error playing sound: $e");
    }
  }

  void dispose() {
    _audioPlayer.dispose();
  }
}
