import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class SpeechService {
  final String openAiApiKey = String.fromEnvironment('OPENAI_API_KEY');

  Future<String> convertAudioToText(String audioPath) async {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('https://api.openai.com/v1/audio/transcriptions'),
    );

    request.headers['Authorization'] = 'Bearer $openAiApiKey';
    request.files.add(await http.MultipartFile.fromPath('file', audioPath));
    request.fields['model'] = 'whisper-1';

    var response = await request.send();

    if (response.statusCode == 200) {
      var responseBody = await response.stream.bytesToString();
      var jsonData = json.decode(responseBody);
      return jsonData['text'];
    } else {
      throw Exception('轉換失敗，錯誤碼：${response.statusCode}');
    }
  }
}
