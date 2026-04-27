import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

// ─── Upgrades ────────────────────────────────────────────────────────────────

class NoseUpgrade {
  final int level; // 1–6 (first 3 always available, 4–6 need DNA)
  final String name;
  final String icon;
  final int baseCost; // glut cost
  final double perClickBonus; // additional glut per click
  NoseUpgrade({required this.level, required this.name, required this.icon, required this.baseCost, required this.perClickBonus});
}

class RoomUpgrade {
  final int level; // 1–6
  final String name;
  final String icon;
  final int baseCost; // glut cost
  final double dripPerSec; // passive glut/s
  RoomUpgrade({required this.level, required this.name, required this.icon, required this.baseCost, required this.dripPerSec});
}

class DnaUpgradeDef {
  final String id;
  final String title;
  final String description;
  final String icon;
  final int baseCostDna;
  final int maxLevel;
  final bool unlocksAtDnaShop;
  final List<String> unlocks; // what it unlocks
  DnaUpgradeDef({required this.id, required this.title, required this.description, required this.icon, required this.baseCostDna, this.maxLevel = 1, this.unlocksAtDnaShop = false, this.unlocks = const []});
}

// ─── GameState ───────────────────────────────────────────────────────────────

class GameState {
  static final GameState _instance = GameState._internal();
  static GameState get instance => _instance;
  factory GameState() => _instance;

  GameState._internal() {
    _resetForNewGame();
    _random = Random();
    _bacteriaSpawnTime = DateTime.now();
    _lastBacteriaSpawnCheck = DateTime.now();
  }
  
  void _resetForNewGame() {
    tankMl = 0.0;
    glutCount = 0;
    comboPoints = 0.0;
    bacteriaInTank = 0;
    noseLevels.clear();
    roomLevels.clear();
    dnaUpgradeLevels.clear();
    dnaPoints = 0;
    unspentDna = 0;
    tissues = 0;
    virusEvolutionUnlocked = false;
    maxVirusSlots = 1;
    activeVirusSlots = 0;
    activeViruses.clear();
    inventory.clear();
    _bacteriaSpawnTime = DateTime.now();
    _lastBacteriaSpawnCheck = DateTime.now();
  }

  /// Public full reset (also used by cheat tools)
  void fullReset() => _resetForNewGame();

  // Chance to spawn bacteria on click
  void _maybeSpawnBacteria() {
    if (bacteriaInTank >= maxBacteria) return;
    final fillRatio = (tankMl / rebirthThreshold).clamp(0.0, 1.0);
    final chance = 0.05 + (fillRatio * 0.10);
    if (_random.nextDouble() < chance) {
      bacteriaInTank++;
    }
  }

  void _checkAutoBacteriaSpawn() {

  // Stop timers (call from dispose)

  // ===== Allergy system (model only) =====
  bool _allergyActive = false;
  DateTime? _allergyEndsAt;

  bool get allergyActive => _allergyActive;
  double get allergyRemainingSeconds {
    if (!_allergyActive || _allergyEndsAt == null) return 0.0;
    final remaining = _allergyEndsAt!.difference(DateTime.now());
    return remaining.inMilliseconds / 1000.0;
  }

  /// Call this to activate the allergy buff for 30 seconds (e.g., when pollen is caught)
  void activateAllergy() {
    _allergyActive = true;
    _allergyEndsAt = DateTime.now().add(const Duration(seconds: 30));
  }

  /// Call this periodically (e.g., from UI timer) to update state; returns true if allergy just ended
  bool updateAllergy() {
    if (!_allergyActive || _allergyEndsAt == null) return false;
    if (DateTime.now().isAfter(_allergyEndsAt!)) {
      _allergyActive = false;
      _allergyEndsAt = null;
      return true; // just ended
    }
    return false;
  }
}