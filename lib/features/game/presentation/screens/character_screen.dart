import 'package:flutter/material.dart';
import '../../../../game_state.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../logic/game_controller.dart';
import '../widgets/nose_upgrades_panel.dart';
import '../widgets/room_upgrades_panel.dart';
import '../widgets/combo_bar.dart';

class CharacterScreen extends StatefulWidget {
  final GameController controller;

  const CharacterScreen({super.key, required this.controller});

  @override
  State<CharacterScreen> createState() => _CharacterScreenState();
}

class _CharacterScreenState extends State<CharacterScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnim;
  int _lastGlutCount = 0;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 150));
    _scaleAnim = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.15), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.15, end: 1.0), weight: 50),
    ]).animate(_animController);

    widget.controller.addListener(_onGameUpdate);
  }

  void _onGameUpdate() {
    if (widget.controller.gameState.glutCount > _lastGlutCount) {
      _lastGlutCount = widget.controller.gameState.glutCount;
      _animController.forward(from: 0.0);
    }
    if (mounted) setState(() {});
  }

  void _onTapNose(TapDownDetails details) {
    widget.controller.clickNose();
    _showClickEffect(details.globalPosition);
  }

  void _showClickEffect(Offset position) {
    // TODO: Efekt wizualny kliknięcia (krople, animacja)
  }

  @override
  Widget build(BuildContext context) {
    final gs = widget.controller.gameState;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: Column(
          children: [
            // Pasek górny z DNA i Rebirth
            _buildTopBar(gs, theme),
            const SizedBox(height: 10),
            // Combo bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ComboBar(
                comboPoints: gs.comboPoints,
                multiplier: gs.comboMultiplier,
                allergyMultiplier: gs.allergyMultiplier,
                allergyActive: gs.allergyActive,
                allergyRemainingSeconds: gs.allergyRemainingSeconds,
              ),
            ),
            const SizedBox(height: 10),
            // Główny obszar: Ogr i dół
            Expanded(
              child: Stack(
                children: [
                  Center(
                    child: GestureDetector(
                      onTapDown: _onTapNose,
                      child: ScaleTransition(
                        scale: _scaleAnim,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              '👹',
                              style: TextStyle(fontSize: 120),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Ogr',
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: AppTheme.slime,
                                fontFamily: 'Creepster',
                                fontSize: 28,
                              ),
                            ),
                            Text(
                              'Katarzyński',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: AppTheme.textDim,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Animacja pyłka (pollen), jeśli aktywny
                  if (gs.pollenVisible) _buildPollenOverlay(gs),
                ],
              ),
            ),
            // Statystyki zbiornika
            _buildTankStats(gs, theme),
            const SizedBox(height: 16),
          ],
        ),
      ),
      // Dolny panel - panele ulepszeń
      bottomNavigationBar: BottomSheet(
        enableDrag: true,
        showDragHandle: true,
        backgroundColor: AppTheme.bg,
        onClosing: () {},
        builder: (context) => SizedBox(
          height: 350,
          child: DefaultTabController(
            length: 2,
            child: Column(
              children: [
                const TabBar(
                  tabs: [
                    Tab(icon: Icon(Icons.fingerprint), text: 'Nose'),
                    Tab(icon: Icon(Icons.home), text: 'Room'),
                  ],
                  indicatorColor: AppTheme.slime,
                  labelColor: AppTheme.slime,
                  unselectedLabelColor: AppTheme.textDim,
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      NoseUpgradesPanel(controller: widget.controller),
                      RoomUpgradesPanel(controller: widget.controller),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(GameState gs, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Punkty DNA
          _buildStatChip(
            icon: Icons.card_giftcard,
            label: 'DNA',
            value: gs.dnaPoints.toString(),
            color: AppTheme.dna,
          ),
          // Niewydane DNA
          _buildStatChip(
            icon: Icons.star,
            label: 'Niewydane',
            value: gs.unspentDna.toString(),
            color: AppTheme.premium,
            multiplier: '×${(1.0 + gs.unspentDna * 0.1).toStringAsFixed(1)}',
          ),
          // Rebirth
          if (gs.rebirthAvailable)
            ElevatedButton.icon(
              onPressed: () {
                widget.controller.doRebirth();
                setState(() {});
              },
              icon: const Icon(Icons.refresh, size: 16),
              label: Text('Rebirth\n+${gs.dnaToEarn} DNA'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.slime,
                foregroundColor: AppTheme.bg,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                textStyle: const TextStyle(fontSize: 10),
              ),
            )
          else
            _buildStatChip(
              icon: Icons.water_drop,
              label: 'Rebirth',
              value: '${(gs.rebirthProgress * 100).toStringAsFixed(0)}%',
              color: AppTheme.slimeDark,
            ),
        ],
      ),
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    String? multiplier,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.card,
        border: Border.all(color: AppTheme.border),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 9, color: AppTheme.textDim),
          ),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          if (multiplier != null)
            Text(
              multiplier,
              style: const TextStyle(fontSize: 9, color: AppTheme.textDim),
            ),
        ],
      ),
    );
  }

  Widget _buildTankStats(GameState gs, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Kanał Ściekowy',
                style: theme.textTheme.titleMedium,
              ),
              Text(
                '${gs.tankMl.toStringAsFixed(0)} ml',
                style: TextStyle(
                  color: AppTheme.slime,
                  fontFamily: 'ShareTechMono',
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: (gs.tankMl / gs.rebirthThreshold).clamp(0.0, 1.0),
            backgroundColor: AppTheme.bg,
            valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.slime),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Bakterie: ${gs.bacteriaInTank}/${GameState.maxBacteria}',
                style: theme.textTheme.bodySmall,
              ),
              if (gs.bacteriaUnlocked)
                Text(
                  'Virus: ${gs.allergyMultiplier > 1 ? "Aktywne ${gs.allergyRemainingSeconds.toStringAsFixed(0)}s" : "Czeka..."}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: gs.allergyActive ? AppTheme.accent : AppTheme.textDim,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: gs.bacteriaUnlocked
                  ? () {
                      widget.controller.clickBacteria();
                      setState(() {});
                    }
                  : null,
              icon: const Icon(Icons.bug_report, size: 16),
              label: const Text('Aktywuj Bakterię'),
              style: ElevatedButton.styleFrom(
                backgroundColor: gs.bacteriaUnlocked ? AppTheme.virus : AppTheme.bg,
                foregroundColor: AppTheme.bg,
                disabledBackgroundColor: AppTheme.bg3,
                disabledForegroundColor: AppTheme.textDim,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPollenOverlay(GameState gs) {
    return Positioned(
      left: gs.pollenLeft,
      top: gs.pollenTop,
      child: GestureDetector(
        onTap: () {
          widget.controller.clickPollen();
          setState(() {});
        },
        child: Container(
          width: gs.pollenSize,
          height: gs.pollenSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.yellow.withValues(alpha: 0.6),
            border: Border.all(color: Colors.yellow, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.yellow.withValues(alpha: 0.4),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: const Center(
            child: Icon(Icons.pets, size: 20, color: Colors.orange),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    widget.controller.removeListener(_onGameUpdate);
    super.dispose();
  }
}






