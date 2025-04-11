import 'package:flutter_sound/flutter_sound.dart';
import 'dart:io';

class AudioPlayerService {
  final FlutterSoundPlayer _player = FlutterSoundPlayer();
  bool _isPlayerInitialized = false;

  Future<void> initPlayer() async {
    if (!_isPlayerInitialized) {
      await _player.openPlayer();
      _isPlayerInitialized = true;
    }
  }

  Future<void> play(String filePath) async {
    if (!_isPlayerInitialized) await initPlayer();

    if (!File(filePath).existsSync()) {
      print("❌ 音檔不存在：$filePath");
      return;
    }

    await _player.startPlayer(
      fromURI: filePath,
      codec: Codec.aacADTS,
      whenFinished: () {
        print("🎧 播放結束");
      },
    );

    print("▶️ 開始播放音檔：$filePath");
  }

  Future<void> stop() async {
    if (_player.isPlaying) {
      await _player.stopPlayer();
      print("⏹️ 已停止播放");
    }
  }

  void dispose() {
    _player.closePlayer();
    _isPlayerInitialized = false;
  }
}
