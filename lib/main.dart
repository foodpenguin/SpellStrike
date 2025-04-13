import 'dart:async';
import 'dart:io';
import 'dart:convert'; // Keep utf8 for GPT response decoding
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:csv/csv.dart'; // <--- Import the CSV package

/// 評分結果物件，包含評分（滿分10）與回饋內容
class EvaluationResult {
  final int score; // 評分（0~10）
  final String feedback;
  EvaluationResult({required this.score, required this.feedback});

  @override
  String toString() {
    return 'Score: $score, Feedback: $feedback';
  }
}

/// 錄音器整合，包含錄音、語音轉文字與 GPT 評分
class AudioRecorder {
  FlutterSoundRecorder? _recorder;
  bool _isRecording = false;
  String? _recordedFilePath;

  /// 初始化錄音器並請求麥克風權限
  Future<void> initRecorder() async {
    _recorder = FlutterSoundRecorder();
    await _recorder!.openRecorder();
    await Permission.microphone.request();
  }

  /// 開始錄音，錄音檔暫存至臨時資料夾
  Future<void> startRecording() async {
    if (_isRecording) return;
    final dir = await getTemporaryDirectory();
    // --- 修改檔案名稱和編碼 ---
    String path = '${dir.path}/voice_record.m4a'; // <--- 改為 .m4a
    await _recorder!.startRecorder(
      toFile: path,
      codec: Codec.aacMP4, // <--- 改用 aacMP4 (產生 .m4a)
    );
    // --- 修改結束 ---
    _isRecording = true;
    _recordedFilePath = path;
    print("🎤 錄音開始... 儲存到: $path");
  }

  /// 停止錄音，並進行語音轉文字及 GPT 評分，回傳 [EvaluationResult]
  Future<EvaluationResult?> stopRecordingAndEvaluate() async {
    if (!_isRecording) return null;
    try {
      await _recorder!.stopRecorder();
    } catch (e) {
      print("❌ stopRecorder 發生錯誤: $e");
      _isRecording = false;
      return null;
    }
    _isRecording = false;
    print("✅ 錄音完成，檔案儲存路徑: $_recordedFilePath");

    if (_recordedFilePath != null && File(_recordedFilePath!).existsSync()) {
      final transcription = await _transcribeAudioToText(_recordedFilePath!);
      if (transcription != null) {
        print("📝 Whisper 譯文: $transcription");
        final evaluation = await _evaluateEnglish(transcription);
        print("📊 GPT 評分結果: $evaluation");
        return evaluation;
      } else {
        print("❌ Whisper 轉譯結果為空或轉譯失敗");
      }
    } else {
      print("❌ 錄音檔案不存在或路徑為空: $_recordedFilePath");
    }
    return null;
  }

