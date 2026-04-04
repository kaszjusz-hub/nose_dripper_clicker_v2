import 'package:flutter/material.dart';
import 'game_state.dart';
import 'dna_upgrade.dart';

class DNAShopScreen extends StatefulWidget {
  const DNAShopScreen({Key? key}) : super(key: key);

  @override
  State<DNAShopScreen> createState() => _DNAShopScreenState();
}

class _DNAShopScreenState extends State<DNAShopScreen> {
  final GameState gameState = GameState.instance;

  // DNA upgrades list
  late List<DNAUpgrade> effectUpgrades;

  @override
  void initState() {
    super.initState();
    effectUpgrades = [
      DNAUpgrade(
        title: 'Szybciej',
        description: 'Zwiększ szybkość kliknięcia',
        baseCost: 10,
        effect: () {
          setState(() {});
        },
      ),
      DNAUpgrade(
        title: 'Więcej glutu',
        description: 'Zwiększ ilość glutu na kliknięcie',
        baseCost: 20,
        effect: () {
          setState(() {});
        },
      ),
    ];
  }

  bool _canBuy(DNAUpgrade upgrade) =>
      gameState.dnaPoints >= upgrade.baseCost && upgrade.level < 10;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sklep DNA'),
      ),
      body: ListView.builder(
        itemCount: effectUpgrades.length,
        itemBuilder: (context, index) {
          final upgrade = effectUpgrades[index];
          final canBuy = _canBuy(upgrade);
          final cost = upgrade.currentCost(upgrade.level);

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    upgrade.title,
                    style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    upgrade.description,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Poziom: ${upgrade.level}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        'Koszt: $cost DNA',
                        style: Theme.of(context).textTheme.bodySmall!.copyWith(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: canBuy
                        ? () {
                            gameState.dnaPoints =
                                (gameState.dnaPoints - cost).toInt();
                            upgrade.level++;
                            upgrade.effect();
                            setState(() {});
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Zakupiono: ${upgrade.title}'),
                              ),
                            );
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: canBuy ? Colors.green : Colors.grey,
                    ),
                    child: const Text('Kup'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}