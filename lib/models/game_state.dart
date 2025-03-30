import 'package:flutter/foundation.dart';
import 'dart:math' as math;
import 'card.dart';

class GameState extends ChangeNotifier {
  List<HanabiCard> deck = [];
  List<List<HanabiCard>> playerHands = [];
  List<HanabiCard> playedCards = [];
  List<HanabiCard> discardedCards = [];
  int hints = 8;
  int fuses = 3;
  int currentPlayer = 0;
  int playerCount;
  bool isGameOver = false;
  int score = 0;
  String gameEndReason = '';
  List<String> gameLog = [];
  
  // 開發模式設置
  bool devMode = false;
  int viewingPlayer = -1; // -1表示當前玩家視角，否則表示正在查看的玩家索引

  GameState({required this.playerCount, this.devMode = false}) {
    initializeGame();
  }

  void initializeGame() {
    // 創建牌組
    deck = [];
    for (var color in CardColor.values) {
      if (color == CardColor.rainbow) continue; // 基礎模式不使用彩虹牌
      
      // 每種顏色的牌數分配：1(x3), 2(x2), 3(x2), 4(x2), 5(x1)
      for (var number = 1; number <= 5; number++) {
        var count = number == 5 ? 1 : (number == 1 ? 3 : 2);
        for (var i = 0; i < count; i++) {
          deck.add(HanabiCard(color: color, number: number));
        }
      }
    }

    // 洗牌
    deck.shuffle();

    // 發牌
    playerHands = List.generate(
      playerCount,
      (index) => deck.take(playerCount <= 3 ? 5 : 4).toList(),
    );
    deck.removeRange(0, playerCount * (playerCount <= 3 ? 5 : 4));

    // 在開發模式下顯示所有卡牌
    if (devMode) {
      _revealAllCards();
    }

    notifyListeners();
  }

  // 切換開發模式
  void toggleDevMode() {
    devMode = !devMode;
    
    // 在開發模式下自動顯示所有卡牌
    if (devMode) {
      _revealAllCards();
    } else {
      // 關閉開發模式時，重設已顯示狀態
      _hideAllCards();
    }
    
    notifyListeners();
  }

  // 顯示所有卡牌
  void _revealAllCards() {
    // 顯示牌堆中的卡牌
    for (var card in deck) {
      card.isRevealed = true;
    }
    
    // 顯示所有玩家手牌
    for (var hand in playerHands) {
      for (var card in hand) {
        card.isRevealed = true;
      }
    }
    
    // 顯示已打出的卡牌
    for (var card in playedCards) {
      card.isRevealed = true;
    }
    
    // 顯示棄牌堆的卡牌
    for (var card in discardedCards) {
      card.isRevealed = true;
    }
  }

  // 隱藏所有卡牌
  void _hideAllCards() {
    // 隱藏牌堆中的卡牌
    for (var card in deck) {
      card.isRevealed = false;
    }
    
    // 隱藏所有玩家手牌
    for (var hand in playerHands) {
      for (var card in hand) {
        card.isRevealed = false;
      }
    }
    
    // 隱藏已打出的卡牌
    for (var card in playedCards) {
      card.isRevealed = false;
    }
    
    // 隱藏棄牌堆的卡牌
    for (var card in discardedCards) {
      card.isRevealed = false;
    }
  }
  
  // 切換查看的玩家
  void switchViewToPlayer(int playerIndex) {
    if (playerIndex < 0 || playerIndex >= playerCount) {
      viewingPlayer = -1;
    } else {
      viewingPlayer = playerIndex;
    }
    notifyListeners();
  }

  void giveHint(int targetPlayer, {CardColor? color, int? number}) {
    if (hints <= 0) return;
    if (targetPlayer == currentPlayer) return;

    var targetHand = playerHands[targetPlayer];
    int matchCount = 0;
    for (var card in targetHand) {
      if (color != null && card.color == color) {
        card.hints['color'] = true;
        matchCount++;
      }
      if (number != null && card.number == number) {
        card.hints['number'] = true;
        matchCount++;
      }
    }

    hints--;
    gameLog.add('玩家 ${currentPlayer + 1} 向玩家 ${targetPlayer + 1} 提示了 ${color != null ? color.name : number.toString()}，匹配了 $matchCount 張牌');
    _nextTurn();
  }

