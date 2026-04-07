import 'package:flutter/material.dart';
import 'game_state.dart';

class DNAShopScreen extends StatefulWidget {
  const DNAShopScreen({super.key});

  @override
  State<DNAShopScreen> createState() => _DNAShopScreenState();
}

class _DNAShopScreenState extends State<DNAShopScreen> {
  final GameState gs = GameState.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🧬 Sklep DNA'),
        backgroundColor: const Color(0xFF161c10),
      ),
      backgroundColor: const Color(0xFF0d0f0a),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: GameState.dnaUpgrades.length,
        itemBuilder: (context, index) {
          final def = GameState.dnaUpgrades[index];
          final currentLevel = gs.dnaUpgradeLevels[def.id] ?? 0;
          final isMaxed = currentLevel >= def.maxLevel;
          final canBuy = !isMaxed && gs.unspentDna >= def.baseCostDna;

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            color: const Color(0xFF161c10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: isMaxed ? const Color(0xFF2d3d1e) : const Color(0xFF3d5d2e),
                width: isMaxed ? 1 : 2,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(def.icon, style: const TextStyle(fontSize: 28)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              def.title,
                              style: const TextStyle(
                                color: Color(0xFFcdd9b5),
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              def.description,
                              style: const TextStyle(
                                color: Color(0xFF7a8a62),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Poziom: $currentLevel/${def.maxLevel}',
                        style: const TextStyle(color: Color(0xFF7a8a62), fontSize: 13),
                      ),
                      if (isMaxed)
                        const Text(
                          '✅ MAX',
                          style: TextStyle(color: Color(0xFFa8ff5a), fontSize: 14, fontWeight: FontWeight.bold),
                        )
                      else
                        ElevatedButton(
                          onPressed: canBuy
                              ? () {
                                  gs.buyDnaUpgrade(def.id);
                                  setState(() {});
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Zakupiono: ${def.title} (Lv.$currentLevel)'),
                                      duration: const Duration(seconds: 1),
                                    ),
                                  );
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: canBuy ? const Color(0xFF3d8d3d) : const Color(0xFF2a2a2a),
                          ),
                          child: Text(
                            canBuy ? 'Kup (🧬 ${def.baseCostDna})' : 'Brak (🧬 ${def.baseCostDna})',
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
