import 'package:flutter/material.dart';
import 'dart:async';
import 'game_state.dart';
import 'nose_screen.dart';
import 'kanaal_screen.dart';

void main() {
  runApp(const NoseDripperClicker());
}

class NoseDripperClicker extends StatelessWidget {
  const NoseDripperClicker({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nose Dripper Clicker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF7ec850),
        scaffoldBackgroundColor: const Color(0xFF0d0f0a),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Color(0xFFcdd9b5)),
          bodyMedium: TextStyle(color: Color(0xFFcdd9b5)),
        ),
      ),
      home: const MainNavigation(),
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  final PageController _pageController = PageController(initialPage: 0);
  Timer? _saveTimer;

  @override
  void initState() {
    super.initState();
    // Load game state (non-blocking, setState after load)
    GameState().loadGame().then((loaded) {
      if (mounted && loaded) setState(() {});
    });
    // Start periodic save every 30 seconds
    _saveTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      GameState().saveGame();
    });
  }

  @override
  void dispose() {
    // Save before app closes
    GameState().saveGame();
    _saveTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        scrollDirection: Axis.vertical,
        controller: _pageController,
        physics: const ClampingScrollPhysics(),
        onPageChanged: (index) {
          // Save when switching screens
          GameState().saveGame();
        },
        children: [
          const NoseScreen(),
          const KanaalScreen(),
        ],
      ),
    );
  }
}
