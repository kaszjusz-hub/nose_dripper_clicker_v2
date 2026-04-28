// Game mechanics – simplified version for current GameState API
import 'dart:async';
import '../game_state.dart';

class GameMechanics {
  final GameState state;

  GameMechanics(this.state);

  // ----- COLLECT GLUTY -----
  void collectGluty(double amount) {
    if (amount <= 0) return;
    state.tankMl = (state.tankMl + amount).clamp(0.0, 250.0);
    state.glutCount += amount.toInt();
  }

  // ----- CLICK NOSE -----
  double comboPoints = 0.0;

  void clickNose() {
    // Increase combo
    comboPoints += 1.0;
    final double multiplier = 1.0 + (comboPoints * 0.01).clamp(0.0, 2.0);

    // Calculate income
    const double baseYield = 100.0;
    final int income = (baseYield * multiplier).toInt();

    // Collect
    collectGluty(income.toDouble());
  }

  // ----- PASSIVE INCOME -----
  Timer? _passiveTimer;

  void startPassiveIncome() {
    if (_passiveTimer != null) return;
    _passiveTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      // Base passive income
      collectGluty(GameState.instance.passiveDrip);
    });
  }

  void stopPassiveIncome() {
    _passiveTimer?.cancel();
    _passiveTimer = null;
  }

  // ---- BACTERIA SPAWNING ----
  Timer? _bacteriaTimer;

  void startBacteriaSpawning() {
    if (_bacteriaTimer != null) return;
    _bacteriaTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (state.bacteriaInTank < GameState.maxBacteria) {
        state.bacteriaInTank++;
      }
    });
  }

  void stopBacteriaSpawning() {
    _bacteriaTimer?.cancel();
    _bacteriaTimer = null;
  }

  void dispose() {
    stopPassiveIncome();
    stopBacteriaSpawning();
  }
}
