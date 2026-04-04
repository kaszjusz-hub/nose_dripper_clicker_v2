
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'game_state.dart';

class KanaalScreen extends StatefulWidget {
  const KanaalScreen({super.key});

  @override
  State<KanaalScreen> createState() => _KanaalScreenState();
}

class _KanaalScreenState extends State<KanaalScreen> with TickerProviderStateMixin {
  final GameState gs = GameState.instance;
  late final AnimationController _waveController;
  late final AnimationController _bubbleController;
  VoidCallback? _tickListener;

  // Floating reward text after clicking bacteria
  final List<_FloatingText> _floatingTexts = [];
  int _floatingId = 0;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
    _bubbleController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat();
    // Use shared game loop instead of local timer
    _tickListener = () {
      // Clean up old floating texts
      final now = DateTime.now().millisecondsSinceEpoch;
      _floatingTexts.removeWhere((ft) => (now - ft.createdAt) > 1500);
      if (mounted) {
        setState(() {});
      }
    };
    gs.addTickListener(_tickListener!);
  }

  @override
  void dispose() {
    gs.removeTickListener(_tickListener!);
    _waveController.dispose();
    _bubbleController.dispose();
    super.dispose();
  }

  Future<void> _onBacteriaTap(Offset position) async {
    final reward = (gs.passiveDrip * 300).round();
    gs.clickBacteria();
    setState(() {
      _floatingTexts.add(_FloatingText(
        id: _floatingId++,
        text: '+${reward > 0 ? reward : '0'}',
        x: position.dx,
        y: position.dy,
        createdAt: DateTime.now().millisecondsSinceEpoch,
      ));
    });
    gs.saveGame();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0d0f0a),
      body: AnimatedBuilder(
        animation: Listenable.merge([_waveController, _bubbleController]),
        builder: (ctx, _) {
          return Stack(
            children: [
              // Sewer background: walls, ladder, lamp
              Positioned.fill(
                child: CustomPaint(
                  painter: _SewerBackgroundPainter(
                    flickerT: _waveController.value,
                    slimeFillRatio: (gs.tankMl / 3000000.0).clamp(0.0, 1.0),
                  ),
                  size: Size.infinite,
                ),
              ),
              // Slime layer at the bottom
              _buildSlimeLayer(),
              _buildHUD(),
              ..._buildBacteria(),
              ..._buildFloatingTexts(),
              if (gs.rebirthAvailable) _buildRebirthButton(),  
              if (gs.dnaShopUnlocked) _buildDnaShopButton(),
              if (gs.inventory.isNotEmpty) _buildInventoryButton(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSlimeLayer() {
    final fillRatio = (gs.tankMl / 3000000.0).clamp(0.0, 1.0);
    if (fillRatio < 0.01) return const SizedBox.shrink();

    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.5 * fillRatio,
        child: AnimatedBuilder(
          animation: Listenable.merge([_waveController, _bubbleController]),
          builder: (ctx, _) {
            return CustomPaint(
              painter: _SlimeWavePainter(
                waveT: _waveController.value,
                bubbleT: _bubbleController.value,
                bacteriaCount: gs.bacteriaInTank,
                intensity: fillRatio,
              ),
              size: Size.infinite,
            );
          },
        ),
      ),
    );
  }

  Widget _buildHUD() {
    final multiplier = gs.rebirthProgress >= 1.0
        ? gs.rebirthProgress.floor()
        : 0;
    final progress = gs.rebirthProgress.clamp(0.0, 1.0);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${gs.tankMl.toStringAsFixed(0)} ml',
                  style: const TextStyle(
                    color: Color(0xFFcdd9b5),
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      'DNA: ${gs.unspentDna}',
                      style: const TextStyle(color: Color(0xFF5ab4ff), fontSize: 14),
                    ),
                    if (kDebugMode)
                      IconButton(
                        icon: const Icon(Icons.build, size: 20),
                        color: const Color(0xFF7a8a62),
                        onPressed: _openDevCheats,
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 10,
                backgroundColor: Colors.black54,
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF7ec850)),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              multiplier > 0
                  ? '🧬 ×${multiplier} DNA gotowe (${gs.dnaToEarn} DNA)'
                  : '${(progress * 100).toStringAsFixed(1)}% do pierwszego Rebirthu',
              style: const TextStyle(color: Color(0xFF7a8a62), fontSize: 12),
            ),
            // Income/sec in top-right
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '🧪 +${gs.passiveDrip.toStringAsFixed(1)} ml/s',
                style: const TextStyle(color: Color(0xFF7a8a62), fontSize: 12),
              ),
            ),
            if (gs.comboPoints > 5) ...[
              const SizedBox(height: 8),
              _buildComboBar(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildComboBar() {
    final comboCap = 200.0;
    final ratio = (gs.comboPoints.clamp(0.0, comboCap) / comboCap).clamp(0.0, 1.0);
    final displayPoints = gs.comboPoints.clamp(0.0, comboCap);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('COMBO ${displayPoints.toInt()}/200',
              style: const TextStyle(fontSize: 10, color: Color(0xFF7a8a62), letterSpacing: 2)),
            Text(
              'x${gs.comboMultiplier.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 12, color: Color(0xFFa8ff5a), fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 3),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 4,
            backgroundColor: Colors.black54,
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFa8ff5a)),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildFloatingTexts() {
    final now = DateTime.now().millisecondsSinceEpoch;
    // Remove old texts
    _floatingTexts.removeWhere((ft) => (now - ft.createdAt) > 1500);

    return _floatingTexts.map((ft) {
      final elapsed = (now - ft.createdAt) / 1500.0;
      final dx = ft.x;
      final dy = ft.y - elapsed * 100; // float up 100px
      final opacity = (1.0 - elapsed).clamp(0.0, 1.0);

      return Positioned(
        left: dx - 30,
        top: dy - 15,
        child: IgnorePointer(
          child: Opacity(
            opacity: opacity,
            child: Text(
              ft.text,
              style: const TextStyle(
                color: Color(0xFFa8ff5a),
                fontWeight: FontWeight.bold,
                fontSize: 20,
                shadows: [Shadow(color: Colors.black, blurRadius: 6)],
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  List<Widget> _buildBacteria() {
    if (!gs.bacteriaUnlocked || gs.bacteriaInTank <= 0) return [];
    final size = MediaQuery.of(context).size;
    final widgets = <Widget>[];
    for (int i = 0; i < gs.bacteriaInTank; i++) {
      final dx = size.width * 0.15 + (size.width * 0.7) * (i / (GameState.maxBacteria - 1));
      final dy = size.height * 0.55 - (i % 3) * 55.0;
      widgets.add(Positioned(
        left: dx - 24,
        top: dy - 24,
        child: GestureDetector(
          onTap: () => _onBacteriaTap(Offset(dx, dy)),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFcc3333).withOpacity(0.7),
              border: Border.all(color: const Color(0xFFff6644), width: 2),
            ),
            child: const Center(
              child: Text('🦠', style: TextStyle(fontSize: 24)),
            ),
          ),
        ),
      ));
    }
    return widgets;
  }

  Positioned _buildRebirthButton() {
    return Positioned(
      bottom: 30,
      left: 30,
      right: 30,
      child: ElevatedButton(
        onPressed: _confirmRebirth,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF5ab4ff),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: Text('🧬 REBIRTH - Wyleczenie (${gs.dnaToEarn} DNA)',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }

  void _confirmRebirth() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF161c10),
        title: const Text('🧬 Rebirth'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('+${gs.dnaToEarn} DNA', style: const TextStyle(color: Color(0xFF5ab4ff))),
            const SizedBox(height: 8),
            const Text('Resetuje: gluty, ulepszenia nosa i pokoju.\nDNA i ulepszenia DNA zostają.'),
            const SizedBox(height: 8),
            Text('Próg: ${gs.rebirthThreshold.toStringAsFixed(0)} ml (stały)',
              style: const TextStyle(fontSize: 12)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Anuluj')),
          ElevatedButton(
            onPressed: () {
              gs.doRebirth();
              Navigator.pop(ctx);
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Rebirth! +DNA 💚')),
              );
            },
            child: const Text('Potwierdz'),
          ),
        ],
      ),
    );
  }

  Positioned _buildDnaShopButton() {
    return Positioned(
      bottom: 30,
      right: 30,
      child: ElevatedButton.icon(
        onPressed: _openDnaShop,
        icon: const Icon(Icons.science),
        label: Text('DNA: ${gs.unspentDna}'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF7ec850),
          foregroundColor: Colors.white,
        ),
      ),
    );
  }

  void _openDnaShop() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF161c10),
      isScrollControlled: true,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('🧬 SKLEP DNA',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFcdd9b5))),
                Text('Dostepne: ${gs.unspentDna}',
                  style: const TextStyle(color: Color(0xFF5ab4ff), fontSize: 14)),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: GameState.dnaUpgrades.length,
                itemBuilder: (_, i) {
                  final def = GameState.dnaUpgrades[i];
                  final level = gs.dnaUpgradeLevels[def.id] ?? 0;
                  final maxed = level >= def.maxLevel;
                  final canBuy = gs.unspentDna >= def.baseCostDna && !maxed;
                  return Card(
                    color: const Color(0xFF1a1f13),
                    child: ListTile(
                      leading: Text(def.icon, style: const TextStyle(fontSize: 28)),
                      title: Text(def.title,
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFcdd9b5))),
                      subtitle: Text('${def.description}\nPoziom: $level/${def.maxLevel}',
                        style: const TextStyle(color: Color(0xFF7a8a62))),
                      trailing: maxed
                          ? const Text('MAX',
                              style: TextStyle(color: Colors.yellow, fontWeight: FontWeight.bold))
                          : ElevatedButton(
                              onPressed: canBuy
                                  ? () { gs.buyDnaUpgrade(def.id); setState(() {}); }
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: canBuy ? const Color(0xFF7ec850) : Colors.grey),
                              child: Text('${def.baseCostDna} DNA'),
                            ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Positioned _buildInventoryButton() {
    return Positioned(
      bottom: 30,
      left: 30,
      child: ElevatedButton.icon(
        onPressed: _openInventory,
        icon: const Icon(Icons.backpack),
        label: const Text('Ekwipunek'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFe0a030),
          foregroundColor: Colors.black,
        ),
      ),
    );
  }

  void _openInventory() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF161c10),
      builder: (_) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎒 EKWIPUNEK',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFcdd9b5))),
            const SizedBox(height: 6),
            Text('Sloty: ${gs.activeVirusSlots}/${gs.maxVirusSlots}',
              style: const TextStyle(color: Color(0xFF7a8a62))),
            if (gs.inventory.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(child: Text('Pusto... Klikaj bakterie, zeby znalezc wirusy! 🦠')),
              )
            else ...[
              const SizedBox(height: 8),
              ...gs.inventory.asMap().entries.map((entry) {
                final idx = entry.key;
                final virus = entry.value;
                final equipped = virus['equipped'] == true;
                return ListTile(
                  leading: Text(virus['icon'] ?? '☣️', style: const TextStyle(fontSize: 28)),
                  title: Text(virus['name'] ?? 'Wirus',
                    style: const TextStyle(color: Color(0xFFcdd9b5))),
                  subtitle: Text('Bonus: +${((virus['bonus'] ?? 0) * 100).toInt()}%'),
                  trailing: Icon(
                    equipped ? Icons.check_circle : Icons.add_circle,
                    color: equipped ? const Color(0xFF7ec850) : const Color(0xFF7a8a62)),
                  onTap: () { gs.toggleEquipVirus(idx); setState(() {}); },
                );
              }),
            ],
          ],
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
                  setState(() {});
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
                  setState(() {});
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
                  setState(() {});
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
                setState(() {});
                Navigator.pop(context);
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