  void playCard(int playerIndex, int cardIndex) {
    if (playerIndex != currentPlayer) return;

    var card = playerHands[playerIndex][cardIndex];
    playerHands[playerIndex].removeAt(cardIndex);

    // 檢查是否可以正確放置
    bool isValidPlay = _checkValidPlay(card);
    if (!isValidPlay) {
      card.isDiscarded = true;  // 標記為棄牌，而不是已打出
      discardedCards.add(card);  // 添加到棄牌堆，而不是已打出的牌堆
      fuses--;
      gameLog.add('玩家 ${playerIndex + 1} 打出了錯誤的牌：${card.color.name} ${card.number}，失誤次數增加到 ${3 - fuses}');
      if (fuses <= 0) {
        isGameOver = true;
        gameEndReason = '失誤次數達到上限';
      }
    } else {
      card.isPlayed = true;  // 只有正確打出的牌才標記為已打出
      playedCards.add(card);  // 只有正確打出的牌才添加到已打出的牌堆
      gameLog.add('玩家 ${playerIndex + 1} 成功打出了 ${card.color.name} ${card.number}');
    }

    // 抽新牌
    if (deck.isNotEmpty) {
      var newCard = deck.removeLast();
      if (devMode) {
        newCard.isRevealed = true;
      }
      playerHands[playerIndex].add(newCard);
    } else {
      gameLog.add('牌堆已空，無法抽取新牌');
    }

    _calculateScore();
    _nextTurn();
  }

  void discardCard(int playerIndex, int cardIndex) {
    if (playerIndex != currentPlayer) {
      print('棄牌失敗：不是當前玩家的回合');
      return;
    }
    if (hints >= 8) {
      print('棄牌失敗：提示數量已達上限 ($hints/8)');
      return;
    }

    var card = playerHands[playerIndex][cardIndex];
    card.isDiscarded = true;
    discardedCards.add(card);
    playerHands[playerIndex].removeAt(cardIndex);
    print('玩家 ${playerIndex + 1} 成功棄掉了 ${card.color.name} ${card.number}');
    gameLog.add('玩家 ${playerIndex + 1} 棄掉了 ${card.color.name} ${card.number}');

    // 抽新牌
    if (deck.isNotEmpty) {
      var newCard = deck.removeLast();
      if (devMode) {
        newCard.isRevealed = true;
      }
      playerHands[playerIndex].add(newCard);
    } else {
      gameLog.add('牌堆已空，無法抽取新牌');
    }

    hints = math.min(hints + 1, 8);
    _nextTurn();
  }

  bool _checkValidPlay(HanabiCard card) {
    // 如果是數字1，檢查該顏色是否已經有1了
    if (card.number == 1) {
      // 檢查該顏色是否已經有1了
      var existingOnes = playedCards.where((c) => c.color == card.color && c.number == 1).toList();
      return existingOnes.isEmpty; // 如果沒有該顏色的1，則可以打出
    }
    
    // 對於數字大於1的卡牌，檢查該顏色的前一個數字是否已經打出
    var sameColorCards = playedCards.where((c) => c.color == card.color).toList();
    
    // 如果該顏色還沒有牌被打出，那麼只能打出1
    if (sameColorCards.isEmpty) {
      return card.number == 1;
    }
    
    // 找出該顏色已經打出的最大數字
    int maxNumber = sameColorCards.map((c) => c.number).reduce(math.max);
    
    // 只有當打出的牌的數字正好比已打出的最大數字大1時，才是有效的
    return card.number == maxNumber + 1;
  }

  void _calculateScore() {
    score = 0;
    for (var color in CardColor.values) {
      if (color == CardColor.rainbow) continue;
      var sameColorCards = playedCards.where((c) => c.color == color).toList();
      if (sameColorCards.isNotEmpty) {
        score += sameColorCards.map((c) => c.number).reduce(math.max);
      }
    }
  }

  void _nextTurn() {
    currentPlayer = (currentPlayer + 1) % playerCount;
    
    // 檢查遊戲是否結束
    if (deck.isEmpty) {
      var emptyHands = playerHands.where((hand) => hand.isEmpty).length;
      if (emptyHands == playerHands.length) {
        isGameOver = true;
        gameEndReason = '所有玩家的手牌用完';
      }
    }
    
    // 檢查是否完成所有煙火
    bool allFireworksComplete = true;
    for (var color in CardColor.values) {
      if (color == CardColor.rainbow) continue;
      var sameColorCards = playedCards.where((c) => c.color == color).toList();
      if (sameColorCards.isEmpty || sameColorCards.map((c) => c.number).reduce(math.max) < 5) {
        allFireworksComplete = false;
        break;
      }
    }
    
    if (allFireworksComplete) {
      isGameOver = true;
      gameEndReason = '完美完成所有煙火！';
    }
    
    notifyListeners();
  }

  void restartGame() {
    deck = [];
    playerHands = [];
    playedCards = [];
    discardedCards = [];
    hints = 8;
    fuses = 3;
    currentPlayer = 0;
    isGameOver = false;
    score = 0;
    gameEndReason = '';
    gameLog = [];
    initializeGame();
  }
}