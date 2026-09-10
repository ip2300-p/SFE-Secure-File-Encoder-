import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';
import 'package:open_file/open_file.dart';

import '../services/encryption_service.dart';
import '../services/decryption_service.dart';
import '../services/settings_service.dart';
import '../services/localization_service.dart';
import '../services/share_intent_service.dart';
import '../core/file_format/sfe_file_reader.dart';
import '../main.dart' show outputDirNotifier, setDefaultOutputDir;
import 'settings_screen.dart';

class _FileJob {
  final String inputPath;
  bool done = false;
  bool success = false;
  String? outputPath;
  String? error;

  _FileJob(this.inputPath);

  String get name => p.basename(inputPath);
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _passwordController = TextEditingController();
  final _secondaryPasswordController = TextEditingController();
  bool _useSecondaryPassword = false;
  bool _obscurePassword = true;
  bool _obscureSecondaryPassword = true;

  final List<_FileJob> _jobs = [];
  bool _busy = false;
  String? _currentFileName;
  double _progress = 0;
  int _jobIndex = 0;
  int _jobTotal = 0;

  String? _outputDirChoice;
  bool _deleteSourceAfter = false;
  bool _suppressTabClear = false;

  final _encryptionService = EncryptionService();
  final _decryptionService = DecryptionService();

  String get _effectivePassword => _useSecondaryPassword
      ? '${_passwordController.text}||${_secondaryPasswordController.text}'
      : _passwordController.text;

  // ── قدرت رمز (همون منطق نسخه‌ی ویندوز) ─────────────
  int get _passwordStrength {
    final p = _passwordController.text;
    if (p.isEmpty) return 0;
    int s = 0;
    if (p.length >= 8) s++;
    if (p.length >= 12) s++;
    if (p.contains(RegExp('[A-Z]')) && p.contains(RegExp('[a-z]'))) s++;
    if (p.contains(RegExp('[0-9]'))) s++;
    if (p.contains(RegExp(r'[^A-Za-z0-9]'))) s++;
    return s.clamp(0, 4);
  }

  // 🆕 رنگ‌های متناسب با تم: در حالت تاریک از رنگ‌های Catppuccin
  // و در حالت روشن از نسخه‌ی تیره‌تر (کنتراست بهتر) استفاده می‌کنیم
  Color get _strengthColor {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return switch (_passwordStrength) {
      1 => dark ? const Color(0xFFF38BA8) : Colors.red.shade700,
      2 => dark ? const Color(0xFFFAB387) : Colors.orange.shade700,
      3 => dark ? const Color(0xFFA6E3A1) : Colors.green.shade700,
      _ => dark ? const Color(0xFF89B4FA) : Colors.blue.shade700,
    };
  }

