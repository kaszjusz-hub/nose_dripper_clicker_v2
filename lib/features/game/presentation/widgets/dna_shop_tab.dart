import 'package:flutter/material.dart';
import '../../../../game_state.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../logic/game_controller.dart';

class DNAShopTab extends StatelessWidget {
  final GameController controller;

  const DNAShopTab({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final gs = controller.gameState;

    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          Container(
            color: AppTheme.card,
            child: TabBar(
              tabs: const [
                Tab(text: 'Nose', icon: Icon(Icons.fingerprint, size: 16)),
                Tab(text: 'Room', icon: Icon(Icons.home, size: 16)),
                Tab(text: 'DNA', icon: Icon(Icons.card_giftcard, size: 16)),
              ],
              labelColor: AppTheme.slime,
              unselectedLabelColor: AppTheme.textDim,
              indicatorColor: AppTheme.slime,
              indicatorSize: TabBarIndicatorSize.tab,
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildNoseUpgrades(gs, context),
                _buildRoomUpgrades(gs, context),
                _buildDnaUpgrades(gs, context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoseUpgrades(GameState gs, BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Odblokowuj wyższe poziomy ulepszeń Nosa',
          style: TextStyle(color: AppTheme.textDim, fontSize: 12),
        ),
        const SizedBox(height: 12),
        ...GameState.dnaUpgrades.where((d) => d.id == 'nose_slots').map((upgrade) {
          final currentLevel = gs.dnaUpgradeLevels[upgrade.id] ?? 0;
          final isMaxed = currentLevel >= upgrade.maxLevel;
          final canBuy = !isMaxed && gs.unspentDna >= upgrade.baseCostDna;

          return _buildDNACard(upgrade, currentLevel, isMaxed, canBuy, context);
        }).toList(),
      ],
    );
  }

  Widget _buildRoomUpgrades(GameState gs, BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Odblokowuj wyższe poziomy ulepszeń Pokoju',
          style: TextStyle(color: AppTheme.textDim, fontSize: 12),
        ),
        const SizedBox(height: 12),
        ...GameState.dnaUpgrades.where((d) => d.id == 'room_expansion').map((upgrade) {
          final currentLevel = gs.dnaUpgradeLevels[upgrade.id] ?? 0;
          final isMaxed = currentLevel >= upgrade.maxLevel;
          final canBuy = !isMaxed && gs.unspentDna >= upgrade.baseCostDna;

          return _buildDNACard(upgrade, currentLevel, isMaxed, canBuy, context);
        }).toList(),
      ],
    );
  }

  Widget _buildDnaUpgrades(GameState gs, BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Wydaj niewydane DNA na trwałe ulepszenia',
          style: TextStyle(color: AppTheme.textDim, fontSize: 12),
        ),
        const SizedBox(height: 12),
        ...GameState.dnaUpgrades.where((d) => d.id != 'nose_slots' && d.id != 'room_expansion').map((upgrade) {
          final currentLevel = gs.dnaUpgradeLevels[upgrade.id] ?? 0;
          final isMaxed = currentLevel >= upgrade.maxLevel;
          final canBuy = !isMaxed && gs.unspentDna >= upgrade.baseCostDna;

          return _buildDNACard(upgrade, currentLevel, isMaxed, canBuy, context);
        }).toList(),
      ],
    );
  }

  Widget _buildDNACard(DnaUpgradeDef upgrade, int currentLevel, bool isMaxed,
      bool canBuy, BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.card,
        border: Border.all(
          color: isMaxed ? AppTheme.bg3 : (canBuy ? AppTheme.dna : AppTheme.border),
          width: isMaxed ? 1 : 2,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                upgrade.icon,
                style: const TextStyle(fontSize: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      upgrade.title,
                      style: const TextStyle(
                        color: AppTheme.text,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      upgrade.description,
                      style: const TextStyle(
                        color: AppTheme.textDim,
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
                'Poziom: $currentLevel/${upgrade.maxLevel}',
                style: const TextStyle(color: AppTheme.textDim, fontSize: 13),
              ),
              if (isMaxed)
                const Text(
                  '✅ MAX',
                  style: TextStyle(color: AppTheme.slime, fontWeight: FontWeight.bold),
                )
              else
                ElevatedButton.icon(
                  onPressed: canBuy
                      ? () {
                          if (controller.buyDnaUpgrade(upgrade.id)) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Kupiono: ${upgrade.title}'),
                                backgroundColor: AppTheme.dna,
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          }
                        }
                      : null,
                  icon: const Icon(Icons.add, size: 16),
                  label: Text('${upgrade.baseCostDna} 🧬'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: canBuy ? AppTheme.dna.withValues(alpha: 0.8) : AppTheme.bg3,
                    foregroundColor: canBuy ? AppTheme.dna : AppTheme.textDim,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}



