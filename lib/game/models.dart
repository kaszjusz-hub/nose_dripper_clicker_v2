// Models for the game


// Bacteria class (lightweight, only geometry + timeout)
class Bacteria {
  final int id;
  final DateTime spawnedAt;
  final double left;
  final double top;
  Bacteria(this.id, this.spawnedAt, this.left, this.top);
}

// Virus types (enum)
enum VirusType {
  Discount,      // -5% cost on Nose/Room upgrades for 1h
  FreeClick,    // instant: +1 free click boost
  InstantDNA,   // instant: +10 DNA
  Multiplier,   // +2% global income for 1h
  AutoCollect,  // every 15s collect 100*autoCollectLevel glut for 5min
}

// Virus class (active in inventory or slot)
class Virus {
  final int id;
  final VirusType type;
  final DateTime spawnTime;
  final int? durationSeconds; // null for instant effects
  Virus(this.id, this.type, this.spawnTime, this.durationSeconds);
}

// Pathogen/Ekwipunek slot
class VirusSlot {
  final int slotIndex;
  Virus? virus; // null if empty
  VirusSlot(this.slotIndex, {this.virus});
}
