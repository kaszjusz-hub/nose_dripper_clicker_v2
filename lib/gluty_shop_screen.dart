
import 'package:flutter/material.dart';
import 'game_state.dart';

class GlutyShopScreen extends StatefulWidget {
  const GlutyShopScreen({super.key});

  @override
  State<GlutyShopScreen> createState() => _GlutyShopScreenState();
}

class _GlutyShopScreenState extends State<GlutyShopScreen> {
  final gs = GameState.instance;
  bool showNoseTab = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0d0f0a),
      appBar: AppBar(
        backgroundColor: const Color(0xFF7ec850),
        title: const Text('Sklep Glotów'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Tab navigation
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => setState(() => showNoseTab = true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: showNoseTab ? const Color(0xFF7ec850) : Colors.black26,
                    foregroundColor: showNoseTab ? Colors.white : Colors.grey,
                    shape: const RoundedRectangleBorder(),
                    padding: const EdgeInsets.all(16),
                  ),
                  child: const Text('👃 Nos'),
                ),
              ),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => setState(() => showNoseTab = false),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: !showNoseTab ? const Color(0xFF7ec850) : Colors.black26,
                    foregroundColor: !showNoseTab ? Colors.white : Colors.grey,
                    shape: const RoundedRectangleBorder(),
                    padding: const EdgeInsets.all(16),
                  ),
                  child: const Text('🛋️ Pokój'),
                ),
              ),
            ],
          ),
          Expanded(
            child: showNoseTab ? _buildNoseUpgrades() : _buildRoomUpgrades(),
          ),
        ],
      ),
    );
  }

  Widget _buildNoseUpgrades() {
    final availableLevels = gs.availableNoseLevels;
    final upgrades = GameState.noseUpgrades
        .where((u) => u.level <= availableLevels)
        .toList();

    return ListView.builder(
      itemCount: upgrades.length,
      itemBuilder: (_, i) {
        final upgrade = upgrades[i];
        final count = gs.noseLevels[upgrade.level] ?? 0;
        final cost = gs.noseCost(upgrade.level);
        final canBuy = gs.glutCount >= cost;

        return Card(
          color: const Color(0xFF161c10),
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: ListTile(
            leading: Text(upgrade.icon, style: const TextStyle(fontSize: 28)),
            title: Text(upgrade.name, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF7ec850))),
            subtitle: Text(
              '+${upgrade.perClickBonus.toInt()} glut/klik\nKoszt: $cost | Poziom: $count\nGlutów: ${gs.glutCount}',
              style: const TextStyle(color: Color(0xFF7a8a62)),
            ),
            trailing: ElevatedButton(
              onPressed: canBuy
                  ? () {
                      gs.buyNoseUpgrade(upgrade.level);
                      setState(() {});
                    }
                  : null,
              child: Text('$cost'),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRoomUpgrades() {
    final availableLevels = gs.availableRoomLevels;
    final upgrades = GameState.roomUpgrades
        .where((u) => u.level <= availableLevels)
        .toList();

    return ListView.builder(
      itemCount: upgrades.length,
      itemBuilder: (_, i) {
        final upgrade = upgrades[i];
        final count = gs.roomLevels[upgrade.level] ?? 0;
        final cost = gs.roomCost(upgrade.level);
        final canBuy = gs.glutCount >= cost;

        return Card(
          color: const Color(0xFF161c10),
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: ListTile(
            leading: Text(upgrade.icon, style: const TextStyle(fontSize: 28)),
            title: Text(upgrade.name, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF7ec850))),
            subtitle: Text(
              '+${upgrade.dripPerSec.toStringAsFixed(1)} glut/s\nKoszt: $cost | Poziom: $count\nGlutów: ${gs.glutCount}',
              style: const TextStyle(color: Color(0xFF7a8a62)),
            ),
            trailing: ElevatedButton(
              onPressed: canBuy
                  ? () {
                      gs.buyRoomUpgrade(upgrade.level);
                      setState(() {});
                    }
                  : null,
              child: Text('$cost'),
            ),
          ),
        );
      },
    );
  }
}