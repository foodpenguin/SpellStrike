import 'package:flutter/material.dart';
import 'dart:async'; // 用於 Splash Screen 的計時器

void main() {
  runApp(const SpellStrikeApp());
}

class SpellStrikeApp extends StatelessWidget {
  const SpellStrikeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SpellStrike', // 應用程式標題
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple, // 你可以換成遊戲的主題色
          brightness: Brightness.dark, // 可以嘗試暗色主題
        ),
        useMaterial3: true, // 建議使用 Material 3
        // 你可以在這裡定義整個 App 的字體、按鈕樣式等
        textTheme: const TextTheme(
          bodyMedium: TextStyle(fontSize: 18.0),
          headlineLarge: TextStyle(fontSize: 48.0, fontWeight: FontWeight.bold),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
            textStyle: const TextStyle(fontSize: 20),
          ),
        ),
      ),
      // 使用命名路由來管理頁面跳轉
      initialRoute: '/', // 指定起始路由為 SplashScreen
      routes: {
        '/': (context) => const SplashScreen(),
        '/home': (context) => const HomeScreen(),
        '/topic_selection': (context) => const TopicSelectionScreen(),
        '/gameplay': (context) => const GameplayScreen(),
        '/results': (context) => const ResultsScreen(),
      },
      // 如果需要，可以定義一個未知的路由處理頁面
      // onUnknownRoute: (settings) => MaterialPageRoute(builder: (context) => UnknownScreen()),
    );
  }
}

// --- 1. 起始畫面 (Splash Screen) ---
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // 延遲一段時間（例如 3 秒）後跳轉到主頁
    Timer(const Duration(seconds: 3), () {
      // 使用 pushReplacementNamed 避免用戶可以返回到 Splash Screen
      Navigator.of(context).pushReplacementNamed('/home');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 在這裡放你的 Logo 或遊戲名稱
            // 例如：使用 FlutterLogo 或 Image.asset('assets/logo.png')
            const FlutterLogo(size: 150), // 暫時用 Flutter Logo 替代
            const SizedBox(height: 20),
            Text(
              'SpellStrike',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 20),
            const CircularProgressIndicator(), // 顯示載入動畫
          ],
        ),
      ),
    );
  }
}

// --- 2. 主頁 (Home Screen) ---
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SpellStrike - 主頁'),
        automaticallyImplyLeading: false, // 不顯示返回按鈕
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // 可能會放遊戲 Logo 或主要視覺
            Text(
              '歡迎來到 SpellStrike!',
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 50),
            ElevatedButton(
              onPressed: () {
                // 跳轉到抽題目類型頁面
                Navigator.of(context).pushNamed('/topic_selection');
              },
              child: const Text('開始遊戲'),
            ),
            const SizedBox(height: 20),
            // 可以添加其他按鈕，例如 設定、排行榜 等
            // OutlinedButton(
            //   onPressed: () { /* TODO: Navigate to Settings */ },
            //   child: const Text('設定'),
            // ),
          ],
        ),
      ),
    );
  }
}

// --- 3. 抽題目類型 (Topic Selection Screen) ---
class TopicSelectionScreen extends StatelessWidget {
  const TopicSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 假設的題目類型列表
    final List<String> topics = ['日常生活', '旅遊英語', '商務會話', '隨機挑戰'];

