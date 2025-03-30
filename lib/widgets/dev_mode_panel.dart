import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import '../models/card.dart';

class DevModePanel extends StatelessWidget {
  const DevModePanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (context, gameState, child) {
        if (!gameState.devMode) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 頂部標題欄
              Row(
                children: [
                  const Icon(Icons.developer_mode),
                  const SizedBox(width: 8),
                  const Text(
                    '開發模式面板',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => gameState.toggleDevMode(),
                    tooltip: '關閉開發模式',
                  ),
                ],
              ),
              const Divider(),
              
              // 牌堆信息
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Icon(Icons.style, color: Colors.blue),
                    const SizedBox(width: 8),
                    Text(
                      '牌堆剩餘：${gameState.deck.length} 張',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              
              // 玩家手牌區域
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: ListView.builder(
                    itemCount: gameState.playerCount,
                    itemBuilder: (context, playerIndex) {
                      var playerHand = gameState.playerHands[playerIndex];
                      return Card(
                        margin: const EdgeInsets.all(4),
                        child: ExpansionTile(
                          initiallyExpanded: true,
                          title: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: playerIndex == gameState.currentPlayer
                                    ? Colors.blue
                                    : Colors.grey,
                                child: Text('P${playerIndex + 1}'),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '玩家 ${playerIndex + 1} 的手牌',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: playerIndex == gameState.currentPlayer
                                      ? Colors.blue
                                      : null,
                                ),
                              ),
                            ],
                          ),
                          subtitle: Text(
                            playerIndex == gameState.currentPlayer ? '當前回合' : '等待中',
                            style: TextStyle(
                              color: playerIndex == gameState.currentPlayer
                                  ? Colors.blue
                                  : Colors.grey,
                            ),
                          ),
                          children: [
                            Container(
                              height: 130,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              child: ListView(
                                scrollDirection: Axis.horizontal,
                                children: playerHand
                                    .map((card) => _buildDevModeCard(card))
                                    .toList(),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
              
              // 棄牌堆區域
              Container(
                margin: const EdgeInsets.only(top: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.delete_outline, color: Colors.red),
                        const SizedBox(width: 8),
                        Text(
                          '棄牌堆 (${gameState.discardedCards.length} 張)',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 130,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.all(4),
                        children: gameState.discardedCards
                            .map((card) => _buildDevModeCard(card))
                            .toList(),
                      ),
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

  Widget _buildDevModeCard(HanabiCard card) {
    return Container(
      width: 80,
      height: 120,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        image: const DecorationImage(
          image: AssetImage('assets/images/背卡封面.webp'),
          fit: BoxFit.cover,
        ),
        border: Border.all(color: Colors.black),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            spreadRadius: 0,
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          color: card.color.displayColor.withOpacity(0.85),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Stack(
          children: [
            // 卡牌內容
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    card.number.toString(),
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: card.color.textColor,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.3),
                          offset: const Offset(1, 1),
                          blurRadius: 2,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 0.5,
                      ),
                    ),
                    child: Text(
                      card.color.name,
                      style: TextStyle(
                        fontSize: 12,
                        color: card.color.textColor,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.3),
                            offset: const Offset(1, 1),
                            blurRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // 狀態圖標
            if (card.isDiscarded || card.isPlayed)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        spreadRadius: 0,
                        blurRadius: 2,
                      ),
                    ],
                  ),
                  child: Icon(
                    card.isDiscarded ? Icons.delete : Icons.check_circle,
                    color: card.isDiscarded ? Colors.red : Colors.green,
                    size: 16,
                  ),
                ),
              ),
            // 提示標記
            if ((card.hints['color'] == true) || (card.hints['number'] == true))
              Positioned(
                bottom: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        spreadRadius: 0,
                        blurRadius: 2,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.info,
                    color: Colors.blue,
                    size: 16,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}