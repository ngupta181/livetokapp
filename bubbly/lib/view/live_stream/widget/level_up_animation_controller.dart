import 'package:flutter/material.dart';

class LevelUpAnimationController extends ChangeNotifier {
  // Singleton instance
  static final LevelUpAnimationController _instance =
      LevelUpAnimationController._internal();
  factory LevelUpAnimationController() => _instance;
  
  LevelUpAnimationController._internal() {
    print("LevelUpAnimationController initialized");
  }

  // Level up animation data
  bool _showLevelAnimation = false;
  int _oldLevel = 0;
  int _newLevel = 0;

  // Getters
  bool get showLevelAnimation => _showLevelAnimation;
  int get oldLevel => _oldLevel;
  int get newLevel => _newLevel;

  // Show level up animation
  void showLevelUp(int oldLevel, int newLevel) {
    if (oldLevel < newLevel) {
      _oldLevel = oldLevel;
      _newLevel = newLevel;
      _showLevelAnimation = true;
      notifyListeners();
      
      // Auto-hide after 3 seconds
      Future.delayed(Duration(seconds: 3), () {
        hideAnimation();
      });
    }
  }

  // Hide level up animation
  void hideAnimation() {
    if (_showLevelAnimation) {
      _showLevelAnimation = false;
      notifyListeners();
    }
  }
} 