  /// 呼叫 OpenAI Whisper API 將音檔轉換為文字 (加入重試機制)
  Future<String?> _transcribeAudioToText(String filePath) async {
    final apiKey = dotenv.env['GPT_KEY'];
    if (apiKey == null) {
      print("❌ API 金鑰不存在，請確認 .env 中有 GPT_KEY");
      return null;
    }

    int retries = 0;
    const maxRetries = 3;
    const initialDelay = Duration(seconds: 1);

    while (retries < maxRetries) {
      try {
        var request = http.MultipartRequest(
          'POST',
          Uri.parse('https://api.openai.com/v1/audio/transcriptions'),
        );
        request.headers['Authorization'] = 'Bearer $apiKey';
        request.files.add(
          await http.MultipartFile.fromPath(
            'file',
            filePath,
            // --- 修改 ContentType ---
            contentType: MediaType('audio', 'm4a'), // <--- 改為 m4a
            // --- 修改結束 ---
          ),
        );
        request.fields['model'] = 'whisper-1';

        print("🚀 [Whisper] 正在嘗試轉譯音檔 (第 ${retries + 1} 次)...");
        var response = await request.send();

        if (response.statusCode == 200) {
          final resBody = await response.stream.bytesToString();
          print("✅ [Whisper] 轉譯成功");
          return jsonDecode(resBody)['text'];
        } else if (response.statusCode == 429) {
          retries++;
          if (retries >= maxRetries) {
            print("❌ [Whisper] 轉譯失敗: ${response.statusCode} (已達最大重試次數)");
            final errorBody = await response.stream.bytesToString();
            print("錯誤內容: $errorBody");
            return null;
          }
          final delay =
              initialDelay * (1 << (retries - 1)); // Exponential backoff
          print(
            "⏳ [Whisper] API 速率限制 (429)，將在 ${delay.inSeconds} 秒後重試 ($retries/$maxRetries)...",
          );
          await Future.delayed(delay);
        } else {
          // --- 修改：在其他錯誤時也印出錯誤內容 ---
          final errorBody = await response.stream.bytesToString();
          print("❌ [Whisper] 轉譯失敗: ${response.statusCode}, 錯誤內容: $errorBody");
          return null; // 其他錯誤直接返回
          // --- 修改結束 ---
        }
      } catch (e) {
        print("❌ [Whisper] _transcribeAudioToText 發生例外錯誤: $e");
        // 考慮是否在特定網路錯誤下重試
        retries++; // 發生例外也計入重試，避免無限迴圈
        if (retries >= maxRetries) {
          print("❌ [Whisper] 例外錯誤達到最大重試次數");
          return null;
        }
        final delay = initialDelay * (1 << (retries - 1));
        print(
          "⏳ [Whisper] 發生例外，將在 ${delay.inSeconds} 秒後重試 ($retries/$maxRetries)...",
        );
        await Future.delayed(delay);
        // return null; // 如果不想在例外時重試，則取消註解此行並移除上面的重試邏輯
      }
    }
    print("❌ [Whisper] 轉譯在重試後仍然失敗");
    return null;
  }

  /// 呼叫 OpenAI GPT API，要求以 JSON 格式回傳評分結果（score 與 feedback）(加入重試機制)
  Future<EvaluationResult?> _evaluateEnglish(String text) async {
    final apiKey = dotenv.env['GPT_KEY'];
    if (apiKey == null) {
      print("❌ API 金鑰不存在");
      return null;
    }

    int retries = 0;
    const maxRetries = 3;
    const initialDelay = Duration(seconds: 1);

    while (retries < maxRetries) {
      try {
        print("🚀 [GPT] 正在嘗試評分 (第 ${retries + 1} 次)...");
        final response = await http
            .post(
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
                        "你是一位專業英文口說教師，請根據學生的英文發音與語法表現評分（滿分10分）。請回傳有效的 JSON 格式，只包含兩個欄位：score（數字）與 feedback（文字），例如：{\"score\": 8, \"feedback\": \"發音不錯，但語法有待改善。\"}。請勿包含多餘文字。",
                  },
                  {"role": "user", "content": text},
                ],
              }),
            )
            .timeout(const Duration(seconds: 30)); // 設定超時

        if (response.statusCode == 200) {
          try {
            final result = jsonDecode(
              utf8.decode(response.bodyBytes),
            ); // 使用 utf8 解碼確保中文正常
            final content = result['choices'][0]['message']['content'];
            final parsed = jsonDecode(content); // 解析 GPT 回傳內容中的 JSON 字串
            final int score =
                parsed['score'] is int
                    ? parsed['score']
                    : int.tryParse(parsed['score'].toString()) ?? 0; // 更安全的型別轉換
            final String feedback =
                parsed['feedback'] ?? "No feedback provided.";
            print("✅ [GPT] 評分成功");
            return EvaluationResult(score: score, feedback: feedback);
          } catch (e) {
            print("❌ [GPT] 解析結果失敗: $e");
            print("原始回應內容: ${response.body}"); // 印出原始回應方便除錯
            // 解析失敗也視為一種錯誤，進行重試
            retries++;
            if (retries >= maxRetries) {
              print("❌ [GPT] 解析失敗達到最大重試次數");
              return null;
            }
            final delay = initialDelay * (1 << (retries - 1));
            print(
              "⏳ [GPT] 解析失敗，將在 ${delay.inSeconds} 秒後重試 ($retries/$maxRetries)...",
            );
            await Future.delayed(delay);
            // return null; // 如果不想重試解析錯誤，則取消註解此行
          }
        } else if (response.statusCode == 429) {
          retries++;
          if (retries >= maxRetries) {
            print("❌ [GPT] 評分失敗: ${response.statusCode} (已達最大重試次數)");
            print("錯誤內容: ${response.body}");
            return null;
          }
          final delay = initialDelay * (1 << (retries - 1));
          print(
            "⏳ [GPT] API 速率限制 (429)，將在 ${delay.inSeconds} 秒後重試 ($retries/$maxRetries)...",
          );
          await Future.delayed(delay);
        } else {
          print("❌ [GPT] 評分失敗: ${response.statusCode}");
          print("錯誤內容: ${response.body}");
          return null; // 其他錯誤直接返回
        }
      } on TimeoutException catch (e) {
        print("❌ [GPT] 請求超時: $e");
        retries++;
        if (retries >= maxRetries) {
          print("❌ [GPT] 請求超時達到最大重試次數");
          return null;
        }
        final delay = initialDelay * (1 << (retries - 1));
        print(
          "⏳ [GPT] 請求超時，將在 ${delay.inSeconds} 秒後重試 ($retries/$maxRetries)...",
        );
        await Future.delayed(delay);
      } catch (e) {
        print("❌ [GPT] _evaluateEnglish 發生例外錯誤: $e");
        retries++; // 發生例外也計入重試
        if (retries >= maxRetries) {
          print("❌ [GPT] 例外錯誤達到最大重試次數");
          return null;
        }
        final delay = initialDelay * (1 << (retries - 1));
        print(
          "⏳ [GPT] 發生例外，將在 ${delay.inSeconds} 秒後重試 ($retries/$maxRetries)...",
        );
        await Future.delayed(delay);
        // return null; // 如果不想在例外時重試
      }
    }
    print("❌ [GPT] 評分在重試後仍然失敗");
    return null;
  }

  // 取得錄音檔案路徑（若需要）
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

