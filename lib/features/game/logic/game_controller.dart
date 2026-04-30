import 'package:flutter/foundation.dart';
import '../../../game_state.dart';

class GameController extends ChangeNotifier {
  final GameState _gameState;

  GameState get gameState => _gameState;

  GameController(this._gameState) {
    _gameState.startGameLoop();
    _gameState.startAllergySystem();
    _gameState.addTickListener(() {
      notifyListeners();
    });
  }

  void clickNose() {
    _gameState.clickNose();
    notifyListeners();
    _tryAutoSave();
  }

  void clickBacteria() {
    _gameState.clickBacteria();
    notifyListeners();
    _tryAutoSave();
  }

  void clickPollen() {
    _gameState.clickPollen();
    notifyListeners();
    _tryAutoSave();
  }

  bool buyNoseUpgrade(int level) {
    final success = _gameState.buyNoseUpgrade(level);
    if (success) {
      notifyListeners();
      _tryAutoSave();
    }
    return success;
  }

  bool buyRoomUpgrade(int level) {
    final success = _gameState.buyRoomUpgrade(level);
    if (success) {
      notifyListeners();
      _tryAutoSave();
    }
    return success;
  }

  bool buyDnaUpgrade(String upgradeId) {
    final success = _gameState.buyDnaUpgrade(upgradeId);
    if (success) {
      notifyListeners();
      _tryAutoSave();
    }
    return success;
  }

  void doRebirth() {
    _gameState.doRebirth();
    notifyListeners();
    _tryAutoSave();
  }

  void _tryAutoSave() {
    // Auto-save each action
    _gameState.saveGame().catchError((e) {
      if (kDebugMode) print('Auto-save error: $e');
    });
  }

  void loadGame() {
    _gameState.loadGame();
    notifyListeners();
  }

  @override
  void dispose() {
    _gameState.stopGameLoop();
    _gameState.stopAllergySystem();
    _gameState.saveGame();
    super.dispose();
  }
}
