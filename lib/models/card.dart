import 'package:flutter/material.dart';

class HanabiCard {
  final CardColor color;
  final int number;
  bool isRevealed;
  bool isPlayed;
  bool isDiscarded;
  Map<String, bool> hints;

  HanabiCard({
    required this.color,
    required this.number,
    this.isRevealed = false,
    this.isPlayed = false,
    this.isDiscarded = false,
  }) : hints = {
    'color': false,
    'number': false,
  };
}

enum CardColor {
  red,
  blue,
  green,
  white,
  yellow,
  rainbow, // 進階模式用
}

extension CardColorExtension on CardColor {
  String get name {
    switch (this) {
      case CardColor.red:
        return '紅色';
      case CardColor.blue:
        return '藍色';
      case CardColor.green:
        return '綠色';
      case CardColor.white:
        return '白色';
      case CardColor.yellow:
        return '黃色';
      case CardColor.rainbow:
        return '彩虹';
    }
  }
  
  Color get displayColor {
    switch (this) {
      case CardColor.red:
        return Colors.red;
      case CardColor.blue:
        return Colors.blue;
      case CardColor.green:
        return Colors.green;
      case CardColor.white:
        return Colors.white;
      case CardColor.yellow:
        return Colors.yellow;
      case CardColor.rainbow:
        return Colors.purple;
    }
  }
  
  Color get textColor {
    switch (this) {
      case CardColor.white:
      case CardColor.yellow:
        return Colors.black;
      default:
        return Colors.white;
    }
  }
}