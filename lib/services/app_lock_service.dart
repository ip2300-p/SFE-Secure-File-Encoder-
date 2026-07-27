import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// مدیریت قفل ورود به برنامه.
/// به‌جای ساختن یک PIN اختصاصی برای خود اپ، از همون قفل امنیتی‌ای که کاربر
/// از قبل روی گوشیش تنظیم کرده (اثر انگشت / تشخیص چهره / PIN / الگو)
/// استفاده می‌کنیم. این کار هم ساده‌تره و هم امن‌تر (چون خود اپ هیچ رمزی رو
/// ذخیره نمی‌کنه).
class AppLockService {
  static const _keyLockEnabled = 'app_lock_enabled';
  static final _auth = LocalAuthentication();

  static Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyLockEnabled) ?? false;
  }

  static Future<void> setEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyLockEnabled, value);
  }

  /// آیا دستگاه اصلاً از این نوع قفل پشتیبانی می‌کنه؟
  static Future<bool> isDeviceSupported() async {
    try {
      return await _auth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  /// تلاش برای احراز هویت. اگه کاربر قفلی روی گوشیش تنظیم نکرده باشه یا
  /// خطایی رخ بده، false برمی‌گردونه.
  static Future<bool> authenticate({String? reason}) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason ?? 'برای ورود به برنامه هویتت رو تأیید کن',
        biometricOnly: false, // اجازه بده از PIN/الگوی خود گوشی هم استفاده بشه
      );
    } catch (_) {
      return false;
    }
  }
}
