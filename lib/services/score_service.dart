import 'dart:convert';
import 'package:http/http.dart' as http;

class ScoreService {
  final String openAiApiKey = String.fromEnvironment('OPENAI_API_KEY');

  Future<Map<String, dynamic>> evaluatePronunciation({
    required String expectedText,
    required String recognizedText,
  }) async {
    final prompt = '''
Compare the following two sentences:
EXPECTED: "$expectedText"
RECOGNIZED: "$recognizedText"

Give feedback on:
1. Is the meaning preserved?
2. Which words are missing or incorrect?
3. Score from 0 to 100 on pronunciation accuracy and fluency.
Return in JSON format like:
{
  "meaning_correct": true,
  "missing_words": ["to"],
  "pronunciation_score": 85,
  "fluency_score": 90
}
''';

    final response = await http.post(
      Uri.parse('https://api.openai.com/v1/chat/completions'),
      headers: {
        'Authorization': 'Bearer $openAiApiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        "model": "gpt-3.5-turbo",
        "messages": [
          {"role": "user", "content": prompt},
        ],
        "temperature": 0.2,
      }),
    );

    if (response.statusCode == 200) {
      final jsonBody = json.decode(response.body);
      final gptContent = jsonBody["choices"][0]["message"]["content"];
      final gptResult = json.decode(gptContent);

      final pronunciation = gptResult['pronunciation_score'] ?? 0;
      final fluency = gptResult['fluency_score'] ?? 0;
      final accuracy = gptResult['meaning_correct'] == true ? 100 : 60;

      final overall =
          ((pronunciation * 0.4) + (fluency * 0.3) + (accuracy * 0.3)).round();

      return {
        "overall_score": overall,
        "pronunciation_score": pronunciation,
        "fluency_score": fluency,
        "accuracy_score": accuracy,
      };
    } else {
      throw Exception('GPT 評分失敗: ${response.body}');
    }
  }
}
