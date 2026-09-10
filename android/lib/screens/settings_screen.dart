import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../services/settings_service.dart';
import '../services/app_lock_service.dart';
import '../services/localization_service.dart';
import '../services/scenario_service.dart';
import '../core/models/disguised_name.dart';
import '../core/models/scenario.dart';
import '../main.dart'
    show themeModeNotifier, languageNotifier, outputDirNotifier, setDefaultOutputDir;

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _darkMode = false;
  int _chunkSizeMb = 4;
  bool _appLockEnabled = false;
  String _language = 'fa';
  bool _randomizeFilename = false;
  int _nameStyleIndex = 0;
  List<Scenario> _scenarios = [];
  bool _loading = true;

  static const _chunkOptions = [1, 2, 4, 8, 16];

  // این مقادیر رو در صورت نیاز با آدرس‌های واقعی خودت جایگزین کن
  static const _githubUrl =
      'https://github.com/ip2300-p/SFE-Secure-File-Encoder-';
  static const _issuesUrl =
      'https://github.com/ip2300-p/SFE-Secure-File-Encoder-/issues';
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final dark = await SettingsService.getDarkMode();
    final chunk = await SettingsService.getChunkSizeMb();
    final lockEnabled = await AppLockService.isEnabled();
    final lang = await SettingsService.getLanguage();
    final randomize = await SettingsService.getRandomizeFilename();
    final nameStyle = await SettingsService.getNameStyle();
    final scenarios = await ScenarioService.getAll();
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _darkMode = dark;
      _chunkSizeMb = chunk;
      _appLockEnabled = lockEnabled;
      _language = lang;
      _randomizeFilename = randomize;
      _nameStyleIndex = nameStyle;
      _scenarios = scenarios;
      // versionName + شماره‌ی build (مثلاً "1.0.0 (1)") - دقیقاً همون چیزی
      // که توی pubspec.yaml بعد از "version:" نوشته شده
      _appVersion = '${packageInfo.version} (${packageInfo.buildNumber})';
      _loading = false;
    });
  }

  String get _nameStyleDesc => switch (_nameStyleIndex) {
    1 => AppStrings.t('name_style_data_desc'),
    2 => AppStrings.t('name_style_guid_desc'),
    _ => AppStrings.t('name_style_cache_desc'),
  };

  Future<void> _onToggleAppLock(bool value) async {
    if (!value) {
      await AppLockService.setEnabled(false);
      setState(() => _appLockEnabled = false);
      return;
    }

    final supported = await AppLockService.isDeviceSupported();
    if (!supported) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.t('no_device_lock'))),
      );
      return;
    }

    final ok = await AppLockService.authenticate(
      reason: AppStrings.t('confirm_enable_lock_reason'),
    );
    if (!mounted) return;
    if (ok) {
      await AppLockService.setEnabled(true);
      setState(() => _appLockEnabled = true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.t('auth_failed'))),
      );
    }
  }

  Future<void> _onLanguageChanged(String? lang) async {
    if (lang == null) return;
    setState(() => _language = lang);
    await SettingsService.setLanguage(lang);
    languageNotifier.value = lang;
  }

  Future<void> _saveCurrentAsScenario() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppStrings.t('new_scenario_title')),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(hintText: AppStrings.t('scenario_name_hint')),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppStrings.t('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: Text(AppStrings.t('save')),
          ),
        ],
      ),
    );

    if (name == null || name.isEmpty) return;

    await ScenarioService.add(
      name: name,
      chunkSizeMb: _chunkSizeMb,
      randomizeFilename: _randomizeFilename,
      nameStyleIndex: _nameStyleIndex,
      outputDir: outputDirNotifier.value,
    );
    _load();
  }

  Future<void> _applyScenario(Scenario s) async {
    setState(() {
      _chunkSizeMb = s.chunkSizeMb;
      _randomizeFilename = s.randomizeFilename;
      _nameStyleIndex = s.nameStyleIndex;
    });
    await SettingsService.setChunkSizeMb(s.chunkSizeMb);
    await SettingsService.setRandomizeFilename(s.randomizeFilename);
    await SettingsService.setNameStyle(s.nameStyleIndex);
    await setDefaultOutputDir(s.outputDir);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${AppStrings.t('scenario_applied_prefix')}${s.name}')),
    );
  }

  Future<void> _deleteScenario(Scenario s) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppStrings.t('delete_scenario_title')),
        content: Text('${AppStrings.t('delete_scenario_body')} «${s.name}»'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppStrings.t('cancel')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(AppStrings.t('delete_yes')),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ScenarioService.remove(s.id);
    _load();
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.t('could_not_open_link'))),
      );
    }
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppStrings.t('settings_title'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          _buildSectionHeader(AppStrings.t('section_general')),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.dark_mode_outlined),
                  title: Text(AppStrings.t('dark_mode')),
                  value: _darkMode,
                  onChanged: (value) async {
                    setState(() => _darkMode = value);
                    await SettingsService.setDarkMode(value);
                    themeModeNotifier.value =
                        value ? ThemeMode.dark : ThemeMode.light;
                  },
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  leading: const Icon(Icons.language_outlined),
                  title: Text(AppStrings.t('language')),
                  trailing: DropdownButton<String>(
                    value: _language,
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(value: 'fa', child: Text('فارسی')),
                      DropdownMenuItem(value: 'en', child: Text('English')),
                    ],
                    onChanged: _onLanguageChanged,
                  ),
                ),
              ],
            ),
          ),

          _buildSectionHeader(AppStrings.t('section_encryption')),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.data_usage_outlined),
                  title: Text(AppStrings.t('chunk_size_title')),
                  subtitle: Text(AppStrings.t('chunk_size_subtitle')),
                  trailing: DropdownButton<int>(
                    value: _chunkSizeMb,
                    underline: const SizedBox(),
                    items: _chunkOptions
                        .map((mb) => DropdownMenuItem(
                            value: mb, child: Text(AppStrings.mbLabel(mb))))
                        .toList(),
                    onChanged: (value) async {
                      if (value == null) return;
                      setState(() => _nameStyleIndex = value);
                      await SettingsService.setNameStyle(value);
                    },
                  ),
                ),
                if (_randomizeFilename)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Text(
                      _nameStyleDesc,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                SwitchListTile(
                  secondary: const Icon(Icons.shuffle_outlined),
                  title: Text(AppStrings.t('randomize_filename_title')),
                  subtitle: Text(
                    AppStrings.t('randomize_filename_subtitle'),
                    style: const TextStyle(fontSize: 11.5),
                  ),
                  value: _randomizeFilename,
                  onChanged: (value) async {
                    setState(() => _randomizeFilename = value);
                    await SettingsService.setRandomizeFilename(value);
                  },
                ),
                if (_randomizeFilename)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: DropdownButtonFormField<int>(
                      initialValue: _nameStyleIndex,
                      decoration: const InputDecoration(
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        DropdownMenuItem(
                            value: 0,
                            child: Text(AppStrings.t('name_style_cache_like'))),
                        DropdownMenuItem(
                            value: 1,
                            child: Text(AppStrings.t('name_style_data_like'))),
                        DropdownMenuItem(
                            value: 2,
                            child: Text(AppStrings.t('name_style_guid_short'))),
                      ],
                      onChanged: (value) async {
                        if (value == null) return;
                        setState(() => _nameStyleIndex = value);
                        await SettingsService.setNameStyle(value);
                      },
                    ),
                  ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                ValueListenableBuilder<String?>(
                  valueListenable: outputDirNotifier,
                  builder: (context, dir, _) {
                    return ListTile(
                      leading: const Icon(Icons.folder_outlined),
                      title: Text(AppStrings.t('default_output_dir_title')),
                      subtitle: Text(
                        dir ?? AppStrings.t('default_output_dir_not_set'),
                        style: const TextStyle(fontSize: 11.5),
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () async {
                        final picked = await FilePicker.platform.getDirectoryPath(
                          dialogTitle: AppStrings.t('choose_output_dir_title'),
                        );
                        if (picked != null) {
                          await setDefaultOutputDir(picked);
                        }
                      },
                      trailing: dir != null
                          ? IconButton(
                              icon: const Icon(Icons.close),
                              tooltip: AppStrings.t('cancel'),
                              onPressed: () => setDefaultOutputDir(null),
                            )
                          : Text(AppStrings.t('choose_folder')),
                    );
                  },
                ),
              ],
            ),
          ),

          _buildSectionHeader(AppStrings.t('section_security')),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: SwitchListTile(
              secondary: const Icon(Icons.fingerprint_outlined),
              title: Text(AppStrings.t('app_lock_title')),
              subtitle: Text(AppStrings.t('app_lock_subtitle')),
              value: _appLockEnabled,
              onChanged: _onToggleAppLock,
            ),
          ),

          _buildSectionHeader(AppStrings.t('section_scenarios')),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.add_circle_outline),
                  title: Text(AppStrings.t('save_current_as_scenario')),
                  onTap: _saveCurrentAsScenario,
                ),
                if (_scenarios.isEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Text(
                      AppStrings.t('no_scenarios_yet'),
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                for (final s in _scenarios) ...[
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  ListTile(
                    leading: const Icon(Icons.bookmark_outline),
                    title: Text(s.name),
                    subtitle: Text(
                      '${AppStrings.mbLabel(s.chunkSizeMb)}'
                      '${s.randomizeFilename ? ' • ${AppStrings.t('randomize_filename_title')}' : ''}',
                      style: const TextStyle(fontSize: 11.5),
                    ),
                    onTap: () => _applyScenario(s),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _deleteScenario(s),
                    ),
                  ),
                ],
              ],
            ),
          ),

          _buildSectionHeader(AppStrings.t('section_about')),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: Text(AppStrings.t('about_app_name')),
                  subtitle: Text('${AppStrings.t('about_version_label')} $_appVersion'),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  leading: const Icon(Icons.code_outlined),
                  title: Text(AppStrings.t('about_github')),
                  subtitle: const Text(
                    _githubUrl,
                    style: TextStyle(fontSize: 11.5),
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: const Icon(Icons.open_in_new, size: 18),
                  onTap: () => _openUrl(_githubUrl),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  leading: const Icon(Icons.bug_report_outlined),
                  title: Text(AppStrings.t('about_report_issue')),
                  trailing: const Icon(Icons.open_in_new, size: 18),
                  onTap: () => _openUrl(_issuesUrl),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  leading: const Icon(Icons.description_outlined),
                  title: Text(AppStrings.t('about_license')),
                  subtitle: const Text('MIT License'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

DisguisedNameStyle nameStyleFromIndex(int index) {
  switch (index) {
    case 1:
      return DisguisedNameStyle.dataLike;
    case 2:
      return DisguisedNameStyle.guidShort;
    default:
      return DisguisedNameStyle.cacheLike;
  }
}
