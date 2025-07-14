import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';

class AudioManager {
  static final AudioManager _instance = AudioManager._internal();
  factory AudioManager() => _instance;
  AudioManager._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isSoundEnabled = true;
  double _volume = 1.0;

  // Audio file paths
  static const String _battleStartSound = 'assets/audios/pk_battle/battle_start.mp3';
  static const String _winSound = 'assets/audios/pk_battle/win_sound.mp3';
  static const String _endCountdownSound = 'assets/audios/pk_battle/end_countdown.mp3';

  // Getters and setters
  bool get isSoundEnabled => _isSoundEnabled;
  double get volume => _volume;

  void setSoundEnabled(bool enabled) {
    _isSoundEnabled = enabled;
  }

  void setVolume(double volume) {
    _volume = volume.clamp(0.0, 1.0);
    _audioPlayer.setVolume(_volume);
  }

  // Play battle start sound
  Future<void> playBattleStartSound() async {
    if (!_isSoundEnabled) return;
    
    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(AssetSource(_battleStartSound));
      await _audioPlayer.setVolume(_volume);
    } catch (e) {
      print('Error playing battle start sound: $e');
    }
  }

  // Play winner sound
  Future<void> playWinnerSound() async {
    if (!_isSoundEnabled) return;
    
    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(AssetSource(_winSound));
      await _audioPlayer.setVolume(_volume);
    } catch (e) {
      print('Error playing winner sound: $e');
    }
  }

  // Play battle end sound
  Future<void> playBattleEndSound() async {
    if (!_isSoundEnabled) return;
    
    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(AssetSource(_winSound));
      await _audioPlayer.setVolume(_volume);
    } catch (e) {
      print('Error playing battle end sound: $e');
    }
  }

  // Play countdown sound
  Future<void> playCountdownSound() async {
    if (!_isSoundEnabled) return;
    
    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(AssetSource(_endCountdownSound));
      await _audioPlayer.setVolume(_volume);
    } catch (e) {
      print('Error playing countdown sound: $e');
    }
  }

  // Play gift sound effect
  Future<void> playGiftSound() async {
    if (!_isSoundEnabled) return;
    
    try {
      // Use system sound for gift (or add custom gift sound)
      await SystemSound.play(SystemSoundType.click);
    } catch (e) {
      print('Error playing gift sound: $e');
    }
  }

  // Stop all sounds
  Future<void> stopAllSounds() async {
    try {
      await _audioPlayer.stop();
    } catch (e) {
      print('Error stopping sounds: $e');
    }
  }

  // Dispose resources
  void dispose() {
    _audioPlayer.dispose();
  }
}

