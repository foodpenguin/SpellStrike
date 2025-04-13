import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class AudioRecorder {
  FlutterSoundRecorder? _recorder;
  bool _isRecording = false;
  String? _recordedFilePath;

  // 初始化錄音器，並請求麥克風權限
  Future<void> initRecorder() async {
    _recorder = FlutterSoundRecorder();
    await _recorder!.openRecorder();
    await Permission.microphone.request();
  }

  // 開始錄音
  Future<void> startRecording() async {
    if (_isRecording) return; // 防止重複開始錄音

    final dir = await getTemporaryDirectory();
    String path = '${dir.path}/voice_record.aac';

    await _recorder!.startRecorder(toFile: path, codec: Codec.aacADTS);

    _isRecording = true;
    _recordedFilePath = path;

    print("🎤 錄音開始... 儲存到: $path");
  }

  // 停止錄音
  Future<void> stopRecording() async {
    if (!_isRecording) return; // 防止停止未開始的錄音

    await _recorder!.stopRecorder();

    _isRecording = false;

    print("✅ 錄音完成，檔案儲存路徑: $_recordedFilePath");
  }

  // 取得錄音檔案路徑
  String? getRecordedFilePath() {
    return _recordedFilePath;
  }

  // 確保錄音器釋放資源
  void dispose() {
    _recorder?.closeRecorder();
  }

  // 判斷目前是否正在錄音
  bool get isRecording => _isRecording;
}