  String get _strengthLabel => switch (_passwordStrength) {
    1 => AppStrings.t('strength_weak'),
    2 => AppStrings.t('strength_medium'),
    3 => AppStrings.t('strength_strong'),
    _ => AppStrings.t('strength_very_strong'),
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging && !_suppressTabClear) {
        _clearJobsWithUndo();
      }
    });
    // پوشه‌ی پیش‌فرض ذخیره: هم مقدار فعلی رو می‌گیریم، هم اگه از صفحه‌ی
    // تنظیمات عوض بشه، اینجا هم خودکار به‌روز میشه
    _outputDirChoice = outputDirNotifier.value;
    outputDirNotifier.addListener(_onOutputDirChanged);

    // فایلی که از یک اپ دیگه به SFE اشتراک گذاشته شده یا مستقیم باز شده
    ShareIntentService.listen(_handleIncomingPaths);
    ShareIntentService.consumeInitial(_handleIncomingPaths);
  }

  void _onOutputDirChanged() {
    if (mounted) setState(() => _outputDirChoice = outputDirNotifier.value);
  }

  Future<void> _handleIncomingPaths(List<String> paths) async {
    if (paths.isEmpty) return;

    bool anySfe = false;
    for (final path in paths) {
      if (await SfeFileReader.isSfeFile(path)) {
        anySfe = true;
        break;
      }
    }

    if (!mounted) return;

    // اول تب رو (اگه لازمه) عوض می‌کنیم. چون animateTo چیزی برای await کردن
    // برنمی‌گردونه، با یک تأخیر کوتاه (بیشتر از مدت انیمیشن پیش‌فرض تب)
    // مطمئن می‌شیم قبل از فعال شدن دوباره‌ی منطق «پاک کردن لیست موقع تغییر
    // تب»، فایل‌های تازه‌اضافه‌شده رو زودتر اضافه کرده باشیم.
    _suppressTabClear = true;
    final targetIndex = anySfe ? 1 : 0;
    if (_tabController.index != targetIndex) {
      _tabController.animateTo(targetIndex);
    }

    setState(() {
      for (final path in paths) {
        if (!_jobs.any((j) => j.inputPath == path)) {
          _jobs.add(_FileJob(path));
        }
      }
    });

    await Future.delayed(const Duration(milliseconds: 400));
    _suppressTabClear = false;
  }

  @override
  void dispose() {
    outputDirNotifier.removeListener(_onOutputDirChanged);
    _tabController.dispose();
    _passwordController.dispose();
    _secondaryPasswordController.dispose();
    super.dispose();
  }

  Future<void> _addFiles() async {
    final result = await FilePicker.platform.pickFiles(allowMultiple: true);
    if (result == null) return;
    setState(() {
      for (final f in result.files) {
        if (f.path != null && !_jobs.any((j) => j.inputPath == f.path)) {
          _jobs.add(_FileJob(f.path!));
        }
      }
    });
  }

  void _removeJob(_FileJob job) {
    setState(() => _jobs.remove(job));
  }

  void _clearAll() => _clearJobsWithUndo();

  // 🆕 پاک کردن لیست با امکان بازگردانی (جلوگیری از نابودی تصادفی لیست)
  void _clearJobsWithUndo() {
    if (_jobs.isEmpty) return;
    final backup = List<_FileJob>.from(_jobs);
    setState(() => _jobs.clear());
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppStrings.t('list_cleared_undo')),
        action: SnackBarAction(
          label: AppStrings.t('undo_action'),
          onPressed: () {
            if (mounted) setState(() => _jobs.addAll(backup));
          },
        ),
        duration: const Duration(seconds: 6),
      ),
    );
  }

  // 🆕 پاک‌سازی فایل‌های موقت دسته‌ی قبلی از پوشه‌ی خصوصی اپ
  Future<void> _cleanStaleTempFiles() async {
    try {
      final dir = await getExternalStorageDirectory();
      if (dir == null) return;
      final keep = _jobs
          .where((j) => j.outputPath != null)
          .map((j) => j.outputPath)
          .toSet();
      await for (final entity in dir.list()) {
        if (entity is File && !keep.contains(entity.path)) {
          await entity.delete();
        }
      }
    } catch (_) {}
  }

  Future<String> _tempOutputDir() async {
    final dir = await getExternalStorageDirectory();
    return dir!.path;
  }

  Future<void> _pickOutputDir() async {
    final dir = await FilePicker.platform.getDirectoryPath(
      dialogTitle: AppStrings.t('choose_output_dir_title'),
    );
    if (dir != null) {
      setState(() => _outputDirChoice = dir);
      await setDefaultOutputDir(dir);
    }
  }

  Future<void> _toggleDeleteSource(bool value) async {
    if (!value) {
      setState(() => _deleteSourceAfter = false);
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppStrings.t('delete_confirm_title')),
        content: Text(AppStrings.t('delete_confirm_body')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppStrings.t('cancel')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(AppStrings.t('confirm_enable')),
          ),
        ],
      ),
    );
    setState(() => _deleteSourceAfter = confirmed ?? false);
  }

  Future<void> _runBatch({required bool encrypt}) async {
    // 🆕 به‌جای سکوت مطلق، به کاربر بگو چه چیزی کم است
    if (_jobs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.t('warn_no_files'))),
      );
      return;
    }
    if (_passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.t('warn_no_password'))),
      );
      return;
    }
    if (_useSecondaryPassword && _secondaryPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.t('warn_no_secondary'))),
      );
      return;
    }
    setState(() => _busy = true);
    // 🆕 پاک‌سازی فایل‌های موقتِ دسته‌ی قبلی (فضا + حریم خصوصی)
    await _cleanStaleTempFiles();
    if (_jobs.isEmpty || _passwordController.text.isEmpty) return;

    setState(() => _busy = true);
    final outDir = await _tempOutputDir();
    final chunkSizeMb = await SettingsService.getChunkSizeMb();
    final chunkSizeBytes = chunkSizeMb * 1024 * 1024;
    final randomizeFilename = await SettingsService.getRandomizeFilename();
    final nameStyle =
        nameStyleFromIndex(await SettingsService.getNameStyle());

    for (int i = 0; i < _jobs.length; i++) {
      final job = _jobs[i];
      if (job.done && job.success) continue;
      setState(() {
        _currentFileName = job.name;
        _progress = 0;
        _jobIndex = i;
        _jobTotal = _jobs.length;
      });

      final result = encrypt
          ? await _encryptionService.encryptFile(
              job.inputPath,
              outDir,
              _effectivePassword,
              chunkSize: chunkSizeBytes,
              randomizeFilename: randomizeFilename,
              nameStyle: nameStyle,
              onProgress: (v) => setState(() => _progress = v),
            )
          : await _decryptionService.decryptFile(
              job.inputPath,
              outDir,
              _effectivePassword,
              onProgress: (v) => setState(() => _progress = v),
            );

      setState(() {
        job.done = true;
        job.success = result.success;
        job.outputPath = result.filePath;
        job.error = result.errorMessage;
      });

      if (result.success && _deleteSourceAfter) {
        try {
          await File(job.inputPath).delete();
        } catch (_) {}
      }
    }

    setState(() {
      _busy = false;
      _currentFileName = null;
      // به‌خاطر امنیت، رمزها رو بعد از اتمام عملیات کامل پاک می‌کنیم
      _passwordController.clear();
      _secondaryPasswordController.clear();
    });

    if (_outputDirChoice != null) {
      await _autoSaveAllToChosenDir();
    }
  }

  Future<void> _saveAs(_FileJob job) async {
    if (job.outputPath == null) return;
    final suggestedName = p.basename(job.outputPath!);
    // 🆕 اول فقط مسیر مقصد رو می‌گیریم (بدون load کردن کل فایل در RAM)
    final savedPath = await FilePicker.platform.saveFile(
      dialogTitle: AppStrings.t('save_file_dialog_title'),
      fileName: suggestedName,
    );
    if (savedPath == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.t('cancelled_text'))),
        );
      }
      return;
    }
    try {
      // کپی استریمی و کم‌حافظه — امن برای فایل‌های چند گیگابایتی
      await File(job.outputPath!).copy(savedPath);
    } catch (e) {
      if (mounted) {
        final msg = e.toString().toLowerCase();
        final text = (msg.contains('no space left') || msg.contains('enospc'))
            ? AppStrings.t('error_out_of_space')
            : AppStrings.t('generic_error');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(text)),
        );
      }
      return;
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${AppStrings.t('saved_prefix')}$savedPath'),
        action: SnackBarAction(
          label: AppStrings.t('open_action'),
          onPressed: () => OpenFile.open(savedPath),
        ),
      ),
    );
  }

  Future<void> _share(_FileJob job) async {
    if (job.outputPath == null) return;
    await SharePlus.instance.share(
      ShareParams(files: [XFile(job.outputPath!)]),
    );
  }

  Future<void> _autoSaveAllToChosenDir() async {
    final successfulJobs =
        _jobs.where((j) => j.done && j.success && j.outputPath != null);
    int savedDirect = 0;
    int needsManual = 0;

    for (final job in successfulJobs) {
      final destPath =
          p.join(_outputDirChoice!, p.basename(job.outputPath!));
      try {
        await File(job.outputPath!).copy(destPath);
        savedDirect++;
      } catch (_) {
        needsManual++;
      }
    }

    if (!mounted) return;
    if (savedDirect + needsManual == 0) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          needsManual == 0
              ? AppStrings.t('autosave_all_ok')
              : AppStrings.autosavePartial(savedDirect, needsManual),
        ),
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: AppStrings.t('open_folder_action'),
          // این «تلاش با بهترین تلاش» است: باز شدن مستقیم یک پوشه بسته به
          // فایل‌منیجر نصب‌شده روی گوشی متفاوت عمل می‌کنه و ممکنه روی
          // بعضی گوشی‌ها کار نکنه.
          onPressed: () => OpenFile.open(_outputDirChoice!),
        ),
      ),
    );
  }

  Future<void> _saveAllOutputs() async {
    if (_outputDirChoice != null) {
      await _autoSaveAllToChosenDir();
      return;
    }
    for (final job in _jobs) {
      if (job.done && job.success) {
        await _saveAs(job);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasSuccessfulJobs = _jobs.any((j) => j.done && j.success);
    final isEncryptTab = _tabController.index == 0;
    // 🆕 رنگ حالت رمزگشایی یکدست با ویندوز (سبز Catppuccin)
    final modeColor = isEncryptTab
        ? theme.colorScheme.primary
        : (theme.brightness == Brightness.dark
        ? const Color(0xFFA6E3A1)
        : Colors.green.shade700);

    return PopScope(
      canPop: !_busy,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop) return;
        final leave = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(AppStrings.t('confirm_exit_title')),
            content: Text(AppStrings.t('confirm_exit_message')),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(AppStrings.t('cancel')),
              ),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(AppStrings.t('confirm_exit_leave')),
              ),
            ],
          ),
        );
        if (leave == true && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
      appBar: AppBar(
        title: Text(
          AppStrings.t('app_title'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        centerTitle: false,
        actions: [
          IconButton(
            tooltip: AppStrings.t('settings_tooltip'),
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorSize: TabBarIndicatorSize.tab,
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock_outline, size: 18),
                  const SizedBox(width: 8),
                  Text(AppStrings.t('encrypt_button')),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock_open_outlined, size: 18),
                  const SizedBox(width: 8),
                  Text(AppStrings.t('decrypt_button')),
                ],
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: GestureDetector(
          // سوییپ برای جابجایی بین تب رمزنگاری/رمزگشایی
          onHorizontalDragEnd: (details) {
            final velocity = details.primaryVelocity ?? 0;
            if (velocity.abs() < 200) return; // سوییپ خیلی آروم/تصادفی رو نادیده بگیر
            final current = _tabController.index;
            final next = velocity < 0 ? current + 1 : current - 1;
            if (next >= 0 && next < _tabController.length) {
              _tabController.animateTo(next);
            }
          },
          child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── نوار نشانگر حالت فعلی ────────────────────────
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: modeColor.withAlpha(25),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isEncryptTab ? Icons.lock_outline : Icons.lock_open_outlined,
                            size: 18,
                            color: modeColor,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isEncryptTab
                                ? AppStrings.t('mode_banner_encrypt')
                                : AppStrings.t('mode_banner_decrypt'),
                            style: TextStyle(
                              color: modeColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── کارت انتخاب فایل و لیست ─────────────────────────
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: modeColor.withAlpha(90)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  AppStrings.filesSelectedLabel(_jobs.length),
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (_jobs.isNotEmpty)
                                  IconButton(
                                    tooltip: AppStrings.t('clear_list_tooltip'),
                                    onPressed: _busy ? null : _clearAll,
                                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                    visualDensity: VisualDensity.compact,
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            
                            if (_jobs.isEmpty)
                              InkWell(
                                onTap: _busy ? null : _addFiles,
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: theme.colorScheme.primary.withAlpha(100),
                                      style: BorderStyle.solid,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    color: theme.colorScheme.primary.withAlpha(10),
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.note_add_outlined,
                                        size: 40,
                                        color: theme.colorScheme.primary,
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        AppStrings.t('add_file'),
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: theme.colorScheme.primary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        AppStrings.t('no_files_yet'),
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: theme.colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            else ...[
                              OutlinedButton.icon(
                                onPressed: _busy ? null : _addFiles,
                                icon: const Icon(Icons.add),
                                label: Text(AppStrings.t('add_file')),
                              ),
                              const SizedBox(height: 12),
                              ConstrainedBox(
                                constraints: const BoxConstraints(maxHeight: 320),
                                child: ListView.separated(
                                  shrinkWrap: true,
                                  physics: const ClampingScrollPhysics(),
                                  itemCount: _jobs.length,
                                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                                  itemBuilder: (context, index) {
                                  final job = _jobs[index];
                                  return Container(
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.surfaceContainerHighest.withAlpha(80),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: ListTile(
                                      dense: true,
                                      leading: Icon(
                                        !job.done
                                            ? Icons.insert_drive_file_outlined
                                            : (job.success
                                                ? Icons.check_circle_rounded
                                                : Icons.error_rounded),
                                        color: !job.done
                                            ? theme.colorScheme.primary
                                            : (job.success ? Colors.green : Colors.red),
                                      ),
                                      title: Text(
                                        job.name,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontWeight: FontWeight.w500),
                                      ),
                                      subtitle: job.done && !job.success
                                          ? Text(
                                        job.error ?? AppStrings.t('generic_error'),
                                        style: const TextStyle(color: Colors.red),
                                      )
                                          : (job.done && job.success && job.outputPath != null
                                          ? Text(
                                        p.basename(job.outputPath!),
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          color: theme.colorScheme.onSurfaceVariant,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      )
                                          : null),
                                      trailing: job.done && job.success
                                          ? Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                IconButton(
                                                  tooltip: AppStrings.t('save_tooltip'),
                                                  icon: const Icon(Icons.save_alt, size: 20),
                                                  onPressed: () => _saveAs(job),
                                                ),
                                                IconButton(
                                                  tooltip: AppStrings.t('share_tooltip'),
                                                  icon: const Icon(Icons.share, size: 20),
                                                  onPressed: () => _share(job),
                                                ),
                                              ],
                                            )
                                          : IconButton(
                                              icon: const Icon(Icons.close, size: 18),
                                              onPressed: _busy ? null : () => _removeJob(job),
                                            ),
                                    ),
                                  );
                                },
                              ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // ── کارت اطلاعات پسورد ─────────────────────────
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.key_outlined, size: 20, color: theme.colorScheme.primary),
                                const SizedBox(width: 8),
                                Text(
                                  AppStrings.t('password_label'),
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              onChanged: (_) => setState(() {}),
                              decoration: InputDecoration(
                                labelText: AppStrings.t('password_label'),
                                suffixIcon: IconButton(
                                  icon: Icon(_obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined),
                                  onPressed: () => setState(
                                      () => _obscurePassword = !_obscurePassword),
                                ),
                              ),
                            ),
                            if (_passwordController.text.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: LinearProgressIndicator(
                                          value: _passwordStrength / 4,
                                          minHeight: 6,
                                          backgroundColor:
                                          theme.colorScheme.surfaceContainerHighest,
                                          valueColor:
                                          AlwaysStoppedAnimation<Color>(_strengthColor),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _strengthLabel,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: _strengthColor,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                AppStrings.t('use_secondary_password'),
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                              ),
                              value: _useSecondaryPassword,
                              onChanged: _busy
                                  ? null
                                  : (v) => setState(() => _useSecondaryPassword = v),
                            ),
                            if (_useSecondaryPassword)
                              Padding(
                                padding: const EdgeInsets.only(top: 4, bottom: 8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    TextField(
                                      controller: _secondaryPasswordController,
                                      obscureText: _obscureSecondaryPassword,
                                      onChanged: (_) => setState(() {}),
                                      decoration: InputDecoration(
                                        labelText: AppStrings.t('secondary_password_label'),
                                        suffixIcon: IconButton(
                                          icon: Icon(_obscureSecondaryPassword
                                              ? Icons.visibility_outlined
                                              : Icons.visibility_off_outlined),
                                          onPressed: () => setState(() =>
                                          _obscureSecondaryPassword =
                                          !_obscureSecondaryPassword),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      AppStrings.t('secondary_password_warn'),
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        color: theme.brightness == Brightness.dark
                                            ? const Color(0xFFFAB387)
                                            : Colors.orange.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // ── کارت تنظیمات خروجی ─────────────────────────
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.folder_outlined, size: 20, color: theme.colorScheme.primary),
                                const SizedBox(width: 8),
                                Text(
                                  AppStrings.t('path_and_delete_section'),
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            InkWell(
                              onTap: _busy ? null : _pickOutputDir,
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surfaceContainerHighest.withAlpha(60),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.folder_open, size: 18),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _outputDirChoice ?? AppStrings.t('output_dir_not_chosen'),
                                        style: const TextStyle(fontSize: 12),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (_outputDirChoice != null)
                                      GestureDetector(
                                        onTap: _busy
                                            ? null
                                            : () {
                                                setState(() => _outputDirChoice = null);
                                                setDefaultOutputDir(null);
                                              },
                                        child: const Icon(Icons.close, size: 16),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                AppStrings.t('delete_source_title'),
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                              ),
                              subtitle: Text(
                                AppStrings.t('delete_source_subtitle'),
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              value: _deleteSourceAfter,
                              onChanged: _busy ? null : _toggleDeleteSource,
                            ),
                          ],
                        ),
                      ),
                    ),

                    if (hasSuccessfulJobs && !_busy) ...[
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _saveAllOutputs,
                        icon: const Icon(Icons.save_alt),
                        label: Text(_outputDirChoice != null
                            ? AppStrings.t('save_all_chosen_dir')
                            : AppStrings.t('save_all_one_by_one')),
                      ),
                    ],

                    if (_busy) ...[
                      const SizedBox(height: 16),
                      Card(
                        color: theme.colorScheme.primaryContainer.withAlpha(40),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      '${AppStrings.t('processing_prefix')}${_currentFileName ?? ''}',
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    AppStrings.progressCounter(_jobIndex + 1, _jobTotal),
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${_progress.toInt()}%',
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(value: _progress / 100, minHeight: 6),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // ── دکمه‌های اقدام پایین صفحه ─────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(10),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: AnimatedBuilder(
                animation: _tabController,
                builder: (context, _) {
                  final isEncryptTab = _tabController.index == 0;
                  return SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: isEncryptTab
                            ? theme.colorScheme.primary
                            : (theme.brightness == Brightness.dark
                            ? const Color(0xFFA6E3A1)
                            : Colors.green.shade700),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _busy
                          ? null
                          : () => _runBatch(encrypt: isEncryptTab),
                      icon: Icon(isEncryptTab ? Icons.lock_outline : Icons.lock_open_outlined),
                      label: Text(
                        isEncryptTab
                            ? AppStrings.t('encrypt_button')
                            : AppStrings.t('decrypt_button'),
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        ),
      ),
    ),
    );
  }
}