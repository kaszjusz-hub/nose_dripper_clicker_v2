import 'package:flutter/material.dart';
import '../../../../game_state.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../logic/game_controller.dart';
import '../widgets/dna_shop_tab.dart';

class ChannelScreen extends StatelessWidget {
  final GameController controller;

  const ChannelScreen({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final gs = controller.gameState;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: Column(
          children: [
            // Header kanału
            _buildChannelHeader(theme),
            const SizedBox(height: 10),
            // Zbiornik
            _buildTank(gs, theme),
            const SizedBox(height: 10),
            // Bakterie
            _buildBacteriaPanel(gs, theme),
            const SizedBox(height: 10),
            // DNA Shop (zakładki)
            Expanded(
              child: DNAShopTab(controller: controller),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChannelHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.card,
        border: Border(bottom: BorderSide(color: AppTheme.border)),
      ),
      child: Row(
        children: [
          const Icon(Icons.water_drop, color: AppTheme.slime, size: 20),
          const SizedBox(width: 8),
          Text(
            'Kanał Ściekowy',
            style: theme.textTheme.titleLarge?.copyWith(
              color: AppTheme.slime,
              fontFamily: 'Creepster',
            ),
          ),
          const Spacer(),
          Text(
            'v0.2',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppTheme.textDim,
              fontFamily: 'ShareTechMono',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTank(GameState gs, ThemeData theme) {
    final fillRatio = (gs.tankMl / gs.rebirthThreshold).clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration.copyWith(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.card,
            AppTheme.card.withValues(alpha: 0.8),
          ],
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Poziom Cieczy',
                style: theme.textTheme.bodyMedium,
              ),
              Text(
                '${gs.tankMl.toStringAsFixed(0)} / ${gs.rebirthThreshold.toStringAsFixed(0)} ml',
                style: TextStyle(
                  color: AppTheme.slime,
                  fontFamily: 'ShareTechMono',
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: fillRatio,
              backgroundColor: AppTheme.bg,
              valueColor: AlwaysStoppedAnimation<Color>(
                fillRatio > 0.8 ? AppTheme.accent : AppTheme.slime,
              ),
              minHeight: 16,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildTankStat('Bakterie', gs.bacteriaInTank.toString(), Icons.bug_report, AppTheme.virus),
              _buildTankStat('Aktywne', gs.activeVirusSlots.toString(), Icons.biotech, AppTheme.dna),
              _buildTankStat('Sloty', '${gs.activeVirusSlots}/${gs.maxVirusSlots}', Icons.storage, AppTheme.textDim),
            ],
          ),
          if (gs.rebirthAvailable)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: ElevatedButton.icon(
                onPressed: () => controller.doRebirth(),
                icon: const Icon(Icons.refresh, size: 18),
                label: Text(
                  'WYLECZENIE! +${gs.dnaToEarn} DNA',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.slime,
                  foregroundColor: AppTheme.bg,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTankStat(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: AppTheme.textDim),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
            fontFamily: 'ShareTechMono',
          ),
        ),
      ],
    );
  }

  Widget _buildBacteriaPanel(GameState gs, ThemeData theme) {
    if (!gs.bacteriaUnlocked) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(12),
        decoration: AppTheme.cardDecoration,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline, size: 16, color: AppTheme.textDim),
            const SizedBox(width: 8),
            Text(
              'Odblokuj po 3 000 000 ml',
              style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.textDim),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: AppTheme.cardDecoration,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.bug_report, size: 20, color: AppTheme.virus),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bakterie w Kanale',
                    style: theme.textTheme.bodyMedium,
                  ),
                  Text(
                    'Kliknij, by aktywować (mutacja)',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.textDim,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Text(
            '${gs.bacteriaInTank}/${GameState.maxBacteria}',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.virus,
              fontFamily: 'ShareTechMono',
            ),
          ),
        ],
      ),
    );
  }
}




