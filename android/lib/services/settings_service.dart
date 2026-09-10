import 'package:shared_preferences/shared_preferences.dart';

/// نگهداری و ذخیره‌ی تنظیمات ساده‌ی برنامه (معادل بخشی از AppSettings.cs)
class SettingsService {
  static const _keyDarkMode = 'dark_mode';
  static const _keyChunkSizeMb = 'chunk_size_mb';
  static const _keyLanguage = 'language';
  static const _keyRandomizeFilename = 'randomize_filename';
  static const _keyNameStyle = 'name_style'; // 0=cacheLike, 1=dataLike, 2=guidShort
  static const _keyOutputDir = 'output_dir';

  static Future<bool> getDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyDarkMode) ?? false;
  }

  static Future<void> setDarkMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyDarkMode, value);
  }

  static Future<int> getChunkSizeMb() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyChunkSizeMb) ?? 4;
  }

  static Future<void> setChunkSizeMb(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyChunkSizeMb, value);
  }

  static Future<String> getLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyLanguage) ?? 'fa';
  }

  static Future<void> setLanguage(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLanguage, value);
  }

  static Future<bool> getRandomizeFilename() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyRandomizeFilename) ?? false;
  }

  static Future<void> setRandomizeFilename(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyRandomizeFilename, value);
  }

  static Future<int> getNameStyle() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyNameStyle) ?? 0;
  }

  static Future<void> setNameStyle(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyNameStyle, value);
  }

  static Future<String?> getOutputDir() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyOutputDir);
  }

  static Future<void> setOutputDir(String? value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value == null) {
      await prefs.remove(_keyOutputDir);
    } else {
      await prefs.setString(_keyOutputDir, value);
    }
  }
}
