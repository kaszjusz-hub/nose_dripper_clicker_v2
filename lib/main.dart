import 'package:flutter/material.dart';
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

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const ClampingScrollPhysics(),
        children: [
          const NoseScreen(),
          const KanaalScreen(),
        ],
      ),
    );
  }
}