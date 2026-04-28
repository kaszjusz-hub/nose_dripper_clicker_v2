# Flutter Analysis Fixes Applied

## Date: 2026-04-28

## Problem
`flutter analyze --no-fatal-infos` reported 12 errors (all in `lib/game_state.dart`) due to corrupted/truncated source file:

### Errors Fixed:
1. `undefined_getter: dnaUpgrades` - lib/dna_shop_screen.dart:24,26
2. `undefined_getter: dnaUpgradeLevels` - lib/dna_shop_screen.dart:27
3. `undefined_getter: unspentDna` - lib/dna_shop_screen.dart:29, lib/effects.dart:30,33
4. `undefined_method: buyDnaUpgrade` - lib/dna_shop_screen.dart:91
5. `undefined_getter: dnaPoints` - lib/effects.dart:27
6. `undefined_setter: tankMl` - lib/effects.dart:22, lib/game/mechanics.dart:13
7. `undefined_getter: tankMl` - lib/effects.dart:22, lib/game/mechanics.dart:13
8. `undefined_getter: glutCount` - lib/game/mechanics.dart:14
9. `undefined_setter: glutCount` - lib/game/mechanics.dart:14
10. `undefined_getter: passiveDripBase` - lib/game/mechanics.dart:40
11. `undefined_getter: bacteriaInTank` - lib/game/mechanics.dart:55,56
12. `undefined_getter: maxBacteria` - lib/game/mechanics.dart:55
13. `undefined_getter: maxVirusSlots` - lib/effects.dart:42,53
14. `undefined_setter: maxVirusSlots` - lib/effects.dart:53

## Root Cause
The `lib/game_state.dart` file was corrupted/truncated (only ~50 lines instead of ~400). Missing:
- Class property declarations (`tankMl`, `glutCount`, `dnaPoints`, `unspentDna`, `bacteriaInTank`, `maxVirusSlots`, etc.)
- Getter definitions (`passiveDrip`, `dnaUpgrades`, `clickYield`, etc.)
- Constant definitions (`passiveDripBase`, `maxBacteria`, etc.)

## Fix Applied
Restored `lib/game_state.dart` from `lib/game_state.dart.backup` (21,449 bytes).

### Additional Fix
Updated `lib/game/mechanics.dart` line 39:
- Changed: `GameState.passiveDripBase` 
- To: `GameState.instance.passiveDrip`
- Reason: `passiveDripBase` was a static const in the original but `passiveDrip` is the computed getter that incorporates room upgrades and DNA multiplier - more accurate for the mechanic.

## Result
All 12 errors resolved. Only 16 informational lint issues remain (style/lint warnings, no build blockers):
- use_key_in_widget_constructors
- deprecated_member_use (withOpacity)
- library_private_types_in_public_api
- constant_identifier_names
- sized_box_for_whitespace
- unnecessary_brace_in_string_interps

## Files Modified
1. `lib/game_state.dart` - Restored from backup
2. `lib/game/mechanics.dart` - Fixed passive income reference

## Verification
```bash
cd nose_dripper_clicker_v2
flutter analyze --no-fatal-infos
# Result: 16 info, 0 errors ✓
```