import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/game_state.dart';
import 'screens/web_game_screen.dart';
// 條件導入，確保在Web和非Web平台都能運行
import 'dart:io' if (dart.library.html) 'dart:html' as html;

void main() {
  runApp(const HanabiApp());
}

class HanabiApp extends StatelessWidget {
  const HanabiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '花火 - Web版',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const StartScreen(),
      },
    );
  }
}

class StartScreen extends StatelessWidget {
  const StartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 添加開發模式選項
    bool devMode = false;
    
    return Scaffold(
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          padding: const EdgeInsets.all(32),
          child: Card(
            elevation: 8,
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    '花火',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    '選擇玩家人數開始遊戲',
                    style: TextStyle(fontSize: 24),
                  ),
                  const SizedBox(height: 32),
                  
                  // 開發模式選項
                  StatefulBuilder(
                    builder: (context, setState) => Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('開發模式', style: TextStyle(fontSize: 16)),
                        Switch(
                          value: devMode,
                          onChanged: (value) {
                            setState(() {
                              devMode = value;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    alignment: WrapAlignment.center,
                    children: [
                      for (var i = 2; i <= 5; i++)
                        ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (context) => ChangeNotifierProvider(
                                  create: (context) => GameState(
                                    playerCount: i, 
                                    devMode: devMode,
                                  ),
                                  child: const WebGameScreen(),
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 16,
                            ),
                          ),
                          child: Text(
                            '$i 人遊戲',
                            style: const TextStyle(fontSize: 20),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    '遊戲說明',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '花火是一個合作型卡牌遊戲，玩家們共同努力創造出完美的煙火表演。'
                    '每個玩家都看不到自己的牌，需要通過其他玩家的提示來了解自己的手牌。',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                  
                  const SizedBox(height: 16),
                  const Text(
                    '開發模式說明：啟用後可以查看所有玩家的手牌，便於測試和開發。',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}