import 'dart:math';
import 'game_state.dart';

class _Chance {
  final int weight;
  final Function(GameState) effect;

  _Chance({required this.weight, required this.effect});
}

class Effect {
  final EffectType type;
  final int baseMultiplier;
  final List<_Chance> chances;

  Effect(this.type, this.baseMultiplier, {this.chances = const []});

  void apply(GameState gameState) {
    switch (type) {
      case EffectType.glut:
        // Add glut to tank
        gameState.tankMl = min(gameState.tankMl + (10.0 * baseMultiplier), 200.0);
        break;

      case EffectType.kapital:
        // Add DNA points
        if (gameState.dnaPoints > 0) {
          final boost = Random().nextInt(100);
          if (boost < 50) {
            gameState.unspentDna += (boost % 50).abs() + 1;
          }
        }
        gameState.unspentDna = min(2000, gameState.unspentDna + 1);
        break;

      case EffectType.virus:
        // Virus mutation placeholder
        break;

      case EffectType.virusRarity:
        // Rare virus chance
        if (gameState.maxVirusSlots > 1 && Random().nextDouble() < 0.05) {
          // Rare virus effect
        }
        break;

      case EffectType.mutation:
        // DNA mutation placeholder
        break;

      case EffectType.dnaSlot:
        // Add virus slot
        gameState.maxVirusSlots = min(5, gameState.maxVirusSlots + 1);
        break;
    }
  }
}

enum EffectType { glut, kapital, virus, virusRarity, mutation, dnaSlot }