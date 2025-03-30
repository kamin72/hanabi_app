import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import '../models/card.dart';
import '../widgets/dev_mode_panel.dart';

/// 當鼠標懸停時應用輕微旋轉動畫的 Widget
///
/// 包裝子 Widget 並在鼠標進入/離開時應用輕微搖擺動畫
/// 動畫持續時間 250 毫秒，旋轉角度 ±10 度
class HoverRotatingCard extends StatefulWidget {
  final Widget child;

  const HoverRotatingCard({super.key, required this.child});

  @override
  State<HoverRotatingCard> createState() => _HoverRotatingCardState();
}

/// 管理旋轉動畫的狀態類
/// 
/// 負責動畫控制器的初始化和釋放
/// 處理鼠標懸停事件並觸發相應動畫
class _HoverRotatingCardState extends State<HoverRotatingCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    // 初始化動畫控制器，持續時間 250 毫秒
    _controller = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    
    // 創建從 0 到 0.1 弧度（約5.7度）的動畫
    _animation = Tween<double>(begin: 0, end: 0.1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,  // 使用緩入緩出曲線使動畫更平滑
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _controller.forward(),  // 鼠標懸停時正向播放動畫
      onExit: (_) => _controller.reverse(),   // 鼠標離開時反向播放動畫
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          // 根據動畫值應用旋轉變換
          // 此公式會讓角度在動畫過程中先正後負，產生搖擺效果
          return Transform.rotate(
            angle: _animation.value * (1 - _animation.value * 2),
            child: child,
          );
        },
        child: widget.child,
      ),
    );
  }
}

