import 'dart:math' as math;
import 'package:flutter/foundation.dart';

class DNAUpgrade {
  final String title;
  final String description;
  final int baseCost;
  final VoidCallback effect;
  int level = 0;

  DNAUpgrade({
    required this.title,
    required this.description,
    required this.baseCost,
    required this.effect,
  });

  int currentCost(int lvl) =>
      (baseCost * math.pow(1.5, lvl)).toInt();
}