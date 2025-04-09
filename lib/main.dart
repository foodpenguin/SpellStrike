import 'package:flutter/material.dart';
import 'dart:async'; // 用於 Splash Screen 的計時器
import 'dart:math'; // 用於隨機選擇怪物

void main() {
  runApp(const SpellStrikeApp());
}

// --- 資料模型 ---
class MonsterInfo {
  final String name;
  final String imagePath;
  final int level;

  MonsterInfo({required this.name, required this.imagePath, this.level = 1});
}

// 定義怪物資料
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

// --- App 主體 ---
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
        // fontFamily: 'YourMagicFont', // 如果你有添加特殊字體
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
          // 可以為怪物名稱定義特殊字體樣式
          titleMedium: TextStyle(
            fontSize: 18.0,
            fontWeight: FontWeight.bold,
            color: Color(0xFF90CAF9),
            letterSpacing: 1.2,
          ), // 範例：藍色、稍大字間距
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
            backgroundColor: const Color(0xFF00D2FF), // 亮藍色按鈕
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
          // 進度條 (血條) 樣式
          color: Colors.redAccent.shade400, // 血條主要顏色
          linearTrackColor: Colors.grey.shade800, // 血條背景色
          linearMinHeight: 18, // 血條高度
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
          final monsterInfo =
              ModalRoute.of(context)?.settings.arguments as MonsterInfo?;
          final defaultMonster = monsters.values.first;
          return GameplayScreen(monsterInfo: monsterInfo ?? defaultMonster);
        },
        '/results': (context) => const ResultsScreen(),
        // '/settings': (context) => const SettingsScreen(),
      },
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
                print('Error loading logo on splash: $error');
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

