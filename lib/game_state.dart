import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';

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
  static const double clickYieldBase = 100.0;
  static const double passiveDripBase = 1.0;
  static const int maxBacteria = 5;
  static const double comboDecayPerSec = 3.0;
  static const double baseVirusChance = 0.02; // 2%
  static const int dnaPerRebirth = 10;

  // ── Nose upgrade definitions ─────────────────────────────────────────
  static final List<NoseUpgrade> noseUpgrades = [
    for (int i = 1; i <= 6; i++)
      NoseUpgrade(
        level: i,
        name: 'Nose Lv.$i',
        icon: i <= 3 ? '👃' : '🧬👃',
        baseCost: (100 * (i <= 3 ? pow(2.5, i - 1) : pow(3.0, i - 1))).round(),
        perClickBonus: 50.0 * i,
      ),
  ];

  // ── Room upgrade definitions ─────────────────────────────────────────
  static final List<RoomUpgrade> roomUpgrades = [
    RoomUpgrade(level: 1, name: 'Fan', icon: '🌀', baseCost: 50, dripPerSec: 1.0),
    RoomUpgrade(level: 2, name: 'Humidifier', icon: '💨', baseCost: 500, dripPerSec: 5.0),
    RoomUpgrade(level: 3, name: 'Couch', icon: '🛋️', baseCost: 2500, dripPerSec: 15.0),
    RoomUpgrade(level: 4, name: 'TV Stand', icon: '📺', baseCost: 10000, dripPerSec: 40.0),
    RoomUpgrade(level: 5, name: 'Bookshelf', icon: '📚', baseCost: 50000, dripPerSec: 100.0),
    RoomUpgrade(level: 6, name: 'Wardrobe', icon: '🪞', baseCost: 200000, dripPerSec: 250.0),
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

  /// Glut yield per click (base × nose levels)
  double get clickYield {
    double yield = clickYieldBase;
    for (int lvl = 1; lvl <= availableNoseLevels; lvl++) {
      final count = noseLevels[lvl] ?? 0;
      final def = _getNoseDef(lvl);
      yield += def.perClickBonus * count;
    }
    return yield;
  }

  /// Passive glut drip per second (room upgrades)
  double get passiveDrip {
    double drip = 0.0;
    for (int lvl = 1; lvl <= availableRoomLevels; lvl++) {
      final count = roomLevels[lvl] ?? 0;
      final def = roomUpgrades[lvl - 1]; // 0-indexed list
      drip += def.dripPerSec * count;
    }
    return drip;
  }

  /// Cost for next nose upgrade at given level
  int noseCost(int level) {
    final def = _getNoseDef(level);
    final count = noseLevels[level] ?? 0;
    return (def.baseCost * pow(1.8, count)).round();
  }

  /// Cost for next room upgrade at given level
  int roomCost(int level) {
    final def = roomUpgrades[level - 1];
    final count = roomLevels[level] ?? 0;
    return (def.baseCost * pow(1.8, count)).round();
  }

  /// DNA multiplier from unspent DNA (+10% per point)
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
    comboPoints++;
    _maybeSpawnBacteria();
  }

  /// Tap a bacteria in the tank
  void clickBacteria() {
    if (bacteriaInTank <= 0) return;
    bacteriaInTank--;
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
    if (upgradeId == 'virus_slots') maxVirusSlots = 1 + (currentLevel + 1);
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
    comboPoints = max(0.0, comboPoints - (comboDecayPerSec * dt));
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
}
