import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/settings_service.dart';
import '../services/app_lock_service.dart';
import '../services/localization_service.dart';
import '../core/models/disguised_name.dart';
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
  bool _loading = true;

  static const _chunkOptions = [1, 2, 4, 8, 16];

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
    setState(() {
      _darkMode = dark;
      _chunkSizeMb = chunk;
      _appLockEnabled = lockEnabled;
      _language = lang;
      _randomizeFilename = randomize;
      _nameStyleIndex = nameStyle;
      _loading = false;
    });
  }

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
                      setState(() => _chunkSizeMb = value);
                      await SettingsService.setChunkSizeMb(value);
                    },
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