class _SewerBackgroundPainter extends CustomPainter {
  final double flickerT;
  final double slimeFillRatio;
  _SewerBackgroundPainter({required this.flickerT, required this.slimeFillRatio});

  @override
  void paint(Canvas canvas, Size size) {
    // Dark concrete/mortar background
    final bgPaint = Paint()
      ..color = const Color(0xFF2a2520)
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Brick pattern
    final brickPaint = Paint()
      ..color = const Color(0xFF3d2b1f)
      ..style = PaintingStyle.fill;
    final mortarPaint = Paint()
      ..color = const Color(0xFF1a1410)
      ..style = PaintingStyle.fill;
    final brickH = 14.0;
    final brickW = 28.0;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), mortarPaint);
    final rows = (size.height / brickH).ceil();
    for (int row = 0; row < rows; row++) {
      final cols = (size.width / brickW).ceil() + 1;
      for (int col = 0; col < cols; col++) {
        bool isOddRow = row % 2 == 1;
        double ox = col * brickW + (isOddRow ? brickW / 2 : 0);
        if (ox < size.width) {
          canvas.drawRect(
            Rect.fromLTWH(ox + 1, row * brickH + 1, brickW - 2, brickH - 2),
            brickPaint,
          );
        }
      }
    }

    // Dirt/patina stains
    final stainPaint = Paint()
      ..color = const Color(0xFF1a1410).withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;
    canvas.drawOval(Rect.fromLTWH(size.width * 0.1, size.height * 0.1, 40, 80), stainPaint);
    canvas.drawOval(Rect.fromLTWH(size.width * 0.7, size.height * 0.2, 50, 60), stainPaint);
    canvas.drawRect(Rect.fromLTWH(size.width * 0.4, size.height * 0.15, 30, 100), stainPaint);

    // Metal ladder (left side)
    final railPaint = Paint()
      ..color = const Color(0xFF555555)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;
    final x1 = size.width * 0.08;
    final x2 = size.width * 0.16;
    canvas.drawLine(Offset(x1, 0), Offset(x1, size.height), railPaint);
    canvas.drawLine(Offset(x2, 0), Offset(x2, size.height), railPaint);
    // Rungs
    final rungPaint = Paint()
      ..color = const Color(0xFF555555)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    for (double y = 40; y < size.height; y += 40) {
      canvas.drawLine(Offset(x1, y), Offset(x2, y), rungPaint);
    }

    // Flickering lamp (right top)
    final lampX = size.width * 0.85;
    final lampY = size.height * 0.08;
    final flicker = 0.7 + 0.3 * sin(flickerT * pi * 2.0 * 3.0);
    // Lamp housing
    canvas.drawCircle(Offset(lampX, lampY), 8, Paint()..color = const Color(0xFF333333)..style = PaintingStyle.fill);
    // Wire
    canvas.drawLine(Offset(lampX, 0), Offset(lampX, lampY - 8), Paint()..color = const Color(0xFF333333)..strokeWidth = 2);
    // Light glow
    final glowPaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 0.5,
        colors: [
          Color.fromARGB((flicker * 100).toInt(), 255, 200, 80),
          Color.fromARGB((flicker * 40).toInt(), 255, 200, 80),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: Offset(lampX, lampY), radius: size.width * 0.4));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), glowPaint);
    // Lamp glow circle
    final lampGlow = Paint()
      ..color = Color.fromARGB((flicker * 200).toInt(), 255, 220, 80)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(Offset(lampX, lampY), 12, lampGlow);
  }

  @override
  bool shouldRepaint(covariant _SewerBackgroundPainter oldDelegate) {
    return oldDelegate.flickerT != flickerT;
  }
}