/// 以下為遊戲相關的 UI 與邏輯

// 資料模型：怪物資訊
class MonsterInfo {
  final String name;
  final String imagePath;
  final int level;
  MonsterInfo({required this.name, required this.imagePath, this.level = 1});
}

// 建立全域怪物資料
final Map<String, MonsterInfo> monsters = {
  'Glumburn': MonsterInfo(
    name: 'Glumburn (哀焰獸)',
    imagePath: 'assets/images/monster_1.png',
    level: 3,
  ),
  'Pyrothar': MonsterInfo(
    name: 'Pyrothar (焰眼咒師)',
    imagePath: 'assets/images/monster_2.png',
    level: 5,
  ),
  'Muffora': MonsterInfo(
    name: 'Muffora (巫莓)',
    imagePath: 'assets/images/monster_3.png',
    level: 4,
  ),
  'Shroomane': MonsterInfo(
    name: 'Shroomane (絨菇巢)',
    imagePath: 'assets/images/monster_5.png',
    level: 6,
  ),
};

// 建立單一錄音器物件（整合錄音、轉文字與評分）
AudioRecorder _audioRecorder = AudioRecorder();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();
  runApp(const SpellStrikeApp());
}

class SpellStrikeApp extends StatelessWidget {
  const SpellStrikeApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SpellStrike',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4A00E0),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        textTheme: const TextTheme(
          bodyMedium: TextStyle(fontSize: 18.0, color: Colors.white),
          headlineLarge: TextStyle(
            fontSize: 36.0,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          headlineMedium: TextStyle(
            fontSize: 28.0,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
          headlineSmall: TextStyle(
            fontSize: 22.0,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
          titleLarge: TextStyle(
            fontSize: 20.0,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          titleMedium: TextStyle(
            fontSize: 18.0,
            fontWeight: FontWeight.bold,
            color: Color(0xFF90CAF9),
            letterSpacing: 1.2,
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontSize: 20.0,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00D2FF),
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 18),
            textStyle: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30.0),
            ),
            elevation: 4,
          ),
        ),
        progressIndicatorTheme: ProgressIndicatorThemeData(
          color: Colors.redAccent.shade400,
          linearTrackColor: Colors.grey.shade800,
          linearMinHeight: 18,
        ),
        splashColor: const Color(0xFF4A00E0).withOpacity(0.3),
        scaffoldBackgroundColor: const Color(0xFF1A1A2E),
      ),
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/home': (context) => const HomeScreen(),
        '/topic_selection': (context) => const TopicSelectionScreen(),
        '/gameplay': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map?;
          final monsterInfo = args?['monsterInfo'] as MonsterInfo?;
          final topic = args?['topic'] as String?;
          final defaultMonster = monsters.values.first;
          return GameplayScreen(
            monsterInfo: monsterInfo ?? defaultMonster,
            topic: topic ?? '隨機挑戰',
          );
        },
        '/results': (context) => const ResultsScreen(),
      },
    );
  }
}

