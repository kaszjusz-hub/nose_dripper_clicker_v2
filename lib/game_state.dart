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
    if (!bacteriaUnlocked) return;
    if (bacteriaInTank >= maxBacteria) return;

    final now = DateTime.now();
    final secondsElapsed = now.difference(_lastBacteriaSpawnCheck).inMilliseconds / 1000.0;

    // Try to spawn every ~30 seconds of game time
    if (secondsElapsed >= 30.0) {
      if (_random.nextDouble() < 0.40) {
        bacteriaInTank++;
      }
      _lastBacteriaSpawnCheck = now;
    }
  }

  static const Map<String, Map<String, dynamic>> _virusData = {
    'speed':   {'name': 'Wirus Szybkości',  'icon': '⚡', 'bonus': 0.05},
    'luck':    {'name': 'Wirus Szczęścia',   'icon': '🍀', 'bonus': 0.10},
    'yield':   {'name': 'Wirus Wydajności', 'icon': '💎', 'bonus': 0.05},
    'combo':   {'name': 'Wirus Combo',      'icon': '🔥', 'bonus': 0.03},
    'passive': {'name': 'Wirus Pasywny',     'icon': '🌊', 'bonus': 0.08},
  };

  String _virusName(String effect) => _virusData[effect]?['name'] ?? 'Nieznany Wirus';
  String _virusIcon(String effect) => _virusData[effect]?['icon'] ?? '☣️';
  double _virusBonus(String effect) => _virusData[effect]?['bonus'] ?? 0.0;

  // ── Core resources ────────────────────────────────────────────────────
  double tankMl = 0.0;
  int glutCount = 0;
  int dnaPoints = 0; // total earned (persistent)
  int unspentDna = 0; // available to spend in DNA shop
  int tissues = 0; // premium currency

  // ── Upgrades (reset on Rebirth) ──────────────────────────────────────
  Map<int, int> noseLevels = {}; // level -> count purchased
  Map<int, int> roomLevels = {}; // level -> count purchased

  // ── DNA Upgrades (persistent across Rebirth) ─────────────────────────
  Map<String, int> dnaUpgradeLevels = {};

  // ── Systems ──────────────────────────────────────────────────────────
  double comboPoints = 0.0;
  int bacteriaInTank = 0;
  bool virusEvolutionUnlocked = false;
  int maxVirusSlots = 1; // starts at 1, expandable via DNA
  int activeVirusSlots = 0;
  List<Map<String, dynamic>> inventory = []; // found viruses/items
  List<Map<String, dynamic>> activeViruses = []; // equipped viruses

  // ── Thresholds ──────────────────────────────────────────────────────
  static const double baseRebirthThreshold = 10000000.0; // 10M ml — always constant
  double get rebirthThreshold => baseRebirthThreshold;
  static const double bacteriaUnlockThreshold = 3000000.0; // 3M ml

  // ── Internal ─────────────────────────────────────────────────────────
  late Random _random;
  // ignore: unused_field
  late DateTime _bacteriaSpawnTime;
  late DateTime _lastBacteriaSpawnCheck;
  Timer? _gameLoopTimer;
  final List<VoidCallback> _tickListeners = [];

  /// Register a listener that gets called every game tick (100ms)
  void addTickListener(VoidCallback listener) {
    _tickListeners.add(listener);
  }

  void removeTickListener(VoidCallback listener) {
    _tickListeners.remove(listener);
  }

  /// Start the shared game loop. Call once from app init.
  void startGameLoop() {
    if (_gameLoopTimer != null) return;
    _gameLoopTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      gameTick(0.1);
      for (final listener in List.of(_tickListeners)) {
        listener();
      }
    });
  }

  void stopGameLoop() {
    _gameLoopTimer?.cancel();
    _gameLoopTimer = null;
  }

  // ── Constants ────────────────────────────────────────────────────────
  static const double clickYieldBase = 1.0; // per click, before upgrades
  static const double passiveDripBase = 1.0;
  static const int maxBacteria = 5;
  static const double comboDecayPerSec = 3.0;
  static const double maxComboPoints = 200.0; // combo bar cap
  static const double baseVirusChance = 0.02; // 2%
  static const int dnaPerRebirth = 10;

  // ── Nose upgrade definitions ─────────────────────────────────────────
  // Game Design: First upgrade costs ~15 glutów (10% of base clickYield)
  // so players can buy it after ~1 click, giving instant feedback.
  // Scaling at 1.8^i keeps each level affordable while preserving
  // exponential progression — Lv6 is ~283 glutów (reachable quickly).
  // perClickBonus reduced from 50*i to 10*i to match — max +60/click
  // on top of 100 base keeps nose upgrades a meaningful but not dominant
  // source of income vs room upgrades (passive drip).
  static final List<NoseUpgrade> noseUpgrades = [
    NoseUpgrade(level: 1, name: 'Nose Lv.1', icon: '👃', baseCost: 5, perClickBonus: 0.1),
    NoseUpgrade(level: 2, name: 'Nose Lv.2', icon: '👃', baseCost: 50, perClickBonus: 1.0),
    NoseUpgrade(level: 3, name: 'Nose Lv.3', icon: '👃', baseCost: 500, perClickBonus: 10.0),
    NoseUpgrade(level: 4, name: 'Nose Lv.4', icon: '🧬👃', baseCost: 5000, perClickBonus: 100.0),
    NoseUpgrade(level: 5, name: 'Nose Lv.5', icon: '🧬👃', baseCost: 50000, perClickBonus: 1000.0),
    NoseUpgrade(level: 6, name: 'Nose Lv.6', icon: '🧬👃', baseCost: 500000, perClickBonus: 10000.0),
  ];

  // ── Room upgrade definitions ─────────────────────────────────────────
  static final List<RoomUpgrade> roomUpgrades = [
    RoomUpgrade(level: 1, name: 'Fan', icon: '🌀', baseCost: 5, dripPerSec: 0.2),
    RoomUpgrade(level: 2, name: 'Humidifier', icon: '💨', baseCost: 16, dripPerSec: 0.6),
    RoomUpgrade(level: 3, name: 'Couch', icon: '🛋️', baseCost: 51, dripPerSec: 1.5),
    RoomUpgrade(level: 4, name: 'TV Stand', icon: '📺', baseCost: 164, dripPerSec: 4.0),
    RoomUpgrade(level: 5, name: 'Bookshelf', icon: '📚', baseCost: 525, dripPerSec: 10.0),
    RoomUpgrade(level: 6, name: 'Wardrobe', icon: '🪞', baseCost: 1680, dripPerSec: 30.0),
  ];

  // ── DNA upgrade definitions ────────────────────────────────────────────
  static final List<DnaUpgradeDef> dnaUpgrades = [
    DnaUpgradeDef(
      id: 'nose_slots',
      title: 'Dodatkowe sloty Nosa',
      description: 'Odblokowuje 4., 5., 6. ulepszenie nosa.',
      icon: '👃',
      baseCostDna: 3,
      maxLevel: 3,
      unlocks: ['nose_4', 'nose_5', 'nose_6'],
    ),
    DnaUpgradeDef(
      id: 'room_expansion',
      title: 'Rozbudowa Pokoju',
      description: 'Odblokowuje silniejsze meble (poziomy 4–6).',
      icon: '🛋️',
      baseCostDna: 3,
      maxLevel: 3,
      unlocks: ['room_4', 'room_5', 'room_6'],
    ),
    DnaUpgradeDef(
      id: 'virus_evolution',
      title: 'Ewolucja Bakterii',
      description: 'Odblokowuje szansę na mutację bakterii w wirusa (bazowo 2%).',
      icon: '🦠',
      baseCostDna: 5,
      maxLevel: 1,
    ),
    DnaUpgradeDef(
      id: 'virulence',
      title: 'Wirulencja',
      description: 'Zwiększa szansę mutacji bakterii w wirusa o +3% per level.',
      icon: '☣️',
      baseCostDna: 4,
      maxLevel: 5,
    ),
    DnaUpgradeDef(
      id: 'virus_slots',
      title: 'Sloty wirusów',
      description: 'Dodaje +1 aktywny slot wirusa (baza: 1, max: 5).',
      icon: '🎒',
      baseCostDna: 5,
      maxLevel: 4,
    ),
  ];

  // ──────────────────────────────────────────────────────────────────────────
  //  GETTERS
  // ──────────────────────────────────────────────────────────────────────────

  /// How many nose upgrade levels are available (3 base + DNA unlocks)
  int get availableNoseLevels {
    final unlocked = dnaUpgradeLevels['nose_slots'] ?? 0;
    return 3 + unlocked; // max 6
  }

  /// How many room upgrade levels are available
  int get availableRoomLevels {
    final unlocked = dnaUpgradeLevels['room_expansion'] ?? 0;
    return 3 + unlocked;
  }

  /// Glut yield per click (base × nose levels × threshold multipliers)
  double get clickYield {
    double yield = clickYieldBase;
    for (int lvl = 1; lvl <= availableNoseLevels; lvl++) {
      yield += getEffectiveNoseBonus(lvl);
    }
    return yield;
  }

  /// Passive glut drip per second (room upgrades × threshold multipliers)
  double get passiveDrip {
    double drip = 0.0;
    for (int lvl = 1; lvl <= availableRoomLevels; lvl++) {
      drip += getEffectiveRoomBonus(lvl);
    }
    return drip;
  }

  /// Cost for next nose upgrade at given level
  int noseCost(int level) {
    final def = _getNoseDef(level);
    final count = noseLevels[level] ?? 0;
    return (def.baseCost * pow(1.25, count)).round();
  }

  /// Cost for next room upgrade at given level
  int roomCost(int level) {
    final def = roomUpgrades[level - 1];
    final count = roomLevels[level] ?? 0;
    return (def.baseCost * pow(1.8, count)).round();
  }

  // ─── Threshold / Milestone System ────────────────────────────────────
  /// Threshold milestones that double the bonus of an upgrade.
  /// 10, 25, 50, 100, 200, 300, 400... (every 100 from 100)
  List<int> getThresholdMilestones() {
    final milestones = <int>[10, 25, 50];
    int t = 100;
    while (milestones.length < 20) {
      milestones.add(t);
      t += 100;
    }
    return milestones;
  }

  /// How many milestones have been crossed for a given nose upgrade level.
  int getThresholdCount(int level) {
    final count = noseLevels[level] ?? 0;
    final milestones = getThresholdMilestones();
    return milestones.where((m) => count >= m).length;
  }

  /// The effective bonus multiplier for a nose upgrade (2^thresholdCount).
  int getThresholdMultiplier(int level) {
    final count = getThresholdCount(level);
    return pow(2, count).toInt();
  }

  /// Next milestone threshold for a given nose upgrade level,
  /// or -1 if no more milestones.
  int getNextThreshold(int level) {
    final count = noseLevels[level] ?? 0;
    final milestones = getThresholdMilestones();
    for (final m in milestones) {
      if (count < m) return m;
    }
    return -1;
  }

  /// Effective per-click bonus for a nose upgrade level, including thresholds AND DNA multiplier.
  double getEffectiveNoseBonus(int level) {
    final count = noseLevels[level] ?? 0;
    if (count == 0) return 0.0;
    final def = _getNoseDef(level);
    final threshMult = getThresholdMultiplier(level);
    return def.perClickBonus * count * threshMult * dnaMultiplier;
  }

  /// Effective drip/sec bonus for a room upgrade level, including thresholds AND DNA multiplier.
  double getEffectiveRoomBonus(int level) {
    final count = roomLevels[level] ?? 0;
    if (count == 0) return 0.0;
    final def = roomUpgrades[level - 1];
    final threshMult = getThresholdMultiplier(level);
    return def.dripPerSec * count * threshMult * dnaMultiplier;
  }

  /// DNA multiplier from unspent DNA (+10% per point). Affects click, passive, AND upgrade bonuses.
  double get dnaMultiplier => 1.0 + (unspentDna * 0.10);

  /// Combo multiplier: 1.00 → 2.00 (each 5 combo = +0.05x, cap at 100)
  double get comboMultiplier {
    final cappedCombo = comboPoints.clamp(0.0, 100.0);
    final level = (cappedCombo ~/ 5).clamp(0, 20);
    return 1.0 + (level * 0.05);
  }

  /// Total active multiplier
  double get totalMultiplier => dnaMultiplier * comboMultiplier;

  /// Current virus chance (%)
  double get virusChance {
    if (!virusEvolutionUnlocked) return 0.0;
    final virulenceLevel = dnaUpgradeLevels['virulence'] ?? 0;
    return baseVirusChance + (virulenceLevel * 0.03);
  }

  /// Whether rebirth button should be visible
  bool get rebirthAvailable => tankMl >= rebirthThreshold;

  /// DNA to earn if rebirth now — scales with tank fill (10 DNA per full threshold)
  int get dnaToEarn {
    final ratio = tankMl / rebirthThreshold;
    if (ratio < 1.0) return 0;
    return (ratio.floor() * dnaPerRebirth).clamp(0, 9999);
  }

  /// Progress toward next full rebirth cycle (can exceed 1.0 for 2x, 3x DNA)
  double get rebirthProgress => tankMl / rebirthThreshold;

  /// Whether bacteria can appear
  bool get bacteriaUnlocked => tankMl >= bacteriaUnlockThreshold;

  /// Whether DNA shop is unlocked (after first rebirth)
  bool get dnaShopUnlocked => dnaPoints > 0;

  // ──────────────────────────────────────────────────────────────────────────
  //  ACTIONS
  // ──────────────────────────────────────────────────────────────────────────

  /// Main click handler
  void clickNose() {
    final gained = clickYield * totalMultiplier;
    tankMl += gained;
    glutCount += gained.round();
    comboPoints = min(comboPoints + 1, maxComboPoints);
    _maybeSpawnBacteria();
  }

  /// Tap a bacteria in the tank
  void clickBacteria() {
    if (bacteriaInTank <= 0) return;
    bacteriaInTank--;
    // Reward: passive drip per second × 300
    glutCount += (passiveDrip * 300).round();
    if (virusEvolutionUnlocked) {
      if (_random.nextDouble() < virusChance) {
        _spawnVirus();
      }
    }
  }

  /// Buy a nose upgrade
  bool buyNoseUpgrade(int level) {
    if (level > availableNoseLevels) return false;
    final cost = noseCost(level);
    if (glutCount < cost) return false;
    glutCount -= cost;
    noseLevels[level] = (noseLevels[level] ?? 0) + 1;
    return true;
  }

  /// Buy a room upgrade
  bool buyRoomUpgrade(int level) {
    if (level > availableRoomLevels) return false;
    final cost = roomCost(level);
    if (glutCount < cost) return false;
    glutCount -= cost;
    roomLevels[level] = (roomLevels[level] ?? 0) + 1;
    return true;
  }

  /// Buy a DNA shop upgrade
  bool buyDnaUpgrade(String upgradeId) {
    final def = dnaUpgrades.firstWhere((u) => u.id == upgradeId);
    final currentLevel = dnaUpgradeLevels[upgradeId] ?? 0;
    if (currentLevel >= def.maxLevel) return false;
    final cost = def.baseCostDna;
    if (unspentDna < cost) return false;
    unspentDna -= cost;
    dnaUpgradeLevels[upgradeId] = currentLevel + 1;
    // Apply unlocks
    if (upgradeId == 'virus_evolution') virusEvolutionUnlocked = true;
    if (upgradeId == 'virus_slots') maxVirusSlots = min(5, 1 + currentLevel);
    return true;
  }

  /// Perform rebirth — resets tank to 0, keeps DNA upgrades
  void doRebirth() {
    final earned = dnaToEarn;
    dnaPoints += earned;
    unspentDna += earned;

    // Reset non-persistent state
    tankMl = 0.0;
    glutCount = 0;
    noseLevels.clear();
    roomLevels.clear();
    bacteriaInTank = 0;
    comboPoints = 0.0;
    activeVirusSlots = 0;
    activeViruses.clear();
    inventory.clear();

    // Rebirth threshold stays constant — no increase!
    _bacteriaSpawnTime = DateTime.now();
    _lastBacteriaSpawnCheck = DateTime.now();
  }

  // ──────────────────────────────────────────────────────────────────────────
  //  GAME LOOP (call ~60fps)
  // ──────────────────────────────────────────────────────────────────────────

  void gameTick(double dt) {
    // Passive drip
    if (passiveDrip > 0) {
      final gained = passiveDrip * dt * totalMultiplier;
      tankMl += gained;
      glutCount += gained.round();
    }
    // Combo decay
    comboPoints = max(0.0, comboPoints - (comboDecayPerSec * dt)).clamp(0, maxComboPoints);
    // Auto bacteria spawn (timer-based, not click-based)
    _checkAutoBacteriaSpawn();
  }

  // ──────────────────────────────────────────────────────────────────────────
  //  INTERNAL
  // ──────────────────────────────────────────────────────────────────────────

  NoseUpgrade _getNoseDef(int level) {
    if (level < 1 || level > 6) throw RangeError('Nose level must be 1–6');
    final costMult = level <= 3 ? pow(2.5, level - 1) : pow(3.0, level - 1);
    return NoseUpgrade(
      level: level,
      name: 'Nose Lv.$level',
      icon: level <= 3 ? '👃' : '🧬👃',
      baseCost: (100 * costMult).round(),
      perClickBonus: 50.0 * level,
    );
  }

  void _spawnVirus() {
    final effects = ['speed', 'luck', 'yield', 'combo', 'passive'];
    final usedEffects = inventory.map((v) => v['effect'] as String? ?? '').toSet();
    final available = effects.where((e) => !usedEffects.contains(e)).toList();
    if (available.isEmpty) return;

    final effect = available[_random.nextInt(available.length)];
    final virus = {
      'effect': effect,
      'name': _virusName(effect),
      'icon': _virusIcon(effect),
      'bonus': _virusBonus(effect),
      'equipped': false,
    };
    inventory.add(virus);
  }

  void toggleEquipVirus(int index) {
    if (index >= inventory.length) return;
    final virus = inventory[index];
    final isEquipped = virus['equipped'] == true;
    if (isEquipped) {
      virus['equipped'] = false;
      activeViruses.removeWhere((v) => v['effect'] == virus['effect']);
      activeVirusSlots = max(0, activeVirusSlots - 1);
    } else {
      if (activeVirusSlots >= maxVirusSlots) return;
      virus['equipped'] = true;
      activeViruses.add(virus);
      activeVirusSlots++;
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  //  PERSISTENCE
  // ──────────────────────────────────────────────────────────────────────────

  Future<String> get _savePath async {
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}${Platform.pathSeparator}nose_dripper_save.json';
  }

  /// Serialize full game state to JSON
  Future<void> saveGame() async {
    final data = {
      'tankMl': tankMl,
      'glutCount': glutCount,
      'comboPoints': comboPoints,
      'noseLevels': Map<int, int>.from(noseLevels),
      'roomLevels': Map<int, int>.from(roomLevels),
      'dnaUpgradeLevels': Map<String, int>.from(dnaUpgradeLevels),
      'dnaPoints': dnaPoints,
      'unspentDna': unspentDna,
      'bacteriaInTank': bacteriaInTank,
      'virusEvolutionUnlocked': virusEvolutionUnlocked,
      'maxVirusSlots': maxVirusSlots,
      'activeVirusSlots': activeVirusSlots,
      'activeViruses': List<Map<String, dynamic>>.from(activeViruses),
      'inventory': List<Map<String, dynamic>>.from(inventory),
    };

    final path = await _savePath;
    final file = File(path);
    await file.writeAsString(jsonEncode(data));
  }

  /// Load game state from JSON. Returns true if successful.
  Future<bool> loadGame() async {
    try {
      final path = await _savePath;
      final file = File(path);
      if (!await file.exists()) return false;

      final content = await file.readAsString();
      final data = jsonDecode(content) as Map<String, dynamic>;

      tankMl = (data['tankMl'] as num).toDouble();
      glutCount = data['glutCount'] as int;
      comboPoints = (data['comboPoints'] as num).toDouble();
      noseLevels = Map<int, int>.from((data['noseLevels'] as Map).map((k, v) => MapEntry(int.parse(k.toString()), v as int)));
      roomLevels = Map<int, int>.from((data['roomLevels'] as Map).map((k, v) => MapEntry(int.parse(k.toString()), v as int)));
      dnaUpgradeLevels = Map<String, int>.from(data['dnaUpgradeLevels'] as Map);
      dnaPoints = data['dnaPoints'] as int;
      unspentDna = data['unspentDna'] as int;
      bacteriaInTank = data['bacteriaInTank'] as int;
      virusEvolutionUnlocked = data['virusEvolutionUnlocked'] as bool;
      maxVirusSlots = data['maxVirusSlots'] as int;
      activeVirusSlots = data['activeVirusSlots'] as int;
      activeViruses = List<Map<String, dynamic>>.from(data['activeViruses'] as List);
      inventory = List<Map<String, dynamic>>.from(data['inventory'] as List);

      return true;
    } catch (e) {
      // If loading fails, start fresh
      _resetForNewGame();
      return false;
    }
  }

  /// Check if a save file exists
  Future<bool> get hasSaveGame async {
    try {
      final path = await _savePath;
      final file = File(path);
      return await file.exists();
    } catch (_) {
      return false;
    }
  }
}