class _FloatingText {
  final int id;
  final String text;
  final double x;
  final double y;
  final int createdAt;
  _FloatingText({
    required this.id,
    required this.text,
    required this.x,
    required this.y,
    required this.createdAt,
  });
}

class _SlimeWavePainter extends CustomPainter {
  final double waveT;
  final double bubbleT;
  final int bacteriaCount;
  final double intensity; // scales wave activity when above threshold

  _SlimeWavePainter({
    required this.waveT,
    required this.bubbleT,
    required this.bacteriaCount,
    this.intensity = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final waveHeight = 8.0 + (intensity.clamp(1.0, 5.0) * 3.0);
    final numWaves = 3 + (intensity.clamp(1.0, 5.0)).toInt();

    // Background gradient - full canal
    final gradPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: const [
          Color(0xFF7ec850),
          Color(0xFF4a8a2a),
          Color(0xFF2d3d1e),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), gradPaint);

    // Animated wave overlay
    for (int wave = 0; wave < numWaves; wave++) {
      final phaseOffset = wave * 0.7;
      final alpha = 0.12 - (wave * 0.03);
      final wavePaint = Paint()
        ..color = const Color(0xFFcdd9b5).withOpacity(alpha)
        ..style = PaintingStyle.fill;

      final path = Path();
      path.moveTo(0, 0);
      for (double x = 0; x <= size.width; x += 4) {
        final frac = x / size.width;
        final y = waveHeight * sin(frac * pi * (2.0 + wave * 0.5) + waveT * (2.0 + wave * 0.3) + phaseOffset);
        path.lineTo(x, y);
      }
      path.lineTo(size.width, size.height);
      path.lineTo(0, size.height);
      path.close();
      canvas.drawPath(path, wavePaint);
    }

    // Surface highlight
    final highlightPaint = Paint()
      ..color = const Color(0xFFa8ff5a).withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final highlightPath = Path();
    highlightPath.moveTo(0, 0);
    for (double x = 0; x <= size.width; x += 4) {
      final frac = x / size.width;
      final y = waveHeight * sin(frac * pi * 2.0 + waveT * 2.0);
      highlightPath.lineTo(x, y);
    }
    canvas.drawPath(highlightPath, highlightPaint);

    // Bubbles
    final bubbleCount = bacteriaCount.clamp(0, 5);
    for (int i = 0; i < bubbleCount; i++) {
      final r = 6 + sin(waveT * 1.5 + i.toDouble()) * 4;
      final bx = size.width * (0.15 + (0.7 * (i / 4)));
      final by = size.height * 0.6 + cos(bubbleT * (0.5 + i * 0.15) + i.toDouble()) * (30 + intensity * 10);
      canvas.drawCircle(Offset(bx, by), r.abs(),
        Paint()..color = Colors.white.withOpacity(0.35)..style = PaintingStyle.fill);
      canvas.drawCircle(Offset(bx, by), r.abs(),
        Paint()..color = Colors.white.withOpacity(0.2)..style = PaintingStyle.stroke..strokeWidth = 1.5);
    }
  }

  @override
  bool shouldRepaint(covariant _SlimeWavePainter oldDelegate) {
    return oldDelegate.waveT != waveT ||
        oldDelegate.bubbleT != bubbleT ||
        oldDelegate.bacteriaCount != bacteriaCount ||
        oldDelegate.intensity != intensity;
  }
}
