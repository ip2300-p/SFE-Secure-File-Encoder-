import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/models/scenario.dart';

/// معادل سبک‌شده‌ی مدیریت Scenario ها (فایل scenarios.json در نسخه‌ی ویندوز)
class ScenarioService {
  static const _key = 'scenarios';

  static Future<List<Scenario>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .map((e) => Scenario.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> _saveAll(List<Scenario> scenarios) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(scenarios.map((s) => s.toJson()).toList());
    await prefs.setString(_key, raw);
  }

  static Future<Scenario> add({
    required String name,
    required int chunkSizeMb,
    required bool randomizeFilename,
    required int nameStyleIndex,
    String? outputDir,
  }) async {
    final scenarios = await getAll();
    final scenario = Scenario(
      id: _generateId(),
      name: name,
      chunkSizeMb: chunkSizeMb,
      randomizeFilename: randomizeFilename,
      nameStyleIndex: nameStyleIndex,
      outputDir: outputDir,
    );
    scenarios.add(scenario);
    await _saveAll(scenarios);
    return scenario;
  }

  static Future<void> remove(String id) async {
    final scenarios = await getAll();
    scenarios.removeWhere((s) => s.id == id);
    await _saveAll(scenarios);
  }

  static String _generateId() {
    final rnd = Random.secure();
    return List.generate(12, (_) => rnd.nextInt(16).toRadixString(16)).join();
  }
}
