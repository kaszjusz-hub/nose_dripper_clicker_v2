import 'dart:async';
import 'package:flutter/material.dart';
import 'game_state.dart';

class NoseScreen extends StatefulWidget {
  const NoseScreen({super.key});

  @override
  State<NoseScreen> createState() => _NoseScreenState();
}

class _NoseScreenState extends State<NoseScreen>
    with SingleTickerProviderStateMixin {
  final GameState gs = GameState.instance;
  late final TabController _tabController;
  VoidCallback? _tickListener;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tickListener = () {
      if (mounted) setState(() {});
    };
    gs.addTickListener(_tickListener!);
    gs.startGameLoop();
  }

  @override
  void dispose() {
    if (_tickListener != null) gs.removeTickListener(_tickListener!);
    _tabController.dispose();
    super.dispose();
  }

  void _onTap() {
    gs.clickNose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0d0f0a),
      body: SafeArea(
        child: Column(
          children: [
            _buildHUD(),
            const SizedBox(height: 12),
            Expanded(
              flex: 3,
              child: Center(child: _tapArea()),
            ),
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
              _resourceChip('🟢', '${gs.glutCount}'),
              _resourceChip('🧬', '${gs.unspentDna} DNA'),
              _resourceChip('🧻', '${gs.tissues} chust.'),
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

  // Tap area
  Widget _tapArea() {
    return GestureDetector(
      onTap: _onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 180,
        height: 180,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              const Color(0xFF7ec850),
              const Color(0xFF4caf50),
              const Color(0xFF2d3d1e),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF7ec850).withOpacity(0.4),
              blurRadius: 40,
              spreadRadius: 6,
            ),
          ],
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('🤧', style: TextStyle(fontSize: 56)),
              SizedBox(height: 6),
              Text('KLIKNIJ!',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      letterSpacing: 1)),
            ],
          ),
        ),
      ),
    );
  }

  // Upgrade panel (Nose & Room tabs)
  Widget _buildUpgradePanel() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF131710),
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
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

        return _upgradeCard(
          icon: upg.icon,
          name: upg.name,
          subtitle: '+${upg.perClickBonus.toInt()} glut/klik',
          owned: owned.toString(),
          cost: cost.toStringAsFixed(0),
          canBuy: canBuy,
          locked: !unlocked,
          onBuy: () {
            gs.buyNoseUpgrade(lvl);
            setState(() {});
          },
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
        final dripStr = upg.dripPerSec == upg.dripPerSec.toInt()
            ? '${upg.dripPerSec.toInt()}'
            : '${upg.dripPerSec.toStringAsFixed(1)}';

        return _upgradeCard(
          icon: upg.icon,
          name: upg.name,
          subtitle: '+$dripStr ml/s pasywnie',
          owned: owned.toString(),
          cost: cost.toStringAsFixed(0),
          canBuy: canBuy,
          locked: !unlocked,
          onBuy: () {
            gs.buyRoomUpgrade(lvl);
            setState(() {});
          },
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
                  ? const Color(0xFF4a8a2a).withOpacity(0.6)
                  : const Color(0xFF2d3d1e).withOpacity(0.5),
        ),
      ),
      child: ListTile(
        leading: Text(icon, style: const TextStyle(fontSize: 28)),
        title: Text(name,
            style: TextStyle(
                color: locked
                    ? const Color(0xFF7a8a62).withOpacity(0.5)
                    : const Color(0xFFcdd9b5),
                fontWeight: FontWeight.bold,
                fontSize: 13)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(subtitle,
                style: TextStyle(
                    color: locked
                        ? const Color(0xFF7a8a62).withOpacity(0.5)
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
}