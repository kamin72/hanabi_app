import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import '../models/card.dart';
import '../widgets/dev_mode_panel.dart';

class WebGameScreen extends StatelessWidget {
  const WebGameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (context, gameState, child) {
        if (gameState.isGameOver) {
          // 延遲顯示遊戲結束對話框，避免在狀態更新時立即彈出
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
                    // 左側面板 - 遊戲信息和玩家列表
                    Expanded(
                      flex: 1,
                      child: _buildLeftPanel(gameState),
                    ),
                    // 中央面板 - 遊戲區域
                    Expanded(
                      flex: 3,
                      child: _buildGameArea(gameState, context),
                    ),
                    // 右側面板 - 聊天和操作按鈕
                    Expanded(
                      flex: 1,
                      child: _buildRightPanel(context, gameState),
                    ),
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
              leading: CircleAvatar(
                child: Text('P${index + 1}'),
              ),
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
    int topValue = 0;
    if (cards.isNotEmpty) {
      topValue = cards.map((c) => c.number).reduce((a, b) => a > b ? a : b);
    }
    
    return Column(
      children: [
        // 顏色標識
        Container(
          width: 120,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.displayColor,
            borderRadius: BorderRadius.only(
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
        // 卡牌區域
        Container(
          width: 120,
          height: 150,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.05),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(8),
              bottomRight: Radius.circular(8),
            ),
            border: Border.all(color: color.displayColor),
          ),
          child: cards.isEmpty 
              ? _buildFireworkPlaceholder() 
              : _buildFireworkDisplay(topValue, color),
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
        // 中心數字
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
        // 煙火效果
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
    
    return GestureDetector(
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
            // 如果有提示，顯示卡牌內容
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
                    
                    // 卡牌角落的小煙火
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
          _buildChatArea(),
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

  Widget _buildChatArea() {
    return Consumer<GameState>(
      builder: (context, gameState, child) => Expanded(
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
                                    margin: EdgeInsets.all(4),
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: color.displayColor,
                                        foregroundColor: color.textColor,
                                        shape: CircleBorder(),
                                        padding: EdgeInsets.all(16),
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          selectedColor = color;
                                          selectedNumber = null;
                                        });
                                      },
                                      child: selectedColor == color
                                          ? Icon(Icons.check)
                                          : SizedBox(width: 20, height: 20),
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
                                      shape: CircleBorder(),
                                      padding: EdgeInsets.all(16),
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
            if (selectedPlayer != null &&
                (selectedColor != null || selectedNumber != null))
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

  Widget _buildCardInDialog(HanabiCard card, {bool showDiscard = false}) {
    Color cardColor = card.hints['color'] == true ? card.color.displayColor : Colors.white;
    Color textColor = card.hints['color'] == true ? card.color.textColor : Colors.black;
    
    return Card(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          image: const DecorationImage(
            image: AssetImage('assets/images/背卡封面.webp'),
            fit: BoxFit.cover,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: ListTile(
          tileColor: card.hints['color'] == true ? cardColor.withOpacity(0.9) : Colors.white.withOpacity(0.9),
          leading: CircleAvatar(
            backgroundColor: Colors.white,
            child: Icon(
              showDiscard ? Icons.delete : Icons.play_arrow,
              color: Colors.black,
            ),
          ),
          title: Text(
            card.hints['number'] == true ? '數字 ${card.number}' : '未知數字',
            style: TextStyle(
              color: card.hints['color'] == true ? card.color.textColor : Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          trailing: Icon(
            showDiscard ? Icons.delete : Icons.auto_awesome,
            color: card.hints['color'] == true ? card.color.textColor : Colors.black,
          ),
        ),
      ),
    );
  }

  void _showPlayCardDialog(BuildContext context, GameState gameState) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('選擇要出的牌'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: gameState.playerHands[gameState.currentPlayer].length,
            itemBuilder: (context, index) {
              var card = gameState.playerHands[gameState.currentPlayer][index];
              return InkWell(
                onTap: () {
                  gameState.playCard(gameState.currentPlayer, index);
                  Navigator.pop(context);
                },
                child: _buildCardInDialog(card),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
        ],
      ),
    );
  }

  void _showDiscardDialog(BuildContext context, GameState gameState) {
    if (gameState.hints >= 8) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('無法棄牌'),
          content: const Text('提示標記已達最大值(8)，無法棄牌。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('確定'),
            ),
          ],
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('選擇要棄掉的牌'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: gameState.playerHands[gameState.currentPlayer].length,
            itemBuilder: (context, index) {
              var card = gameState.playerHands[gameState.currentPlayer][index];
              return InkWell(
                onTap: () {
                  gameState.discardCard(gameState.currentPlayer, index);
                  Navigator.pop(context);
                },
                child: _buildCardInDialog(card, showDiscard: true),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
        ],
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