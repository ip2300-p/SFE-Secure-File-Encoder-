import 'package:flutter/material.dart';
import 'services/settings_service.dart';
import 'services/app_lock_service.dart';
import 'screens/home_screen.dart';
import 'screens/lock_screen.dart';

/// ValueNotifier های سراسری برای تغییر تم و زبان
final ValueNotifier<ThemeMode> themeModeNotifier =
ValueNotifier(ThemeMode.light);

/// 'fa' یا 'en'
final ValueNotifier<String> languageNotifier = ValueNotifier('fa');

/// پوشه‌ی پیش‌فرض ذخیره‌ی خروجی (null یعنی هنوز انتخاب نشده)
final ValueNotifier<String?> outputDirNotifier = ValueNotifier<String?>(null);

/// همیشه از این تابع برای عوض کردن پوشه‌ی پیش‌فرض استفاده کن (هم تنظیمات رو
/// ذخیره می‌کنه، هم همه‌ی صفحاتی که به این notifier گوش میدن رو به‌روز می‌کنه)
Future<void> setDefaultOutputDir(String? path) async {
  outputDirNotifier.value = path;
  await SettingsService.setOutputDir(path);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final isDark = await SettingsService.getDarkMode();
  themeModeNotifier.value = isDark ? ThemeMode.dark : ThemeMode.light;
  languageNotifier.value = await SettingsService.getLanguage();
  outputDirNotifier.value = await SettingsService.getOutputDir();
  final lockEnabled = await AppLockService.isEnabled();
  runApp(SfeApp(startLocked: lockEnabled));
}

class SfeApp extends StatelessWidget {
  final bool startLocked;
  const SfeApp({super.key, required this.startLocked});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (context, mode, _) {
        return ValueListenableBuilder<String>(
          valueListenable: languageNotifier,
          builder: (context, lang, __) {
            final isRtl = lang == 'fa';

            const primaryColor = Colors.indigo;

            return MaterialApp(
              title: 'SFE',
              debugShowCheckedModeBanner: false,
              themeMode: mode,
              theme: ThemeData(
                useMaterial3: true,
                colorSchemeSeed: primaryColor,
                brightness: Brightness.light,
                fontFamily: 'Vazirmatn',
                scaffoldBackgroundColor: const Color(0xFFF8F9FA),
                // اصلاح تایپ از CardTheme به CardThemeData
                cardTheme: CardThemeData(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
                inputDecorationTheme: InputDecorationTheme(
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: primaryColor, width: 1.5),
                  ),
                ),
              ),
              darkTheme: ThemeData(
                useMaterial3: true,
                colorSchemeSeed: primaryColor,
                brightness: Brightness.dark,
                fontFamily: 'Vazirmatn',
                scaffoldBackgroundColor: const Color(0xFF121318),
                // اصلاح تایپ از CardTheme به CardThemeData
                cardTheme: CardThemeData(
                  elevation: 0,
                  color: const Color(0xFF1E1F28),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: Color(0xFF2C2D3A)),
                  ),
                ),
                inputDecorationTheme: InputDecorationTheme(
                  filled: true,
                  fillColor: const Color(0xFF1A1B23),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF2C2D3A)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF2C2D3A)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.indigoAccent, width: 1.5),
                  ),
                ),
              ),
              builder: (context, child) => Directionality(
                textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                child: child!,
              ),
              home: startLocked ? LockScreen() : HomeScreen(),
            );
          },
        );
      },
    );
  }
}