    return Scaffold(
      appBar: AppBar(title: const Text('選擇題目類型')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text('選擇你想練習的主題', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 30),
            // 將題目類型顯示為按鈕列表
            Expanded(
              // 使用 Expanded 讓 ListView 填滿剩餘空間
              child: ListView.builder(
                itemCount: topics.length,
                itemBuilder: (context, index) {
                  final topic = topics[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8.0,
                      horizontal: 40.0,
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        // 跳轉到打怪頁面，可以將選擇的 topic 作為參數傳遞
                        // Navigator.of(context).pushNamed('/gameplay', arguments: topic);
                        Navigator.of(context).pushNamed('/gameplay'); // 暫不傳遞參數
                      },
                      child: Text(topic),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- 4. 打怪 (Gameplay Screen) ---
class GameplayScreen extends StatefulWidget {
  const GameplayScreen({super.key});
  // 如果需要接收參數，可以這樣定義：
  // final String selectedTopic;
  // const GameplayScreen({super.key, required this.selectedTopic});

  @override
  State<GameplayScreen> createState() => _GameplayScreenState();
}

class _GameplayScreenState extends State<GameplayScreen> {
  // --- 這裡需要狀態來管理 ---
  String currentSentence = "Please read this example sentence."; // 當前的句子
  double monsterHealth = 1.0; // 怪物血量 (0.0 ~ 1.0)
  bool isRecording = false; // 是否正在錄音
  int score = 0; // 本句得分
  // TODO: 添加計時器邏輯

  void _startRecording() {
    // TODO: 實現開始錄音的邏輯
    setState(() {
      isRecording = true;
      // 清除上一句的分數
      score = 0;
    });
    print("開始錄音...");
    // 模擬錄音和評分過程
    // 在實際應用中，這裡會觸發語音辨識和評分 API
    Future.delayed(const Duration(seconds: 4), _stopRecordingAndEvaluate);
  }

  void _stopRecordingAndEvaluate() {
    // TODO: 實現停止錄音、呼叫 API、獲取分數、計算傷害的邏輯
    setState(() {
      isRecording = false;
      // 模擬獲得分數和計算傷害
      score = (80 + (DateTime.now().second % 21)).toInt(); // 隨機模擬 80-100 分
      double damage = score / 500.0; // 簡單的傷害轉換邏輯
      monsterHealth -= damage;
      if (monsterHealth < 0) monsterHealth = 0;
      print("錄音結束，得分: $score, 怪物剩餘血量: $monsterHealth");

      // 檢查怪物是否被打敗
      if (monsterHealth <= 0) {
        _goToResults();
      } else {
        // 載入下一句 (或重複本句)
        _loadNextSentence();
      }
    });
  }

  void _loadNextSentence() {
    // TODO: 實現從題庫加載下一句的邏輯
    setState(() {
      currentSentence = "This is another example sentence to read aloud.";
      // 也可以根據需要重置怪物血量或設定新怪物
    });
  }

  void _goToResults() {
    // TODO: 可能需要傳遞最終分數或其他統計數據到結果頁面
    // Navigator.of(context).pushReplacementNamed('/results', arguments: finalScore);
    Navigator.of(context).pushReplacementNamed('/results'); // 跳轉到結算頁面
  }

  @override
  Widget build(BuildContext context) {
    // // 如果需要從路由接收參數：
    // final selectedTopic = ModalRoute.of(context)!.settings.arguments as String?;

    return Scaffold(
      appBar: AppBar(
        title: const Text('戰鬥中！'),
        // title: Text('戰鬥中！ - ${selectedTopic ?? '未知主題'}'), // 顯示主題
        automaticallyImplyLeading: false, // 通常戰鬥中不允許返回
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween, // 將元素分散在空間中
          children: <Widget>[
            // --- 頂部：怪物狀態 ---
            Column(
              children: [
                Text(
                  '怪物名稱 (Lv. 5)',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 10),
                // TODO: 替換成怪物圖片或動畫
                const Icon(
                  Icons.adb,
                  size: 100,
                  color: Colors.green,
                ), // 暫用 Android Bot
                const SizedBox(height: 10),
                LinearProgressIndicator(
                  // 怪物血條
                  value: monsterHealth,
                  minHeight: 20,
                  backgroundColor: Colors.grey[700],
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.red),
                ),
                Text('${(monsterHealth * 100).toStringAsFixed(0)}%'), // 顯示血量百分比
              ],
            ),

            // --- 中間：句子顯示 ---
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Text(
                currentSentence,
                style: Theme.of(
                  context,
                ).textTheme.headlineSmall?.copyWith(fontSize: 28), // 放大字體
                textAlign: TextAlign.center,
              ),
            ),

            // --- 顯示分數 (如果有的話) ---
            if (score > 0)
              Text(
                '得分: $score',
                style: Theme.of(
                  context,
                ).textTheme.headlineMedium?.copyWith(color: Colors.amber),
              ),

            // --- 底部：錄音控制 ---
            Column(
              children: [
                // TODO: 加入計時器顯示
                // Text('剩餘時間: 10s', style: TextStyle(fontSize: 18)),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: isRecording ? null : _startRecording, // 錄音中禁用按鈕
                  icon: Icon(isRecording ? Icons.mic_off : Icons.mic),
                  label: Text(isRecording ? '正在錄音...' : '按住說話 (或點擊)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isRecording ? Colors.redAccent : Colors.blueAccent,
                    minimumSize: const Size(200, 60), // 較大的按鈕
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// --- 5. 結算 (Results Screen) ---
class ResultsScreen extends StatelessWidget {
  const ResultsScreen({super.key});
  // // 如果需要接收參數：
  // final int finalScore;
  // const ResultsScreen({super.key, required this.finalScore});

  @override
  Widget build(BuildContext context) {
    // // 如果需要從路由接收參數：
    // final finalScore = ModalRoute.of(context)!.settings.arguments as int?;

    return Scaffold(
      appBar: AppBar(
        title: const Text('戰鬥結算'),
        automaticallyImplyLeading: false, // 不顯示返回按鈕
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              '恭喜！戰鬥勝利！', // 或 "挑戰結束"
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 30),
            // TODO: 顯示更詳細的結算資訊，例如總分、平均發音分、獲得的星星等
            const Icon(Icons.star, size: 80, color: Colors.amber), // 範例：顯示星星
            Text(
              '總分: ${950}', // 範例分數
              // '總分: ${finalScore ?? 'N/A'}', // 使用傳入的分數
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            // 可以顯示錯誤回饋
            // Text('發音建議: 注意 "th" 的發音'),
            const SizedBox(height: 50),
            ElevatedButton(
              onPressed: () {
                // 返回主題選擇頁面，重新開始一輪
                Navigator.of(context).pushReplacementNamed('/topic_selection');
              },
              child: const Text('再玩一次'),
            ),
            const SizedBox(height: 20),
            OutlinedButton(
              onPressed: () {
                // 返回主頁，使用 pushNamedAndRemoveUntil 清除中間的頁面堆疊
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/home',
                  (Route<dynamic> route) => false,
                );
              },
              child: const Text('返回主頁'),
            ),
          ],
        ),
      ),
    );
  }
}
