import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Point d'accès unique à la persistance.
///
/// Aujourd'hui : un blob JSON dans `shared_preferences` (fonctionne sur
/// Android, iOS, web, desktop, sans aucun backend).
/// Demain : remplacer cette classe par une implémentation Supabase/Firebase
/// sans toucher aux écrans — seul `AppState` l'utilise.
abstract class FanZoneStore {
  Future<Map<String, dynamic>?> load();
  Future<void> save(Map<String, dynamic> data);
}

class LocalStore implements FanZoneStore {
  static const _key = 'fanzone_state_v1';

  @override
  Future<Map<String, dynamic>?> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null || raw.isEmpty) return null;
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
      return null;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> save(Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, jsonEncode(data));
    } catch (_) {
      // La persistance est « best effort » : l'app reste utilisable en mémoire.
    }
  }
}
