import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'game_state.dart';

class NoseScreen extends StatefulWidget {
  const NoseScreen({super.key});

  @override
  State<NoseScreen> createState() => _NoseScreenState();
}

class _NoseScreenState extends State<NoseScreen>
    with TickerProviderStateMixin {
  final GameState gs = GameState.instance;
  late final TabController _tabController;
  VoidCallback? _tickListener;
  late final AnimationController _charController;
  late final AnimationController _waveController;
  late final AnimationController _bubbleController;
  final List<_Particle> _particles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tickListener = () {
      if (mounted) setState(() {});
    };
    gs.addTickListener(_tickListener!);
    gs.startGameLoop();
    _charController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _waveController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    _bubbleController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    if (_tickListener != null) gs.removeTickListener(_tickListener!);
    _tabController.dispose();
    _charController.dispose();
    _waveController.dispose();
    _bubbleController.dispose();
    super.dispose();
  }

  void _onTap() {
    gs.clickNose();
    _charController.forward(from: 0);
    _addParticle();
  }

  void _addParticle() {
    _particles.add(_Particle(
      x: 0.5 + (0.2 * (1.0 - 2.0 * _random.nextDouble())),
      y: 0.4,
      delay: 0.0,
      targetY: 0.75 + (0.1 * _random.nextDouble()),
    ));
    // Clean old particles
    if (_particles.length > 20) _particles.removeAt(0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0d0f0a),
      body: SafeArea(
        child: Column(
          children: [
            _buildHUD(),
            // POSTAĆ (character) — flex 3
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                color: const Color(0xFF0d0f0a),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _DottedPatternPainter(),
                      ),
                    ),
                    GestureDetector(
                      onTap: _onTap,
                      behavior: HitTestBehavior.opaque,
                      child: AnimatedBuilder(
                        animation: _charController,
                        builder: (ctx, child) {
                          final scale = 1.0 + (0.15 * (1.0 - _charController.value));
                          final opacity = 1.0 - (0.3 * _charController.value);
                          return Opacity(
                            opacity: opacity,
                            child: Transform.scale(
                              scale: scale,
                              child: child,
                            ),
                          );
                        },
                        child: const Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('🤧', style: TextStyle(fontSize: 120)),
                            SizedBox(height: 8),
                            Text('KLIKNIJ!',
                                style: TextStyle(
                                    color: Color(0xFFcdd9b5),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    letterSpacing: 1)),
                          ],
                        ),
                      ),
                    ),
                    ..._buildParticleWidgets(),
                  ],
                ),
              ),
            ),
            // KANAŁ visualization — fixed height
            _buildCanalVisualization(gs),
            // UPGRADE PANEL — scrollable
            Expanded(
              flex: 2,
              child: _buildUpgradePanel(),
            ),
          ],
        ),
      ),
    );
  }

  // HUD (resources + combo)
  Widget _buildHUD() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                spacing: 6,
                children: [
                  _resourceChip('🟢', '${gs.glutCount}'),
                  _resourceChip('🧬', '${gs.unspentDna} DNA'),
                  _resourceChip('🧻', '${gs.tissues} chust.'),
                ],
              ),
              Text('🟢 +${gs.passiveDrip.toStringAsFixed(1)} ml/s',
                style: const TextStyle(
                  color: Color(0xFFa8ff5a),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (kDebugMode)
                IconButton(
                  icon: const Icon(Icons.build, size: 20),
                  color: const Color(0xFF7a8a62),
                  onPressed: _openDevCheats,
                ),
            ],
          ),
          if (gs.comboPoints > 0) ...[
            const SizedBox(height: 6),
            _buildComboBar(),
          ],
        ],
      ),
    );
  }

  Widget _resourceChip(String icon, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF161c10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2d3d1e)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 6),
          Text(value,
              style: const TextStyle(
                  color: Color(0xFFcdd9b5), fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildComboBar() {
    final comboCap = 200.0;
    final ratio = (gs.comboPoints.clamp(0.0, comboCap) / comboCap).clamp(0.0, 1.0);
    final displayPoints = gs.comboPoints.clamp(0.0, comboCap);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF161c10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF2d3d1e)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('COMBO ${displayPoints.toInt()}/200',
                  style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF7a8a62),
                      letterSpacing: 1,
                      fontWeight: FontWeight.bold)),
              Text('×${gs.comboMultiplier.toStringAsFixed(2)}',
                  style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFFa8ff5a),
                      fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 5,
              backgroundColor: Colors.black54,
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFa8ff5a)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCanalVisualization(GameState gs) {
    final height = 60.0;
    final progress = (gs.tankMl / gs.rebirthThreshold).clamp(0.0, 1.0);
    return AnimatedBuilder(
      animation: Listenable.merge([_waveController, _bubbleController]),
      builder: (ctx, child) {
        return Container(
          height: height,
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: Color(0xFF2d3d1e), width: 2),
              bottom: BorderSide(color: Color(0xFF2d3d1e), width: 2),
            ),
          ),
          child: Stack(
            children: [
              // Brick texture background
              CustomPaint(
                size: Size.infinite,
                painter: _BrickWallPainter(),
              ),
              // Canal water fill
              ClipRect(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    height: height * progress.clamp(0.05, 1.0),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          const Color(0xFF7ec850).withValues(alpha: 0.7),
                          const Color(0xFF4a8a2a).withValues(alpha: 0.9),
                          const Color(0xFF2d3d1e),
                        ],
                      ),
                    ),
                    child: CustomPaint(
                      painter: _SlimeWavePainterMini(
                        waveT: _waveController.value,
                        intensity: progress,
                      ),
                    ),
                  ),
                ),
              ),
              // Text overlay
              Center(
                child: Text(
                  '${gs.tankMl.toStringAsFixed(0)} ml',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                  ),
                ),
              ),
            ],
            ),
          );
      },
    );
  }

  // Particles
  List<Widget> _buildParticleWidgets() {
    final size = MediaQuery.of(context).size;
    final now = DateTime.now().millisecondsSinceEpoch;
    return _particles.asMap().entries.where((e) {
      final age = (now - e.value.born) / 1000.0;
      return age < 2.0;
    }).map((e) {
      final p = e.value;
      final age = (now - e.value.born) / 1000.0;
      final progress = (age / 1.5).clamp(0.0, 1.0);
      final y = (p.y + (p.targetY - p.y) * progress) * size.height;
      final opacity = 1.0 - progress;
      return Positioned(
        left: p.x * size.width,
        top: y,
        child: Opacity(
          opacity: opacity,
          child: const Text('💧', style: TextStyle(fontSize: 16)),
        ),
      );
    }).toList();
  }

  // Individual threshold progress row for a single upgrade level
  Widget _buildThresholdRow(int level, bool isNose) {
    final count = isNose ? (gs.noseLevels[level] ?? 0) : (gs.roomLevels[level] ?? 0);
    final milestones = gs.getThresholdMilestones();
    final next = gs.getNextThreshold(level);
    final mult = gs.getThresholdMultiplier(level);

    if (next == -1) {
      return Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Text('MAX ×$mult',
            style: const TextStyle(color: Color(0xFFd4af37), fontSize: 9)),
      );
    }

    if (count == 0) {
      // Show "0/X → ×2" with empty progress
      return _miniThresholdBar(0.0, milestones.isNotEmpty ? milestones[0] : 10, 0, 0);
    }

    // find previous milestone
    final mIdx = milestones.indexOf(next);
    final prev = mIdx > 0 ? milestones[mIdx - 1] : 0;
    final progress = ((count - prev) / (next - prev)).clamp(0.0, 1.0);
    return _miniThresholdBar(progress, next, mult, count);
  }

  // Mini threshold progress bar displayed beneath each upgrade card
  Widget _miniThresholdBar(double progress, int nextThresh, int currentMult, int current) {
    final displayCurrent = current;
    final nextMult = currentMult * 2;
    return Padding(
      padding: const EdgeInsets.only(top: 2, bottom: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(displayCurrent == 0
                ? '0/$nextThresh → ×$nextMult'
                : '$displayCurrent/$nextThresh → ×$nextMult',
                style: const TextStyle(color: Color(0xFF7a8a62), fontSize: 8)),
          ),
          const SizedBox(width: 4),
          Expanded(
            flex: 3,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 4,
                backgroundColor: const Color(0xFF1a1f13),
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFd4af37)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Upgrade panel (Nose & Room tabs)
  Widget _buildUpgradePanel() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF131710),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
        border: Border(top: BorderSide(color: const Color(0xFF2d3d1e), width: 2)),
      ),
      child: Column(
        children: [
          // Tab bar
          Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: const Color(0xFF2d3d1e), width: 1),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorColor: const Color(0xFF7ec850),
              indicatorWeight: 3,
              labelColor: const Color(0xFF7ec850),
              unselectedLabelColor: const Color(0xFF7a8a62),
              labelStyle: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1),
              tabs: const [
                Tab(text: '👃 NOSE', height: 40),
                Tab(text: '🛋️ ROOM', height: 40),
              ],
            ),
          ),
          // Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildNoseTab(),
                _buildRoomTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Nose upgrades tab
  Widget _buildNoseTab() {
    final maxLevel = gs.availableNoseLevels;
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      itemCount: GameState.noseUpgrades.length,
      itemBuilder: (_, i) {
        final upg = GameState.noseUpgrades[i];
        final lvl = upg.level;
        final unlocked = lvl <= maxLevel;
        final owned = gs.noseLevels[lvl] ?? 0;
        final cost = gs.noseCost(lvl);
        final canBuy = unlocked && gs.glutCount >= cost;
        final effectiveBonus = gs.getEffectiveNoseBonus(lvl);
        final threshMult = gs.getThresholdMultiplier(lvl);
        final multLabel = threshMult > 1 ? ' [×$threshMult THRESH]' : '';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _upgradeCard(
              icon: upg.icon,
              name: upg.name,
              subtitle: '+${effectiveBonus.toInt()} glut/klik${multLabel}',
              owned: owned.toString(),
              cost: cost.toStringAsFixed(0),
              canBuy: canBuy,
              locked: !unlocked,
              onBuy: () {
                gs.buyNoseUpgrade(lvl);
                setState(() {});
              },
            ),
            if (unlocked) _buildThresholdRow(lvl, true),
          ],
        );
      },
    );
  }

  // Room upgrades tab
  Widget _buildRoomTab() {
    final maxLevel = gs.availableRoomLevels;
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      itemCount: GameState.roomUpgrades.length,
      itemBuilder: (_, i) {
        final upg = GameState.roomUpgrades[i];
        final lvl = upg.level;
        final unlocked = lvl <= maxLevel;
        final owned = gs.roomLevels[lvl] ?? 0;
        final cost = gs.roomCost(lvl);
        final canBuy = unlocked && gs.glutCount >= cost;
        final baseDrip = upg.dripPerSec;
        final threshMult = gs.getThresholdMultiplier(lvl);
        final effDrip = baseDrip * threshMult;
        final dripStr = effDrip == effDrip.toInt()
            ? effDrip.toInt().toString()
            : effDrip.toStringAsFixed(1);
        final threshLabel = threshMult > 1 ? ' [×$threshMult THRESH]' : '';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _upgradeCard(
              icon: upg.icon,
              name: upg.name,
              subtitle: '+$dripStr ml/s pasywnie$threshLabel',
              owned: owned.toString(),
              cost: cost.toStringAsFixed(0),
              canBuy: canBuy,
              locked: !unlocked,
              onBuy: () {
                gs.buyRoomUpgrade(lvl);
                setState(() {});
              },
            ),
            if (unlocked) _buildThresholdRow(lvl, false),
          ],
        );
      },
    );
  }

  // Shared upgrade card
  Widget _upgradeCard({
    required String icon,
    required String name,
    required String subtitle,
    required String owned,
    required String cost,
    required bool canBuy,
    required bool locked,
    required VoidCallback onBuy,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: locked ? const Color(0xFF0d0f0a) : const Color(0xFF161c10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: locked
              ? const Color(0xFF1a1f13)
              : canBuy
                  ? const Color(0xFF4a8a2a).withValues(alpha: 0.6)
                  : const Color(0xFF2d3d1e).withValues(alpha: 0.5),
        ),
      ),
      child: ListTile(
        leading: Text(icon, style: const TextStyle(fontSize: 28)),
        title: Text(name,
            style: TextStyle(
                color: locked
                    ? const Color(0xFF7a8a62).withValues(alpha: 0.5)
                    : const Color(0xFFcdd9b5),
                fontWeight: FontWeight.bold,
                fontSize: 13)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(subtitle,
                style: TextStyle(
                    color: locked
                        ? const Color(0xFF7a8a62).withValues(alpha: 0.5)
                        : const Color(0xFF7ec850),
                    fontSize: 11)),
            if (int.tryParse(owned) != null && int.parse(owned) > 0)
              Text('Posiadasz: $owned',
                  style: const TextStyle(
                      color: Color(0xFF7a8a62), fontSize: 10)),
          ],
        ),
        trailing: locked
            ? const Icon(Icons.lock, color: Color(0xFF1a1f13), size: 18)
            : SizedBox(
                width: 64,
                child: ElevatedButton(
                  onPressed: canBuy ? onBuy : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: canBuy
                        ? const Color(0xFF7ec850)
                        : const Color(0xFF2d3d1e),
                    foregroundColor: canBuy
                        ? const Color(0xFF0d0f0a)
                        : const Color(0xFF7a8a62),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 6),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    minimumSize: const Size(0, 34),
                  ),
                  child: Text(cost,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 11)),
                ),
              ),
      ),
    );
  }

  void _openDevCheats() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF161c10),
      isScrollControlled: true,
      builder: (_) => _DevCheatsPanel(gs: gs),
    );
  }
}

