import 'package:flutter/material.dart';
import '../../../../shared/theme/app_theme.dart';

class ComboBar extends StatelessWidget {
  final double comboPoints;
  final double multiplier;
  final double allergyMultiplier;
  final bool allergyActive;
  final double allergyRemainingSeconds;

  const ComboBar({
    super.key,
    required this.comboPoints,
    required this.multiplier,
    required this.allergyMultiplier,
    required this.allergyActive,
    required this.allergyRemainingSeconds,
  });

  @override
  Widget build(BuildContext context) {
    final comboForLevel = (comboPoints ~/ 5).clamp(0, 20);
    final progress = comboPoints / 100.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.card,
        border: Border.all(color: AppTheme.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.whatshot, size: 16, color: AppTheme.slime),
                  const SizedBox(width: 6),
                  Text(
                    'COMBO',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDim,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  if (allergyActive)
                    Row(
                      children: [
                        Icon(Icons.pets, size: 14, color: Colors.yellow),
                        const SizedBox(width: 4),
                        Text(
                          '${allergyRemainingSeconds.toStringAsFixed(0)}s',
                          style: const TextStyle(
                            color: Colors.yellow,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                    ),
                  Text(
                    '×${multiplier.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: allergyActive ? Colors.yellow : AppTheme.slime,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: AppTheme.bg3,
              valueColor: AlwaysStoppedAnimation<Color>(
                comboForLevel >= 20 ? AppTheme.accent : AppTheme.slime,
              ),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Combo: ${comboPoints.toInt()}',
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.textDim,
                  fontFamily: 'ShareTechMono',
                ),
              ),
              Text(
                'Progi: 5 / 50 / 100 / 200',
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.textDim,
                  fontFamily: 'ShareTechMono',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
