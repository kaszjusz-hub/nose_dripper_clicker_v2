import 'package:flutter/material.dart';

class ClickAnimation extends StatefulWidget {
  final Offset position;
  final int count;
  final VoidCallback? onTap;

  const ClickAnimation({
    required this.position,
    required this.count,
    this.onTap,
  });

  @override
  State<ClickAnimation> createState() => _ClickAnimationState();
}

class _ClickAnimationState extends State<ClickAnimation> with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _opacityAnim;
  bool _visible = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnim = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
    ));

    _opacityAnim = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.7, 1.0, curve: Curves.easeOut),
    ));

    _controller.forward();
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() => _visible = false);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) return const SizedBox.shrink();

    return Positioned(
      left: widget.position.dx - 50,
      top: widget.position.dy - 50,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, child) {
          return Opacity(
            opacity: _opacityAnim.value,
            child: Transform.scale(
              scale: _scaleAnim.value,
              child: child,
            ),
          );
        },
        child: GestureDetector(
          onTap: widget.onTap,
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF7ec850),
                  Color(0xFF4a8a2a),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF7ec850).withOpacity(0.6),
                  blurRadius: 20,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: Center(
              child: Text(
                '👃',
                style: const TextStyle(fontSize: 48),
              ),
            ),
          ),
        ),
      ),
    );
  }
}