// ─── Particle class ──────────────────────────────────────────────────────────
class _Particle {
  final double x;
  final double y;
  final double targetY;
  final double delay;
  final int born = DateTime.now().millisecondsSinceEpoch;
  _Particle({required this.x, required this.y, required this.targetY, this.delay = 0.0});
}

// ─── Dotted Pattern Painter (background for character area) ──────────────────
class _DottedPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1a1f13)
      ..style = PaintingStyle.fill;
    for (double x = 0; x < size.width; x += 20) {
      for (double y = 0; y < size.height; y += 20) {
        canvas.drawCircle(Offset(x, y), 1, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DottedPatternPainter oldDelegate) => false;
}

// ─── Brick Wall Painter ──────────────────────────────────────────────────────
class _BrickWallPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final brickPaint = Paint()
      ..color = const Color(0xFF3d2b1f)
      ..style = PaintingStyle.fill;
    final mortarPaint = Paint()
      ..color = const Color(0xFF1a1410)
      ..style = PaintingStyle.fill;
    final brickHeight = 12.0;
    final brickWidth = 24.0;
    // Draw mortar (background)
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), mortarPaint);

    final rows = (size.height / brickHeight).ceil();
    for (int row = 0; row < rows; row++) {
      final offsetY = row * brickHeight;
      final isOddRow = row % 2 == 1;
      final cols = (size.width / brickWidth).ceil() + 1;
      for (int col = 0; col < cols; col++) {
        final offsetX = col * brickWidth + (isOddRow ? brickWidth / 2 : 0);
        final x = offsetX - (isOddRow ? brickWidth / 2 : 0);
        canvas.drawRect(
          Rect.fromLTWH(x + 1, offsetY + 1, brickWidth - 2, brickHeight - 2),
          brickPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BrickWallPainter oldDelegate) => false;
}

// ─── Mini Slime Wave Painter (for canal visualization) ───────────────────────
class _SlimeWavePainterMini extends CustomPainter {
  final double waveT;
  final double intensity;
  _SlimeWavePainterMini({required this.waveT, required this.intensity});

  @override
  void paint(Canvas canvas, Size size) {
    final waveHeight = 3.0 + (intensity * 3.0);
    final path = Path();
    path.moveTo(0, 0);
    for (double x = 0; x <= size.width; x += 4) {
      final frac = x / size.width;
      
          2.0 * (2.0 * frac * (1.0 - frac) - 0.5).abs() +
          waveHeight * 0.3 * (frac * 6.2832 + waveT * 2.0).abs() % 1.0;
    }
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    final paint = Paint()
      ..color = const Color(0xFFa8ff5a).withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SlimeWavePainterMini oldDelegate) => true;
}

// ─── Dev Cheats Panel ────────────────────────────────────────────────────────
class _DevCheatsPanel extends StatefulWidget {
  final GameState gs;
  const _DevCheatsPanel({required this.gs});

  @override
  State<_DevCheatsPanel> createState() => _DevCheatsPanelState();
}

class _DevCheatsPanelState extends State<_DevCheatsPanel> {
  final _glutController = TextEditingController();
  final _dnaController = TextEditingController();
  final _tankController = TextEditingController();

  @override
  void dispose() {
    _glutController.dispose();
    _dnaController.dispose();
    _tankController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('🔧 DEV TOOLS', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFcdd9b5))),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _glutController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Color(0xFFcdd9b5)),
                  decoration: const InputDecoration(
                    labelText: 'Dodaj gluty',
                    labelStyle: TextStyle(color: Color(0xFF7a8a62)),
                    enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF2d3d1e))),
                    focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF7ec850))),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  final amount = int.tryParse(_glutController.text) ?? 0;
                  widget.gs.glutCount += amount;
                  _glutController.clear();
                  widget.gs.saveGame();
                  if (context.mounted) setState(() {});
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7ec850)),
                child: const Text('Dodaj', style: TextStyle(color: Colors.black)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _dnaController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Color(0xFFcdd9b5)),
                  decoration: const InputDecoration(
                    labelText: 'Dodaj DNA',
                    labelStyle: TextStyle(color: Color(0xFF7a8a62)),
                    enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF2d3d1e))),
                    focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF7ec850))),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  final amount = int.tryParse(_dnaController.text) ?? 0;
                  widget.gs.unspentDna += amount;
                  _dnaController.clear();
                  widget.gs.saveGame();
                  if (context.mounted) setState(() {});
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7ec850)),
                child: const Text('Dodaj', style: TextStyle(color: Colors.black)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _tankController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Color(0xFFcdd9b5)),
                  decoration: const InputDecoration(
                    labelText: 'Ustaw tankMl (ml)',
                    labelStyle: TextStyle(color: Color(0xFF7a8a62)),
                    enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF2d3d1e))),
                    focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF7ec850))),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  final amount = double.tryParse(_tankController.text) ?? 0.0;
                  widget.gs.tankMl = amount;
                  _tankController.clear();
                  widget.gs.saveGame();
                  if (context.mounted) setState(() {});
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7ec850)),
                child: const Text('Ustaw', style: TextStyle(color: Colors.black)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Center(
            child: ElevatedButton.icon(
              onPressed: () {
                widget.gs.fullReset();
                widget.gs.saveGame();
                if (context.mounted) {
                  setState(() {});
                  Navigator.pop(context);
                }
              },
              icon: const Icon(Icons.refresh, color: Colors.white),
              label: const Text('RESET STAN', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFcc3333)),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