// --- 2. 主頁 (Home Screen) ---
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  void _showCharacterInteraction(BuildContext context) {
    /* ... */
  }
  void _openSettings(BuildContext context) {
    /* ... */
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/home_background.png',
            fit: BoxFit.cover /* errorBuilder */,
          ),
          Positioned.fill(
            child: GestureDetector(
              onTap: () => _showCharacterInteraction(context),
              child: Container(color: Colors.transparent),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.only(top: 20.0),
                child: Image.asset(
                  'assets/images/logo.png',
                  height: 240 /* errorBuilder */,
                ),
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
                      // TODO: 添加按鈕的功能
                      print('開始遊戲按鈕被點擊');
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
                        // TODO: 添加設定按鈕的功能
                        print('設定按鈕被點擊');
                        Navigator.of(context).pushNamed('/settings');
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

// --- 3. 抽題目類型 (Topic Selection Screen) - *** 修正 *** ---
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
      // *** 恢復 Center 的 child 內容 ***
      body: Center(
        // 讓內容在螢幕中央
        child: Column(
          // 垂直佈局
          mainAxisAlignment: MainAxisAlignment.center, // 主軸居中 (雖然 Expanded 會填滿)
          children: <Widget>[
            Padding(
              // 頂部文字標題
              padding: const EdgeInsets.symmetric(vertical: 30.0), // 上下間距
              child: Text(
                '選擇你想練習的主題',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.lightBlue[100],
                ), // 使用主題樣式並微調顏色
              ),
            ),
            Expanded(
              // 讓 ListView 填滿剩餘的垂直空間
              child: ListView.builder(
                // 建立按鈕列表
                itemCount: topics.length, // 列表項數量 = 主題數量
                itemBuilder: (context, index) {
                  // 如何建立每個列表項
                  final topic = topics[index]; // 獲取當前主題文字
                  return Padding(
                    // 為每個按鈕添加垂直和水平邊距
                    padding: const EdgeInsets.symmetric(
                      vertical: 10.0,
                      horizontal: 50.0,
                    ),
                    child: ElevatedButton(
                      // 每個主題是一個按鈕
                      onPressed: () {
                        // 按下按鈕時的動作
                        // 根據選中的主題獲取怪物資訊
                        final selectedMonster = _getMonsterForTopic(topic);
                        // 導航到遊戲畫面，並將怪物資訊作為參數傳遞
                        Navigator.of(
                          context,
                        ).pushNamed('/gameplay', arguments: selectedMonster);
                      },
                      child: Text(topic), // 按鈕顯示的文字
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20), // 在列表底部增加一些額外空間
          ],
        ),
      ), // *** Center 的 child 結束 ***
    );
  }
}

// --- Placeholder for MonsterInfo ---
// You should have your actual MonsterInfo class defined elsewhere
// --- End of Placeholder ---
// --- 4. 打怪 (Gameplay Screen) - *** 全面修改 *** ---
class GameplayScreen extends StatefulWidget {
  final MonsterInfo monsterInfo;
  const GameplayScreen({super.key, required this.monsterInfo});

  @override
  State<GameplayScreen> createState() => _GameplayScreenState();
}

class _GameplayScreenState extends State<GameplayScreen> {
  late MonsterInfo currentMonster;
  String currentSentence = "Loading sentence...";
  double monsterHealth = 1.0;
  bool isRecording = false;
  int score = 0;
  // Placeholder for detailed scores
  int pronunciationScore = 0;
  int fluencyScore = 0;
  int accuracyScore = 0; // 可以加一個準確度分數

  @override
  void initState() {
    super.initState();
    currentMonster = widget.monsterInfo;
    _loadNextSentence();
  }

  void _startRecording() {
    if (!mounted) return;
    setState(() {
      isRecording = true;
      score = 0; // Reset scores for new attempt
      pronunciationScore = 0;
      fluencyScore = 0;
      accuracyScore = 0;
    });
    print("開始錄音...");
    // TODO: Start actual voice recording & processing
    // Placeholder delay
    Future.delayed(const Duration(seconds: 4), _stopRecordingAndEvaluate);
  }

  void _stopRecordingAndEvaluate() {
    if (!mounted) return;

    // --- TODO: Replace with actual API call results ---
    final random = Random();
    final calculatedPronunciationScore =
        60 + random.nextInt(41); // Simulate 60-100
    final calculatedFluencyScore = 70 + random.nextInt(31); // Simulate 70-100
    final calculatedAccuracyScore = 80 + random.nextInt(21); // Simulate 80-100
    // Calculate overall score (example: weighted average)
    final overallScore =
        ((calculatedPronunciationScore * 0.4) +
                (calculatedFluencyScore * 0.3) +
                (calculatedAccuracyScore * 0.3))
            .round();
    // --- End of simulation ---

    final damageFactor = 500.0 + (currentMonster.level * 50);
    final damageDealt = overallScore / damageFactor;

    setState(() {
      isRecording = false;
      score = overallScore; // Update overall score display
      pronunciationScore = calculatedPronunciationScore;
      fluencyScore = calculatedFluencyScore;
      accuracyScore = calculatedAccuracyScore; // Store detailed scores

      monsterHealth -= damageDealt;
      if (monsterHealth < 0) monsterHealth = 0;

      print(
        "評分完成 - Overall: $score (P:$pronunciationScore, F:$fluencyScore, A:$accuracyScore), ${currentMonster.name} HP: ${(monsterHealth * 100).toStringAsFixed(0)}%",
      );

      // TODO: Trigger attack animations based on score (e.g., high score = critical hit)
      // Example: if (overallScore > 90) { _triggerCriticalHitAnimation(); } else { _triggerNormalHitAnimation(); }

      if (monsterHealth <= 0) {
        print("怪物 ${currentMonster.name} 被擊敗！");
        // TODO: Trigger monster defeat animation
        _goToResults();
      } else {
        // TODO: Trigger monster hit animation
        _loadNextSentence();
      }
    });
  }

  void _loadNextSentence() {
    // TODO: Load actual sentences based on topic/difficulty
    final sentences = [
      "Say the word: 'magic'",
      "Read aloud: 'Abracadabra!'",
      "Pronounce: 'Wizardry'",
      "Speak: 'Incantation'",
      "Try this: 'Mystical Orb'",
    ];
    if (!mounted) return;
    setState(() {
      // Reset scores for the new sentence, except the main score display which is handled in startRecording
      pronunciationScore = 0;
      fluencyScore = 0;
      accuracyScore = 0;
      // Load new sentence
      currentSentence = sentences[Random().nextInt(sentences.length)];
    });
  }

  void _goToResults() {
    // TODO: Pass final results (total score, stats) to results screen
    if (mounted) {
      // Example navigation, replace '/results' with your actual route name
      // Make sure you have a route defined for '/results' in your MaterialApp
      Navigator.of(context).pushReplacementNamed('/results');
      // If you don't have named routes setup, use:
      // Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => ResultsScreen())); // Replace ResultsScreen with your actual results screen widget
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar is usually hidden in gameplay for immersion
      body: Stack(
        // Use Stack for layering background and UI
        fit: StackFit.expand,
        children: [
          // --- 1. Background Image ---
          Image.asset(
            'assets/images/gameplay_background.png', // New background
            fit: BoxFit.cover, // Cover the entire screen
            errorBuilder: (context, error, stackTrace) {
              print('Error loading gameplay background: $error');
              return Container(
                color: Theme.of(context).scaffoldBackgroundColor,
              );
            },
          ),

          // --- 2. Main Gameplay UI Column ---
          SafeArea(
            // Ensure UI elements don't overlap with system areas
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 10.0,
              ),
              child: Column(
                // Distribute space: Monster area, Sentence/Score area, Button area
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // --- Top Section: Monster Info ---
                  Column(
                    mainAxisSize: MainAxisSize.min, // Take minimum space
                    children: [
                      Text(
                        // Monster Name & Level
                        '${currentMonster.name} (Lv.${currentMonster.level})',
                        style: Theme.of(
                          context,
                        ).textTheme.titleMedium?.copyWith(
                          color: Colors.white.withOpacity(0.9),
                        ), // Make text visible on dark background
                      ),
                      const SizedBox(height: 8),
                      Row(
                        // HP Bar and Text side-by-side
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.favorite,
                            color: Colors.redAccent,
                            size: 20,
                          ), // Heart icon
                          const SizedBox(width: 8),
                          Expanded(
                            // Let progress bar take available space
                            child: ClipRRect(
                              // Apply rounded corners
                              borderRadius: BorderRadius.circular(10),
                              child: LinearProgressIndicator(
                                value: monsterHealth,
                                minHeight: 18, // Increased height
                                backgroundColor:
                                    Colors.grey.shade800, // Darker background
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.redAccent.shade400,
                                ), // Brighter red
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            // HP Percentage Text
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

                  // --- Middle Section: Monster Image ---
                  // *** MODIFIED: Use Flexible and adjust height to prevent overflow ***
                  Flexible(
                    // <--- Added Flexible widget
                    child: Padding(
                      // Keep the increased top padding to move image down
                      padding: const EdgeInsets.only(
                        top: 40.0,
                        bottom: 10.0,
                      ), // More space above
                      child: Image.asset(
                        currentMonster.imagePath,
                        // *** MODIFIED: Reduced height (e.g., 480 or adjust as needed) ***
                        height:
                            480, // Adjusted monster size (was 640, original was 320)
                        fit: BoxFit.contain,
                        // TODO: Add monster idle/hit/death animations here (e.g., using AnimatedSwitcher or Rive)
                        errorBuilder: (context, error, stackTrace) {
                          print(
                            'Error loading monster image: ${currentMonster.imagePath} - $error',
                          );
                          return const Icon(
                            Icons.error_outline,
                            size: 100,
                            color: Colors.red,
                          );
                        },
                      ),
                    ),
                  ),

                  // --- Bottom Section: Interaction Area ---
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Sentence Display
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(
                          bottom: 15,
                        ), // Space below sentence
                        padding: const EdgeInsets.symmetric(
                          vertical: 16.0,
                          horizontal: 12.0,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(
                            0.5,
                          ), // Slightly darker semi-transparent bg
                          borderRadius: BorderRadius.circular(12.0),
                          border: Border.all(
                            color: Colors.blueGrey.shade700,
                            width: 1.5,
                          ), // Subtle border
                        ),
                        child: Text(
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

                      // Score Display Area (Shows after speaking)
                      AnimatedOpacity(
                        opacity: score > 0 ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 400),
                        child: Visibility(
                          // Use Visibility to remove space when hidden
                          visible: score > 0,
                          maintainAnimation: true, // Keep animations smooth
                          maintainState: true,
                          child: Container(
                            margin: const EdgeInsets.only(
                              bottom: 20,
                            ), // Space below scores
                            padding: const EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              // Display detailed scores
                              "Pronunciation: $pronunciationScore / Fluency: $fluencyScore / Accuracy: $accuracyScore",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.amberAccent.shade100,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),

                      // Speaking Button
                      GestureDetector(
                        // Use GestureDetector for tap/press states
                        onTapDown: (_) {
                          if (!isRecording) _startRecording();
                        }, // Tap to start
                        // onTapUp: (_) { _stopRecordingAndEvaluate(); }, // Optional: Tap again to stop early
                        // onLongPressStart: (_) { if (!isRecording) _startRecording(); }, // Optional: Long press to start
                        // onLongPressEnd: (_) { _stopRecordingAndEvaluate(); }, // Optional: Release long press to stop
                        child: Container(
                          padding: const EdgeInsets.all(
                            18,
                          ), // Larger padding makes the circle bigger
                          decoration: BoxDecoration(
                            color:
                                isRecording
                                    ? Colors.redAccent.shade700
                                    : Theme.of(context)
                                            .elevatedButtonTheme
                                            .style
                                            ?.backgroundColor
                                            ?.resolve(
                                              {
                                                MaterialState.pressed,
                                                MaterialState.focused,
                                                MaterialState.hovered,
                                              },
                                            ) ?? // More robust color resolution
                                        Theme.of(context)
                                            .colorScheme
                                            .primary, // Use theme primary color
                            shape: BoxShape.circle, // Make it circular
                            boxShadow: [
                              // Add a subtle glow/shadow
                              BoxShadow(
                                color: (isRecording
                                        ? Colors.redAccent.shade700
                                        : Theme.of(context)
                                                .elevatedButtonTheme
                                                .style
                                                ?.backgroundColor
                                                ?.resolve(
                                                  {
                                                    MaterialState.pressed,
                                                    MaterialState.focused,
                                                    MaterialState.hovered,
                                                  },
                                                ) // More robust color resolution
                                                ??
                                            Theme.of(context)
                                                .colorScheme
                                                .primary) // Use theme primary color
                                    .withOpacity(0.5),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Icon(
                            // Mic icon inside the circle
                            isRecording
                                ? Icons.mic_off_rounded
                                : Icons.mic_rounded,
                            color:
                                isRecording
                                    ? Colors.white
                                    : Theme.of(context)
                                        .colorScheme
                                        .onPrimary, // Use theme color for contrast
                            size: 35, // Icon size
                          ),
                          // TODO: Add voice wave animation around/inside the button when recording
                        ),
                      ),
                      const SizedBox(height: 10), // Space below button
                      // --- Placeholder for Timer/Animations ---
                      // Example: A simple countdown bar placeholder
                      // Container(height: 10, width: 150, color: Colors.grey.withOpacity(0.5), margin: const EdgeInsets.only(top: 15)),
                      // Text("Timer placeholder", style: TextStyle(color: Colors.grey)),
                      // TODO: Implement countdown timer bar or attack animation display area here
                    ],
                  ),
                ],
              ),
            ),
          ),

          // --- Layer 3 (Optional): Attack Animations / Damage Numbers ---
          // TODO: Use Positioned or Align widgets here to overlay animations
          // Example: Positioned(top: 150, left: 100, child: DamageNumberWidget(damage: 123))
        ],
      ),
    );
  }
}

// --- 5. 結算 (Results Screen) ---
class ResultsScreen extends StatelessWidget {
  const ResultsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    // TODO: Receive and display actual results data
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
            // TODO: Display more detailed results (average scores, stars etc.)
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
