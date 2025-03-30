import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import '../models/card.dart';

class GameScreen extends StatelessWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('花火遊戲'),
      ),
      body: Consumer<GameState>(
        builder: (context, gameState, child) {
          return Column(
            children: [
              _buildGameInfo(gameState),
              _buildPlayedCards(gameState),
              const Spacer(),
              _buildPlayerHand(gameState),
              _buildActionButtons(context, gameState),
            ],
          );
        },
      ),
    );
  }

  Widget _buildGameInfo(GameState gameState) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Text('提示次數: ${gameState.hints}'),
          Text('失誤次數: ${3 - gameState.fuses}'),
          Text('分數: ${gameState.score}'),
        ],
      ),
    );
  }

  Widget _buildPlayedCards(GameState gameState) {
    return Container(
      height: 120,
      padding: const EdgeInsets.all(8.0),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: CardColor.values.length - 1, // 不包括彩虹色
        itemBuilder: (context, index) {
          var color = CardColor.values[index];
          var cards = gameState.playedCards
              .where((card) => card.color == color)
              .toList();
          return _buildPlayedCardStack(color, cards);
        },
      ),
    );
  }

  Widget _buildPlayedCardStack(CardColor color, List<HanabiCard> cards) {
    return Container(
      width: 80,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(color.name),
          Text(cards.isEmpty ? '0' : cards.length.toString()),
        ],
      ),
    );
  }

  Widget _buildPlayerHand(GameState gameState) {
    return Container(
      height: 150,
      padding: const EdgeInsets.all(8.0),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: gameState.playerHands[gameState.currentPlayer].length,
        itemBuilder: (context, index) {
          var card = gameState.playerHands[gameState.currentPlayer][index];
          return _buildCard(card, index, gameState);
        },
      ),
    );
  }

  Widget _buildCard(HanabiCard card, int index, GameState gameState) {
    return Container(
      width: 70,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (card.hints['color']!)
            Text(card.color.name)
          else
            const Text('???'),
          if (card.hints['number']!)
            Text(card.number.toString())
          else
            const Text('?'),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, GameState gameState) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          ElevatedButton(
            onPressed: () => _showHintDialog(context, gameState),
            child: const Text('給予提示'),
          ),
          ElevatedButton(
            onPressed: () => _showPlayCardDialog(context, gameState),
            child: const Text('出牌'),
          ),
          ElevatedButton(
            onPressed: () => _showDiscardDialog(context, gameState),
            child: const Text('棄牌'),
          ),
        ],
      ),
    );
  }

  void _showHintDialog(BuildContext context, GameState gameState) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('給予提示'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('選擇玩家和提示類型'),
            // 這裡可以添加更多UI元素來選擇玩家和提示類型
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
  }

  void _showPlayCardDialog(BuildContext context, GameState gameState) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('選擇要出的牌'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('選擇一張牌出牌'),
            // 這裡可以添加卡牌選擇UI
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
  }

  void _showDiscardDialog(BuildContext context, GameState gameState) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('選擇要棄掉的牌'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('選擇一張牌棄掉'),
            // 這裡可以添加卡牌選擇UI
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
  }
}