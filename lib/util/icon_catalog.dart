import 'package:flutter/widgets.dart';
import 'package:material_symbols_icons/get.dart';

import 'tabler_catalog.dart';

/// Name-keyed access to two icon sets: Material Symbols (~4300) and Tabler
/// (6268), searched together.
///
/// Icons are stored in the database as their string name, so the sets can grow
/// without a migration. Material Symbols resolution goes through
/// [SymbolsGet.get], which needs the app to be built with
/// `--no-tree-shake-icons`.
class IconCatalog {
  const IconCatalog._();

  static const fallback = 'question_mark';
  static const defaultReminder = 'alarm';

  /// Tabler names carry this prefix so they cannot collide with a Material
  /// Symbols name, and so keys stored before Tabler existed still resolve.
  static const tablerPrefix = 'tb:';

  static IconData resolve(String? name) {
    if (name == null) return SymbolsGet.get(fallback, SymbolStyle.rounded);
    if (!name.startsWith(tablerPrefix)) {
      return SymbolsGet.get(name, SymbolStyle.rounded);
    }

    // The codepoints come from a runtime map lookup, so these cannot be const
    // IconData the way a hand-written `TablerIcons.foo` would be.
    final key = name.substring(tablerPrefix.length);
    final outline = tablerOutline[key];
    if (outline != null) {
      return IconData(
        // ignore: non_const_argument_for_const_parameter
        outline,
        fontFamily: tablerOutlineFamily,
        fontPackage: tablerFontPackage,
      );
    }

    final filled = tablerFilled[key];
    if (filled != null) {
      return IconData(
        // ignore: non_const_argument_for_const_parameter
        filled,
        fontFamily: tablerFilledFamily,
        fontPackage: tablerFontPackage,
      );
    }

    return SymbolsGet.get(fallback, SymbolStyle.rounded);
  }

  static bool exists(String name) {
    if (!name.startsWith(tablerPrefix)) return SymbolsGet.map.containsKey(name);
    final key = name.substring(tablerPrefix.length);
    return tablerOutline.containsKey(key) || tablerFilled.containsKey(key);
  }

  /// Ranks exact and prefix matches above substring matches so that typing
  /// "run" surfaces `run_circle` before `directions_run`. Material Symbols are
  /// offered ahead of Tabler within each rank, since they match the app's own
  /// icons.
  static List<String> search(String query, {int limit = 300}) {
    final q = query.trim().toLowerCase().replaceAll(' ', '_');
    if (q.isEmpty) return suggested;

    final exact = <String>[];
    final prefix = <String>[];
    final contains = <String>[];
    var found = 0;

    void consider(String key, String stored) {
      if (found >= limit * 3) return;
      if (key == q) {
        exact.add(stored);
      } else if (key.startsWith(q)) {
        prefix.add(stored);
      } else if (key.contains(q)) {
        contains.add(stored);
      } else {
        return;
      }
      found++;
    }

    for (final name in SymbolsGet.map.keys) {
      consider(name, name);
    }
    for (final key in tablerOutline.keys) {
      consider(key, '$tablerPrefix$key');
    }
    for (final key in tablerFilled.keys) {
      consider(key, '$tablerPrefix$key');
    }

    return [...exact, ...prefix, ...contains].take(limit).toList();
  }

  static List<String>? _suggestedCache;

  /// Shown before the user types anything — the icons a reminder app actually
  /// needs, rather than the head of an alphabetical dump. Filtered against the
  /// real symbol set so a renamed icon degrades to absent, not to a `?` tile.
  static List<String> get suggested =>
      _suggestedCache ??= _suggested.where(exists).toList(growable: false);

  static const _suggested = <String>[
    'alarm', 'schedule', 'timer', 'hourglass_empty', 'snooze', 'event',
    'notifications', 'task_alt', 'checklist', 'flag', 'star', 'favorite',
    'medication', 'vaccines', 'monitor_heart', 'healing', 'health_and_safety',
    'ecg_heart', 'humidity_low', 'water_drop', 'nutrition', 'grocery',
    'fitness_center', 'directions_run', 'directions_walk', 'directions_bike',
    'pool', 'self_improvement', 'sports_soccer', 'sports_basketball', 'spa',
    'exercise',
    'restaurant', 'local_cafe', 'coffee', 'lunch_dining', 'dinner_dining',
    'breakfast_dining', 'bakery_dining', 'local_pizza', 'egg', 'icecream',
    'kitchen', 'blender',
    'home', 'bed', 'shower', 'bathtub', 'cleaning_services', 'local_laundry_service',
    'chair', 'light', 'door_front', 'yard', 'local_florist', 'pets',
    'work', 'business_center', 'computer', 'laptop_mac', 'keyboard', 'mail',
    'call', 'phone_iphone', 'chat', 'groups', 'handshake', 'description',
    'folder', 'print', 'attach_money', 'payments', 'savings', 'credit_card',
    'receipt_long', 'shopping_cart', 'shopping_bag', 'store',
    'school', 'menu_book', 'auto_stories', 'edit', 'edit_note', 'draw',
    'palette', 'brush', 'music_note', 'headphones', 'piano', 'mic',
    'photo_camera', 'movie', 'tv', 'sports_esports', 'book',
    'directions_car', 'local_gas_station', 'flight', 'train', 'directions_bus',
    'two_wheeler', 'local_shipping', 'ev_station', 'commute',
    'wb_sunny', 'dark_mode', 'bedtime', 'nightlight', 'cloud', 'umbrella',
    'ac_unit', 'thermostat', 'eco', 'recycling', 'forest', 'park',
    'settings', 'build', 'handyman', 'construction', 'plumbing', 'hardware',
    'tune', 'key', 'lock', 'shield', 'verified', 'lightbulb', 'bolt',
    'person', 'face', 'child_care', 'family_restroom', 'elderly',
    'accessibility_new', 'cake', 'celebration', 'redeem', 'volunteer_activism',
    'wifi', 'battery_full', 'power', 'devices', 'watch', 'smartphone',
  ];
}
