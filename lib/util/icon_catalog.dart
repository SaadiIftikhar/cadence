import 'package:flutter/widgets.dart';
import 'package:material_symbols_icons/get.dart';

/// Name-keyed access to the full Material Symbols set (~4300 icons).
///
/// Icons are stored in the database as their string name, so the set can grow
/// without a migration. Resolution goes through [SymbolsGet.get], which needs
/// the app to be built with `--no-tree-shake-icons`.
class IconCatalog {
  const IconCatalog._();

  static const fallback = 'question_mark';
  static const defaultReminder = 'alarm';

  static IconData resolve(String? name) =>
      SymbolsGet.get(name ?? fallback, SymbolStyle.rounded);

  static List<String> get allNames => SymbolsGet.values.toList(growable: false);

  static bool exists(String name) => SymbolsGet.map.containsKey(name);

  /// Ranks exact and prefix matches above substring matches so that typing
  /// "run" surfaces `run_circle` before `directions_run`.
  static List<String> search(String query, {int limit = 300}) {
    final q = query.trim().toLowerCase().replaceAll(' ', '_');
    if (q.isEmpty) return suggested;

    final exact = <String>[];
    final prefix = <String>[];
    final contains = <String>[];

    for (final name in SymbolsGet.map.keys) {
      if (name == q) {
        exact.add(name);
      } else if (name.startsWith(q)) {
        prefix.add(name);
      } else if (name.contains(q)) {
        contains.add(name);
      }
      if (exact.length + prefix.length + contains.length >= limit * 3) break;
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