/// Web版花火遊戲主畫面
/// 
/// 負責顯示遊戲主界面，包含：
/// - 玩家手牌區域
/// - 已出牌區域
/// - 遊戲資訊面板
/// - 操作按鈕區域
/// - 遊戲記錄顯示
class WebGameScreen extends StatelessWidget {
  const WebGameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (context, gameState, child) {
        if (gameState.isGameOver) {
          Future.delayed(Duration.zero, () => _showGameOverDialog(context, gameState));
        }
        
        return Scaffold(
          appBar: AppBar(
            title: const Text('花火 - Web版'),
            actions: [
              IconButton(
                icon: const Icon(Icons.developer_mode),
                onPressed: () => gameState.toggleDevMode(),
                tooltip: '開發模式',
              ),
              IconButton(
                icon: const Icon(Icons.help),
                onPressed: () => _showRules(context),
              ),
            ],
          ),
          body: Column(
            children: [
              if (gameState.devMode)
                SizedBox(
                  height: 400,
                  child: const DevModePanel(),
                ),
              Expanded(
                child: Row(
                  children: [
                    Expanded(flex: 1, child: _buildLeftPanel(gameState)),
                    Expanded(flex: 3, child: _buildGameArea(gameState, context)),
                    Expanded(flex: 1, child: _buildRightPanel(context, gameState)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLeftPanel(GameState gameState) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(right: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Column(
        children: [
          _buildGameInfo(gameState),
          const Divider(),
          _buildPlayerList(gameState),
        ],
      ),
    );
  }

  Widget _buildGameInfo(GameState gameState) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('分數: ${gameState.score}', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Text('提示次數: ${gameState.hints}', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Text('失誤次數: ${3 - gameState.fuses}', style: const TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerList(GameState gameState) {
    return Expanded(
      child: ListView.builder(
        itemCount: gameState.playerCount,
        itemBuilder: (context, index) {
          bool isCurrentPlayer = index == gameState.currentPlayer;
          return Card(
            color: isCurrentPlayer ? Colors.blue.shade100 : null,
            child: ListTile(
              leading: CircleAvatar(child: Text('P${index + 1}')),
              title: Text('玩家 ${index + 1}'),
              subtitle: Text(isCurrentPlayer ? '當前回合' : '等待中'),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGameArea(GameState gameState, BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildPlayedCards(gameState),
          const Spacer(),
          _buildCurrentPlayerHand(gameState, context),
        ],
      ),
    );
  }

  Widget _buildPlayedCards(GameState gameState) {
    return Container(
      height: 200,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: CardColor.values.map((color) {
          if (color == CardColor.rainbow) return const SizedBox.shrink();
          var cards = gameState.playedCards.where((card) => card.color == color).toList();
          return _buildPlayedCardStack(color, cards);
        }).toList(),
      ),
    );
  }

  Widget _buildPlayedCardStack(CardColor color, List<HanabiCard> cards) {
    int topValue = cards.isNotEmpty ? cards.map((c) => c.number).reduce((a, b) => a > b ? a : b) : 0;
    return Column(
      children: [
        Container(
          width: 120,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.displayColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(8),
              topRight: Radius.circular(8),
            ),
          ),
          child: Text(
            '${cards.isEmpty ? 0 : topValue}/5',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color.textColor,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        Container(
          width: 120,
          height: 150,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.05),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(8),
              bottomRight: Radius.circular(8),
            ),
            border: Border.all(color: color.displayColor),
          ),
          child: cards.isEmpty ? _buildFireworkPlaceholder() : _buildFireworkDisplay(topValue, color),
        ),
      ],
    );
  }

  Widget _buildFireworkPlaceholder() {
    return Center(
      child: Icon(
        Icons.auto_awesome,
        size: 40,
        color: Colors.grey.withOpacity(0.5),
      ),
    );
  }

  Widget _buildFireworkDisplay(int value, CardColor color) {
    return Stack(
      children: [
        Center(
          child: Text(
            value.toString(),
            style: TextStyle(
              fontSize: 64,
              fontWeight: FontWeight.bold,
              color: color.displayColor,
            ),
          ),
        ),
        ...List.generate(value * 2, (index) {
          final angle = index * 45.0;
          final length = 20.0 + (index % 3) * 10.0;
          return Center(
            child: Transform.rotate(
              angle: angle * 3.14159 / 180.0,
              child: Container(
                width: 2,
                height: length,
                decoration: BoxDecoration(
                  color: color.displayColor,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildCurrentPlayerHand(GameState gameState, BuildContext context) {
    return Container(
      height: 200,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          gameState.playerHands[gameState.currentPlayer].length,
          (index) => _buildCard(
            gameState.playerHands[gameState.currentPlayer][index],
            index,
            gameState,
            context,
          ),
        ),
      ),
    );
  }

  Widget _buildCard(HanabiCard card, int index, GameState gameState, BuildContext context) {
    Color cardColor = card.hints['color'] == true ? card.color.displayColor : Colors.white;
    Color textColor = card.hints['color'] == true ? card.color.textColor : Colors.black;
    
    return HoverRotatingCard(
      child: GestureDetector(
        onTap: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('選擇操作'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(Icons.play_arrow),
                    title: const Text('打出這張牌'),
                    onTap: () {
                      gameState.playCard(gameState.currentPlayer, index);
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.delete),
                    title: const Text('棄掉這張牌'),
                    onTap: () {
                      gameState.discardCard(gameState.currentPlayer, index);
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('取消'),
                ),
              ],
            ),
          );
        },
        child: Container(
          width: 100,
          height: 150,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: cardColor,
            border: Border.all(color: Colors.black),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.5),
                spreadRadius: 1,
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
            image: const DecorationImage(
              image: AssetImage('assets/images/背卡封面.webp'),
              fit: BoxFit.cover,
            ),
          ),
          child: Stack(
            children: [
              if (card.hints['color'] == true || card.hints['number'] == true)
                Container(
                  decoration: BoxDecoration(
                    color: cardColor.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (card.hints['number'] == true)
                        Text(
                          card.number.toString(),
                          style: TextStyle(
                            fontSize: 64,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        )
                      else
                        const Text('?', 
                          style: TextStyle(
                            fontSize: 64, 
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      if (card.hints['number'] == true)
                        ...List.generate(card.number, (i) => 
                          Positioned(
                            top: 5 + i * 20,
                            right: 5,
                            child: Icon(
                              Icons.auto_awesome,
                              size: 12,
                              color: textColor,
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),
                      const Text('點擊使用', style: TextStyle(fontSize: 14)),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRightPanel(BuildContext context, GameState gameState) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Column(
        children: [
          _buildActionButtons(context, gameState),
          const Divider(),
          _buildChatArea(context, gameState),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, GameState gameState) {
    return Column(
      children: [
        ElevatedButton.icon(
          icon: const Icon(Icons.info),
          label: const Text('給予提示'),
          onPressed: () => _showHintDialog(context, gameState),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
          ),
        ),
      ],
    );
  }

  Widget _buildChatArea(BuildContext context, GameState gameState) {
    return Expanded(
      child: Card(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text('遊戲記錄', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            const Divider(),
            Expanded(
              child: ListView.builder(
                itemCount: gameState.gameLog.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(gameState.gameLog[index]),
                    dense: true,
                  );
                },
              ),
            ),
            if (gameState.isGameOver)
              Container(
                padding: const EdgeInsets.all(8),
                color: Colors.red.shade100,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '遊戲結束：${gameState.gameEndReason}\n最終得分：${gameState.score}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    TextButton(
                      onPressed: () => _showGameOverDialog(context, gameState),
                      child: const Text('查看詳情'),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showRules(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('遊戲規則'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('1. 每位玩家看不到自己的牌'),
              Text('2. 每回合可以：'),
              Padding(
                padding: EdgeInsets.only(left: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('- 給予提示（消耗提示標記）'),
                    Text('- 打出一張牌'),
                    Text('- 棄掉一張牌（恢復一個提示標記）'),
                  ],
                ),
              ),
              Text('3. 目標是按順序完成所有顏色的煙火（1-5）'),
              Text('4. 三次失誤將導致遊戲結束'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('了解'),
          ),
        ],
      ),
    );
  }

  void _showHintDialog(BuildContext context, GameState gameState) {
    int? selectedPlayer;
    CardColor? selectedColor;
    int? selectedNumber;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('給予提示'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButton<int>(
                value: selectedPlayer,
                items: List.generate(
                  gameState.playerCount,
                  (index) => DropdownMenuItem(
                    value: index,
                    child: Text('玩家 ${index + 1}'),
                  ),
                ).where((item) => item.value != gameState.currentPlayer).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedPlayer = value;
                    selectedColor = null;
                    selectedNumber = null;
                  });
                },
                hint: const Text('選擇玩家'),
              ),
              if (selectedPlayer != null) ...[
                const SizedBox(height: 16),
                const Text('選擇提示類型:'),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Column(
                      children: [
                        const Text('顏色提示'),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: CardColor.values
                              .where((c) => c != CardColor.rainbow)
                              .map((color) => Container(
                                    margin: const EdgeInsets.all(4),
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: color.displayColor,
                                        foregroundColor: color.textColor,
                                        shape: const CircleBorder(),
                                        padding: const EdgeInsets.all(16),
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          selectedColor = color;
                                          selectedNumber = null;
                                        });
                                      },
                                      child: selectedColor == color
                                          ? const Icon(Icons.check)
                                          : const SizedBox(width: 20, height: 20),
                                    ),
                                  ))
                              .toList(),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Column(
                      children: [
                        const Text('數字提示'),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: [1, 2, 3, 4, 5]
                              .map((number) => ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: selectedNumber == number
                                          ? Colors.blue
                                          : Colors.grey,
                                      shape: const CircleBorder(),
                                      padding: const EdgeInsets.all(16),
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        selectedNumber = number;
                                        selectedColor = null;
                                      });
                                    },
                                    child: Text(number.toString()),
                                  ))
                              .toList(),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            if (selectedPlayer != null && (selectedColor != null || selectedNumber != null))
              TextButton(
                onPressed: () {
                  gameState.giveHint(
                    selectedPlayer!,
                    color: selectedColor,
                    number: selectedNumber,
                  );
                  Navigator.pop(context);
                },
                child: const Text('給予提示'),
              ),
          ],
        ),
      ),
    );
  }

  void _showGameOverDialog(BuildContext context, GameState gameState) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('遊戲結束'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('結束原因：${gameState.gameEndReason}'),
            const SizedBox(height: 16),
            Text('最終得分：${gameState.score}分', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            const Text('煙火完成情況：'),
            ...CardColor.values.where((c) => c != CardColor.rainbow).map((color) {
              var sameColorCards = gameState.playedCards.where((c) => c.color == color).toList();
              int maxNumber = sameColorCards.isEmpty ? 0 : sameColorCards.map((c) => c.number).reduce((a, b) => a > b ? a : b);
              return Padding(
                padding: const EdgeInsets.only(left: 16, top: 4),
                child: Row(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: color.displayColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('${color.name}：$maxNumber/5'),
                  ],
                ),
              );
            }),
            const SizedBox(height: 16),
            Text('剩餘失誤次數：${gameState.fuses}'),
            Text('剩餘提示次數：${gameState.hints}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              gameState.restartGame();
              Navigator.pop(context);
            },
            child: const Text('重新開始'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pushNamedAndRemoveUntil(
                '/',
                (route) => false,
              );
            },
            child: const Text('返回主選單'),
          ),
        ],
      ),
    );
  }
}
