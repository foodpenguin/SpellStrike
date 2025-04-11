import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class WhisperService {
  final String apiKey = 'hf_xxxxxxxxxxxxxxxxxxxxxxxx'; // 換成你自己的 Token
  final String modelUrl = 'https://api-inference.huggingface.co/models/openai/whisper-large-v3';

  // 傳送錄音檔並將回傳的文字寫入 txt 檔
  Future<File?> transcribeAudioAndSave(File audioFile) async {
    try {
      final bytes = await audioFile.readAsBytes();
      final response = await http.post(
        Uri.parse(modelUrl),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'audio/aac', // 根據你實際錄音格式調整
        },
        body: bytes,
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        final transcript = decoded['text'];

        // 儲存為 .txt 檔案
        final dir = await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/transcription.txt');
        await file.writeAsString(transcript);

        print('📄 成功儲存轉譯文字到：${file.path}');
        return file;
      } else {
        print('❌ 語音辨識失敗，狀態碼: ${response.statusCode}');
        print('回應內容: ${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ 發生錯誤: $e');
      return null;
    }
  }

  // 回傳 transcription.txt 的完整路徑
  Future<String> getTranscriptFilePath() async {
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/transcription.txt';
  }
}