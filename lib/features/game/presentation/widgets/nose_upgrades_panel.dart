import 'package:flutter/material.dart';
import '../../../../game_state.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../logic/game_controller.dart';

class NoseUpgradesPanel extends StatelessWidget {
  final GameController controller;

  const NoseUpgradesPanel({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final gs = controller.gameState;
    final availableLevels = gs.availableNoseLevels;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ...GameState.noseUpgrades.asMap().entries.map((entry) {
          final idx = entry.key;
          final upgrade = entry.value;
          final level = upgrade.level;
          final currentCount = gs.noseLevels[level] ?? 0;
          final isUnlocked = level <= availableLevels;
          final cost = gs.noseCost(level);
          final canBuy = gs.glutCount >= cost;

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.card,
              border: Border.all(
                color: isUnlocked ? AppTheme.border : AppTheme.bg3,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.bg3,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    upgrade.icon,
                    style: const TextStyle(fontSize: 22),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${upgrade.name} ${upgrade.level}',
                        style: TextStyle(
                          color: isUnlocked ? AppTheme.text : AppTheme.textDim,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '+${upgrade.perClickBonus} glut / klik',
                        style: TextStyle(
                          fontSize: 12,
                          color: isUnlocked ? AppTheme.textDim : AppTheme.bg3,
                        ),
                      ),
                      if (isUnlocked)
                        Text(
                          'Koszt: $cost glutów | Kupione: $currentCount',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.textDim,
                            fontFamily: 'ShareTechMono',
                          ),
                        ),
                      if (level == 4 || level == 5 || level == 6)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'Odblokowuje się przy ${level - 3} zakupie DNA Nose',
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppTheme.dna,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                if (isUnlocked)
                  ElevatedButton(
                    onPressed: canBuy
                        ? () {
                            if (controller.buyNoseUpgrade(level)) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Kupiono ${upgrade.name} Lv.$level'),
                                  duration: const Duration(seconds: 1),
                                ),
                              );
                            }
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: canBuy ? AppTheme.slime : AppTheme.bg3,
                      foregroundColor: AppTheme.bg,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    ),
                    child: Text(
                      '$cost',
                      style: const TextStyle(fontSize: 11),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.bg3,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      '🔒',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }
}


