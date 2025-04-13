
import 'dart:convert';
import 'dart:io';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:async'; // 確保導入 dart:async


class AudioRecorder {
  FlutterSoundRecorder? _recorder;
  bool _isRecording = false;
  String? _recordedFilePath;


  /// 初始化錄音器，並請求麥克風權限
  Future<void> initRecorder() async {
    try {
      _recorder = FlutterSoundRecorder();
      await _recorder!.openRecorder();
      var status = await Permission.microphone.request();
      if (!status.isGranted) {
        print("❌ 麥克風權限未授權");
      }
    } catch (e) {
      print("❌ initRecorder 發生錯誤: $e");
    }
  }

  /// 開始錄音，將音檔儲存至臨時目錄
  Future<void> startRecording() async {
    if (_isRecording) return;
    try {
      final dir = await getTemporaryDirectory();
      String path = '${dir.path}/voice_record.aac';
      await _recorder!.startRecorder(toFile: path, codec: Codec.aacADTS);
      _isRecording = true;
      _recordedFilePath = path;
      print("🎤 錄音開始... 儲存到: $path");
    } catch (e) {
      print("❌ startRecording 發生錯誤: $e");
    }
  }

  /// 停止錄音並進行分析（轉譯與評分）
  Future<void> stopRecordingAndEvaluate() async {
    if (!_isRecording) return;
    try {
      await _recorder!.stopRecorder();
      _isRecording = false;
      print("✅ 錄音完成，檔案儲存路徑: $_recordedFilePath");

      if (_recordedFilePath != null) {
        final text = await _transcribeAudioToText(_recordedFilePath!);
        if (text != null) {
          print("📝 Whisper 譯文: $text");
          final evaluation = await _evaluateEnglish(text);
          if (evaluation != null) {
            print("📊 GPT 評分結果:\n$evaluation");
          } else {
            print("❌ GPT 評分結果取得失敗");
          }
        } else {
          print("❌ Whisper 轉譯結果為空或轉譯失敗");
        }
      }
    } catch (e) {
      print("❌ stopRecordingAndEvaluate 發生錯誤: $e");
    }
  }

  /// 呼叫 OpenAI Whisper API 進行語音轉文字 (加入重試機制)
  Future<String?> _transcribeAudioToText(String filePath) async {
    final apiKey = dotenv.env['GPT_KEY'];
    if (apiKey == null) {
      print("❌ API 金鑰不存在，請確認 .env 中有 GPT_KEY");
      return null;
    }

    int retries = 0;
    const maxRetries = 3; // 最多重試 3 次
    const initialDelay = Duration(seconds: 1); // 初始延遲 1 秒

    while (retries < maxRetries) {
      try {
        var request = http.MultipartRequest(
          'POST',
          Uri.parse('https://api.openai.com/v1/audio/transcriptions'),
        );
        request.headers['Authorization'] = 'Bearer $apiKey';
        request.files.add(
          await http.MultipartFile.fromPath(
            'file', // 欄位名稱應為 'file'
            filePath,
            contentType: MediaType('audio', 'aac'),
          ),
        );
        request.fields['model'] = 'whisper-1';

        print("🚀 正在嘗試轉譯音檔 (第 ${retries + 1} 次)...");
        var response = await request.send();

        if (response.statusCode == 200) {
          final resBody = await response.stream.bytesToString();
          print("✅ Whisper 轉譯成功");
          return jsonDecode(resBody)['text'];
        } else if (response.statusCode == 429) {
          retries++;
          if (retries >= maxRetries) {
            print("❌ Whisper 轉譯失敗: ${response.statusCode} (已達最大重試次數)");
            final errorBody = await response.stream.bytesToString(); // 嘗試讀取錯誤內容
            print("錯誤內容: $errorBody");
            return null;
          }
          // 指數退避：等待時間 = 初始延遲 * 2^(重試次數-1)
          final delay = initialDelay * (1 << (retries - 1));
          print(
            "⏳ Whisper API 速率限制 (429)，將在 ${delay.inSeconds} 秒後重試 ($retries/$maxRetries)...",
          );
          await Future.delayed(delay); // 等待後重試
        } else {
          // 其他 HTTP 錯誤
          final errorBody = await response.stream.bytesToString();
          print("❌ Whisper 轉譯失敗: ${response.statusCode}, 錯誤內容: $errorBody");
          return null; // 不重試其他錯誤，直接返回 null
        }
      } catch (e) {
        // 網路或其他例外錯誤
        print("❌ _transcribeAudioToText 發生例外錯誤: $e");
        // 也可以考慮在此處加入重試邏輯，但通常針對特定 HTTP 錯誤重試更有效
        return null;
      }
    }
    // 如果迴圈結束仍未成功 (理論上應該在迴圈內返回)
    print("❌ Whisper 轉譯在重試後仍然失敗");
    return null;
  }

  /// 呼叫 OpenAI GPT API 根據轉譯結果給出評分 (同樣可以考慮加入重試)
  Future<String?> _evaluateEnglish(String text) async {
    final apiKey = dotenv.env['GPT_KEY'];
    if (apiKey == null) {
      print("❌ API 金鑰不存在");
      return null;
    }

    // --- GPT API 也可以加入類似的重試邏輯 ---
    int retries = 0;
    const maxRetries = 3;
    const initialDelay = Duration(seconds: 1);

    while (retries < maxRetries) {
      try {
        final response = await http.post(
          Uri.parse('https://api.openai.com/v1/chat/completions'),
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            "model": "gpt-3.5-turbo",
            "messages": [
              {
                "role": "system",
                "content":
                    "你是一位專業英文口說教師，請根據學生說的內容提供英文發音與語法評分（滿分10分），請列出優點與缺點並給一段建議。",
              },
              {"role": "user", "content": text},
            ],
          }),
        );

        if (response.statusCode == 200) {
          final result = jsonDecode(response.body);
          print("✅ GPT 評分成功");
          return result['choices'][0]['message']['content'];
        } else if (response.statusCode == 429) {
          retries++;
          if (retries >= maxRetries) {
            print("❌ GPT 評分失敗: ${response.statusCode} (已達最大重試次數)");
            print("錯誤內容: ${response.body}");
            return null;
          }
          final delay = initialDelay * (1 << (retries - 1));
          print(
            "⏳ GPT API 速率限制 (429)，將在 ${delay.inSeconds} 秒後重試 ($retries/$maxRetries)...",
          );
          await Future.delayed(delay);
        } else {
          print("❌ GPT 評分失敗: ${response.statusCode}, 錯誤內容: ${response.body}");
          return null; // 其他錯誤直接返回
        }
      } catch (e) {
        print("❌ _evaluateEnglish 發生例外錯誤: $e");
        return null;
      }
    }
    print("❌ GPT 評分在重試後仍然失敗");
    return null;
  }

  // 取得錄音檔案路徑
  String? getRecordedFilePath() {
    return _recordedFilePath;
  }


  // 判斷是否正在錄音
  bool get isRecording => _isRecording;

  // 釋放錄音器資源
  void dispose() {
    _recorder?.closeRecorder();
  }

}