// 1. 起始畫面 (Splash Screen)
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _audioRecorder.initRecorder(); // 初始化錄音器
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/logo.png',
              height: 250,
              errorBuilder: (context, error, stackTrace) {
                print('Error loading logo: $error');
                return Text(
                  'SpellStrike',
                  style: Theme.of(context).textTheme.headlineLarge,
                );
              },
            ),
            const SizedBox(height: 30),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.lightBlueAccent),
            ),
          ],
        ),
      ),
    );
  }
}

// 2. 主頁 (Home Screen)
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/home_background.png', fit: BoxFit.cover),
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.only(top: 20.0),
                child: Image.asset('assets/images/logo.png', height: 240),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 40.0, left: 20, right: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pushNamed('/topic_selection');
                    },
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('開始遊戲'),
                  ),
                  const SizedBox(height: 15),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.4),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: () {
                        // 設定頁面可依需求擴充
                        print('設定按鈕被點擊');
                      },
                      icon: const Icon(Icons.settings),
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// 3. 主題選擇畫面 (Topic Selection Screen)
class TopicSelectionScreen extends StatelessWidget {
  const TopicSelectionScreen({super.key});
  MonsterInfo _getMonsterForTopic(String topic) {
    final monsterKeys = monsters.keys.toList();
    final random = Random();
    switch (topic) {
      case '日常生活':
        return monsters['Muffora'] ?? monsters.values.first;
      case '旅遊英語':
        return monsters['Glumburn'] ?? monsters.values.first;
      case '商務會話':
        return monsters['Shroomane'] ?? monsters.values.first;
      case '奇幻冒險':
        return monsters['Pyrothar'] ?? monsters.values.first;
      case '隨機挑戰':
      default:
        return monsters[monsterKeys[random.nextInt(monsterKeys.length)]]!;
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<String> topics = ['日常生活', '旅遊英語', '商務會話', '奇幻冒險', '隨機挑戰'];
    return Scaffold(
      appBar: AppBar(title: const Text('選擇挑戰主題')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 30.0),
              child: Text(
                '選擇你想練習的主題',
                style: TextStyle(fontSize: 24, color: Colors.white70),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: topics.length,
                itemBuilder: (context, index) {
                  final topic = topics[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 10.0,
                      horizontal: 50.0,
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        final selectedMonster = _getMonsterForTopic(topic);
                        Navigator.of(context).pushNamed(
                          '/gameplay',
                          arguments: {
                            'monsterInfo': selectedMonster,
                            'topic': topic,
                          },
                        );
                      },
                      child: Text(topic),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// 4. 打怪畫面 (Gameplay Screen)
class GameplayScreen extends StatefulWidget {
  final MonsterInfo monsterInfo;
  final String topic;
  const GameplayScreen({
    super.key,
    required this.monsterInfo,
    required this.topic,
  });
  @override
  State<GameplayScreen> createState() => _GameplayScreenState();
}

class _GameplayScreenState extends State<GameplayScreen> {
  late MonsterInfo currentMonster;
  late String currentTopic;
  String currentSentence = "Loading sentence...";
  double monsterHealth = 1.0;
  bool isRecording = false;
  int score = 0;
  int evaluationScore = 0;
  String evaluationFeedback = "";
  List<String> _topicSentences = [];
  bool _isLoadingSentences = true;

  @override
  void initState() {
    super.initState();
    currentMonster = widget.monsterInfo;
    currentTopic = widget.topic;
    _loadSentencesForTopic();
  }

  // 載入指定主題的所有句子 (修改為讀取單一 CSV 並按欄位選取)
  Future<void> _loadSentencesForTopic() async {
    if (!mounted) return;
    setState(() {
      _isLoadingSentences = true;
      currentSentence = "Loading sentences...";
    });
    try {
      // Load the single CSV file
      final String filePath =
          'assets/topic/topic.csv'; // <--- Load the main CSV
      final String csvData = await rootBundle.loadString(filePath);

      // Use the CSV package to parse the data
      // Use CsvToListConverter with eol: '\n' if lines might end differently
      final List<List<dynamic>> csvTable = const CsvToListConverter().convert(
        csvData,
      );

      if (csvTable.isEmpty) {
        throw Exception("CSV file is empty.");
      }

      // Find the header row (first row) - convert to String for comparison
      final List<String> headers =
          csvTable[0].map((h) => h.toString().trim()).toList();
      // Find the column index for the current topic
      final int topicColumnIndex = headers.indexOf(currentTopic);

      if (topicColumnIndex == -1) {
        // Topic not found in CSV header
        print("⚠️ 主題 '$currentTopic' 在 topic.csv 的標頭中找不到。");
        _topicSentences = ["Error: Topic '$currentTopic' not found in CSV."];
      } else {
        // Extract sentences from the correct column, skipping the header row
        _topicSentences =
            csvTable
                .skip(1) // Skip header row
                .map((row) {
                  // Check if the row has enough columns
                  if (row.length > topicColumnIndex) {
                    // Get data from the specific column index and convert to String
                    return row[topicColumnIndex]?.toString().trim() ?? '';
                  }
                  return ''; // Return empty if row is too short
                })
                .where((s) => s.isNotEmpty) // Filter out empty strings
                .toList();
      }

      if (_topicSentences.isEmpty) {
        print("⚠️ 主題 '$currentTopic' 在 topic.csv 中沒有找到對應的題目。");
        _topicSentences = ["Error: No sentences found for '$currentTopic'."];
      }
      _loadNextSentence();
    } catch (e) {
      print("❌ 讀取或解析 topic.csv 失敗: $e");
      // Check specifically for FormatException which might indicate encoding issues
      if (e is FormatException) {
        print("   可能原因：topic.csv 檔案未儲存為 UTF-8 編碼。");
      }
      _topicSentences = ["Error loading sentences."];
      _loadNextSentence();
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingSentences = false;
        });
      }
    }
  }

  // 從已載入的句子列表中隨機選取一個
  void _loadNextSentence() {
    if (_topicSentences.isEmpty || !mounted) return;
    setState(() {
      currentSentence =
          _topicSentences[Random().nextInt(_topicSentences.length)];
    });
  }

  void _startRecording() {
    if (!mounted) return;
    setState(() {
      isRecording = true;
      // 清空上一次的分數與回饋
      score = 0;
      evaluationScore = 0;
      evaluationFeedback = "";
    });
    print("開始錄音...");
    _audioRecorder.startRecording();
    // 模擬 4 秒錄音時間，錄音結束後進行評分
    Future.delayed(const Duration(seconds: 4), _stopRecordingAndEvaluate);
  }

  void _stopRecordingAndEvaluate() async {
    final evaluation = await _audioRecorder.stopRecordingAndEvaluate();
    if (evaluation != null) {
      // 假設 GPT 回傳的 score 為 0~10，我們乘以10變成 0~100 的分數
      int evalScore = evaluation.score;
      int overallScore = evalScore * 10;
      final damageFactor = 500.0 + (currentMonster.level * 50);
      final damageDealt = overallScore / damageFactor;
      setState(() {
        isRecording = false;
        evaluationScore = evalScore;
        evaluationFeedback = evaluation.feedback;
        score = overallScore;
        monsterHealth -= damageDealt;
        if (monsterHealth < 0) monsterHealth = 0;
      });
      print(
        "評分完成 - GPT Score: $evalScore (Overall: $overallScore), Damage: $damageDealt, ${currentMonster.name} HP: ${(monsterHealth * 100).toStringAsFixed(0)}%",
      );
      if (monsterHealth <= 0) {
        print("怪物 ${currentMonster.name} 被擊敗！");
        _goToResults();
      } else {
        _loadNextSentence();
      }
    } else {
      setState(() {
        isRecording = false;
      });
      print("評分結果取得失敗");
      _loadNextSentence();
    }
  }

  void _goToResults() {
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/results');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 隱藏 AppBar 以增進沉浸感
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 背景圖片
          Image.asset(
            'assets/images/gameplay_background.png',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              print('Error loading background: $error');
              return Container(
                color: Theme.of(context).scaffoldBackgroundColor,
              );
            },
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 10.0,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 上方：怪物資訊與血條
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${currentMonster.name} (Lv.${currentMonster.level})',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(color: Colors.white.withOpacity(0.9)),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.favorite,
                            color: Colors.redAccent,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: LinearProgressIndicator(
                                value: monsterHealth,
                                minHeight: 18,
                                backgroundColor: Colors.grey.shade800,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.redAccent.shade400,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${(monsterHealth * 100).toStringAsFixed(0)}%',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  // 中間：怪物圖片
                  Flexible(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 40.0, bottom: 10.0),
                      child: Image.asset(
                        currentMonster.imagePath,
                        height: 480,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          print('Error loading monster image: $error');
                          return const Icon(
                            Icons.error_outline,
                            size: 100,
                            color: Colors.red,
                          );
                        },
                      ),
                    ),
                  ),
                  // 下方：題目、評分顯示與錄音按鈕
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 15),
                        padding: const EdgeInsets.symmetric(
                          vertical: 16.0,
                          horizontal: 12.0,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(12.0),
                          border: Border.all(
                            color: Colors.blueGrey.shade700,
                            width: 1.5,
                          ),
                        ),
                        child:
                            _isLoadingSentences
                                ? const CircularProgressIndicator(
                                  strokeWidth: 2,
                                )
                                : Text(
                                  currentSentence,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.headlineSmall?.copyWith(
                                    fontSize: 24,
                                    color: Colors.lightBlue.shade100,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                      ),
                      // 評分顯示區：當有分數時顯示 GPT 評分與回饋
                      AnimatedOpacity(
                        opacity: score > 0 ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 400),
                        child: Visibility(
                          visible: score > 0,
                          maintainAnimation: true,
                          maintainState: true,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 20),
                            padding: const EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              "Score: $evaluationScore/10\nFeedback: $evaluationFeedback",
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.amberAccent,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                      // 錄音按鈕
                      GestureDetector(
                        onTapDown: (_) {
                          if (!isRecording) _startRecording();
                        },
                        child: Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color:
                                isRecording
                                    ? Colors.redAccent.shade700
                                    : Theme.of(context).colorScheme.primary,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: (isRecording
                                        ? Colors.redAccent.shade700
                                        : Theme.of(context).colorScheme.primary)
                                    .withOpacity(0.5),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Icon(
                            isRecording
                                ? Icons.mic_off_rounded
                                : Icons.mic_rounded,
                            color:
                                isRecording
                                    ? Colors.white
                                    : Theme.of(context).colorScheme.onPrimary,
                            size: 35,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// 5. 結算畫面 (Results Screen)
class ResultsScreen extends StatelessWidget {
  const ResultsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('挑戰完成'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Icon(Icons.emoji_events, size: 100, color: Colors.amber),
            const SizedBox(height: 20),
            Text(
              '恭喜！擊敗了怪物！',
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Text(
              '總分: ${950 + Random().nextInt(151)}',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.lightGreenAccent,
              ),
            ),
            const SizedBox(height: 60),
            ElevatedButton.icon(
              icon: const Icon(Icons.replay_rounded),
              label: const Text('再挑戰一次'),
              onPressed: () {
                Navigator.of(context).pushReplacementNamed('/topic_selection');
              },
            ),
            const SizedBox(height: 20),
            TextButton.icon(
              icon: const Icon(Icons.home_rounded, size: 20),
              label: const Text('返回主頁'),
              onPressed: () {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/home',
                  (Route<dynamic> route) => false,
                );
              },
              style: TextButton.styleFrom(foregroundColor: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}
