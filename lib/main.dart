import 'package:flutter/material.dart';

import 'game_state.dart';
import 'features/game/logic/game_controller.dart';
import 'features/game/presentation/screens/character_screen.dart';
import 'features/game/presentation/screens/channel_screen.dart';
import 'shared/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final gameState = GameState.instance;
  await gameState.loadGame();
  runApp(MyApp(gameState: gameState));
}

class MyApp extends StatelessWidget {
  final GameState gameState;

  const MyApp({super.key, required this.gameState});

  @override
  Widget build(BuildContext context) {
    final controller = GameController(gameState);

    return MaterialApp(
      title: 'Nose Dripper Clicker',
      theme: AppTheme.dark,
      debugShowCheckedModeBanner: false,
      home: MainNavigation(controller: controller),
    );
  }
}

class MainNavigation extends StatefulWidget {
  final GameController controller;

  const MainNavigation({super.key, required this.controller});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  @override
  void dispose() {
    widget.controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          CharacterScreenWrapper(),
          ChannelScreenWrapper(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.card,
          border: Border(top: BorderSide(color: AppTheme.border)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _NavItem(
                  icon: Icons.face_rounded,
                  label: 'Ogr',
                  index: 0,
                  isSelected: true,
                ),
                _NavItem(
                  icon: Icons.water_drop,
                  label: 'Kanał',
                  index: 1,
                  isSelected: false,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final int index;
  final bool isSelected;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.index,
    required this.isSelected,
  });

  @override
  State<_NavItem> createState() => __NavItemState();
}

class __NavItemState extends State<_NavItem> {
  @override
  Widget build(BuildContext context) {
    final nav = context.findAncestorStateOfType<_MainNavigationState>();
    return GestureDetector(
      onTap: () => nav?.setState(() => nav._currentIndex = widget.index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: widget.isSelected ? AppTheme.slime.withValues(alpha: 0.15) : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Icon(
              widget.icon,
              color: widget.isSelected ? AppTheme.slime : AppTheme.textDim,
              size: 24,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.label,
            style: TextStyle(
              fontSize: 11,
              fontFamily: 'ShareTechMono',
              color: widget.isSelected ? AppTheme.slime : AppTheme.textDim,
              fontWeight: widget.isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

class CharacterScreenWrapper extends StatelessWidget {
  const CharacterScreenWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final nav = context.findAncestorStateOfType<_MainNavigationState>();
    final controller = nav!.widget.controller;
    return CharacterScreen(controller: controller);
  }
}

class ChannelScreenWrapper extends StatelessWidget {
  const ChannelScreenWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final nav = context.findAncestorStateOfType<_MainNavigationState>();
    final controller = nav!.widget.controller;
    return ChannelScreen(controller: controller);
  }
}


