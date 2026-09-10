using SFE.Core.Models;
using SFE.Services;
using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.ComponentModel;
using System.IO;
using System.Linq;
using System.Runtime.CompilerServices;
using System.Threading;
using System.Threading.Tasks;
using System.Windows;
using System.Windows.Input;
using System.Windows.Media;

namespace SFE.UI.ViewModels;

public enum OperationMode { Encrypt, Decrypt }
public enum FileItemStatus { Pending, Processing, Done, Failed }

public class MainViewModel : INotifyPropertyChanged
{
    private readonly FileProcessor   _fileProcessor  = new();
    private readonly LoggingService  _loggingService = new();
    private CancellationTokenSource? _cts;
    private List<string> _lastDecryptedSourceFiles   = new();

    public AppSettings Settings { get; private set; } = AppSettings.Load();

    // ── حالت: هر حالت state جداگانه داره ──────────────
    private readonly ObservableCollection<string> _encryptPaths = new();
    private readonly ObservableCollection<string> _decryptPaths = new();
    private string _encryptOutput = "";
    private string _decryptOutput = "";

    private OperationMode _mode = OperationMode.Encrypt;
    public OperationMode Mode
    {
        get => _mode;
        set
        {
            _mode = value;
            OnPropertyChanged();
            OnPropertyChanged(nameof(IsEncryptMode));
            OnPropertyChanged(nameof(IsDecryptMode));
            OnPropertyChanged(nameof(ActionButtonText));
            OnPropertyChanged(nameof(SelectedPaths));
            OnPropertyChanged(nameof(OutputDirectory));
            OnPropertyChanged(nameof(ActiveAccentColor));
            OnPropertyChanged(nameof(ActiveCardHeader));
            UpdatePathsDisplay();
        }
    }

    public bool IsEncryptMode => Mode == OperationMode.Encrypt;
    public bool IsDecryptMode => Mode == OperationMode.Decrypt;
    
    public string ActionButtonText => Mode == OperationMode.Encrypt
        ? LocalizationService.Get("ModeEncrypt")
        : LocalizationService.Get("ModeDecrypt");

    // رنگ‌های پویا و عناوین کارت بر اساس مود عملیاتی و زبان
    public string ActiveAccentColor => IsEncryptMode ? "#89B4FA" : "#A6E3A1";
    
    public string ActiveCardHeader => IsEncryptMode 
        ? $"🔒 {LocalizationService.Get("ModeEncrypt")}" 
        : $"🔓 {LocalizationService.Get("ModeDecrypt")}";

    // ── Paths ─────────────────────────────────────────
    public ObservableCollection<string> SelectedPaths =>
        Mode == OperationMode.Encrypt ? _encryptPaths : _decryptPaths;

    public string OutputDirectory
    {
        get => Mode == OperationMode.Encrypt ? _encryptOutput : _decryptOutput;
        set
        {
            if (Mode == OperationMode.Encrypt) _encryptOutput = value;
            else                               _decryptOutput = value;
            OnPropertyChanged();
        }
    }

    private string _selectedPathsDisplay = "";
    public string SelectedPathsDisplay
    {
        get => string.IsNullOrEmpty(_selectedPathsDisplay) ? LocalizationService.Get("DropHere") : _selectedPathsDisplay;
        set { _selectedPathsDisplay = value; OnPropertyChanged(); }
    }

    public string FileCountText
    {
        get
        {
            if (_showRunCounter && _totalFiles > 0)
                return $"({_processedFiles}/{_totalFiles})";
            return SelectedPaths.Count == 0 ? "" : $"({SelectedPaths.Count})";
        }
    }

    public void UpdatePathsDisplay()
    {
        var paths = SelectedPaths;
        SelectedPathsDisplay = paths.Count == 0
            ? LocalizationService.Get("DropHere")
            : paths.Count == 1
                ? paths[0]
                : $"{paths.Count} {LocalizationService.Get("FilesSelected")}";
            _showRunCounter = false;
        OnPropertyChanged(nameof(FileCountText));
    }

    public void AddDroppedPaths(string[] paths)
    {
        var resolvedFilters = Settings.GetResolvedFilter();

        foreach (var p in paths)
        {
            if (File.Exists(p) && Mode == OperationMode.Encrypt && resolvedFilters != null && resolvedFilters.Length > 0)
            {
                var ext = Path.GetExtension(p).ToLowerInvariant();
                if (!resolvedFilters.Contains(ext)) continue;
            }

            if (!SelectedPaths.Contains(p)) SelectedPaths.Add(p);
        }
        UpdatePathsDisplay();
    }

    // ── Password ──────────────────────────────────────
    private string _password = "";
    public string Password
    {
        get => _password;
        set
        {
            _password = value;
            OnPropertyChanged();
            OnPropertyChanged(nameof(PasswordStrength));
            OnPropertyChanged(nameof(PasswordStrengthText));
            OnPropertyChanged(nameof(PasswordStrengthBrush));
        }
    }

    private string _secondPassword = "";
    public string SecondPassword
    {
        get => _secondPassword;
        set { _secondPassword = value; OnPropertyChanged(); }
    }

    public bool ShowSecondPassword => Settings.UseSecondaryPassword;

    public int PasswordStrength => CalcStrength(Password);
    
    public string PasswordStrengthText => PasswordStrength switch
    {
        0 => "", 
        1 => LocalizationService.Get("Weak"), 
        2 => LocalizationService.Get("Medium"),
        3 => LocalizationService.Get("Strong"), 
        _ => LocalizationService.Get("VeryStrong")
    };

    public Brush PasswordStrengthBrush => PasswordStrength switch
    {
        1 => new SolidColorBrush(Color.FromRgb(0xF3, 0x8B, 0xA8)),
        2 => new SolidColorBrush(Color.FromRgb(0xFA, 0xB3, 0x87)),
        3 => new SolidColorBrush(Color.FromRgb(0xA6, 0xE3, 0xA1)),
        _ => new SolidColorBrush(Color.FromRgb(0x89, 0xB4, 0xFA))
    };

    // ── Progress ──────────────────────────────────────
    private double _progressValue;
    public double ProgressValue
    {
        get => _progressValue;
        set { _progressValue = value; OnPropertyChanged(); }
    }

    private string _statusText = "";
    public string StatusText
    {
        get => string.IsNullOrEmpty(_statusText) ? LocalizationService.Get("Ready") : _statusText;
        set { _statusText = value; OnPropertyChanged(); }
    }

    private string _currentFile = "";
    public string CurrentFile
    {
        get => _currentFile;
        set { _currentFile = value; OnPropertyChanged(); }
    }

    private string _etaText = "";
    public string EtaText
    {
        get => _etaText;
        set { _etaText = value; OnPropertyChanged(); }
    }

    private string _speedText = "";
    public string SpeedText
    {
        get => _speedText;
        set { _speedText = value; OnPropertyChanged(); }
    }

    private bool _showOpenFolder;
    public bool ShowOpenFolder
    {
        get => _showOpenFolder;
        set { _showOpenFolder = value; OnPropertyChanged(); }
    }
    private bool _isBusy;
    public bool IsBusy
    {
        get => _isBusy;
        set { _isBusy = value; OnPropertyChanged(); IsIdle = !value; }
    }

    private bool _isIdle = true;
    public bool IsIdle
    {
        get => _isIdle;
        set { _isIdle = value; OnPropertyChanged(); }
    }

     // ── وضعیت هر فایل برای آیکون‌های لیست ──────────────
        private readonly Dictionary<string, FileItemStatus> _fileStatuses = new();
        private readonly Dictionary<string, int> _folderExpected = new();
        private readonly Dictionary<string, int> _folderDone = new();
        private readonly Dictionary<string, int> _folderFailed = new();
        private int _fileStatusVersion;
        public int FileStatusVersion => _fileStatusVersion;
        private int _processedFiles;
        private int _totalFiles;
        private bool _showRunCounter;
        public FileItemStatus GetFileStatus(string path) =>
            _fileStatuses.TryGetValue(path, out var s) ? s : FileItemStatus.Pending;
        private void SetFileStatus(string path, FileItemStatus s)
        {
            _fileStatuses[path] = s;
            _fileStatusVersion++;
            OnPropertyChanged(nameof(FileStatusVersion));
        }
         private void PrepareStatusTracking(EncryptionOptions options)
        {
            _fileStatuses.Clear();
            _folderExpected.Clear(); _folderDone.Clear(); _folderFailed.Clear();
            foreach (var item in SelectedPaths.ToList())
            {
                _fileStatuses[item] = FileItemStatus.Pending;
                if (Directory.Exists(item))
                {
                    var all = Directory.GetFiles(item, "*", SearchOption.AllDirectories);
                    int count;
                    if (Mode == OperationMode.Encrypt)
                    {
                        var filter = options.FileFilter;
                        count = (filter == null || filter.Length == 0)
                            ? all.Length
                            : all.Count(f => filter.Contains(Path.GetExtension(f).TrimStart('.').ToLower()));
                    }
                    else
                    {
                        count = all.Count(SFE.Core.FileFormat.SfeFileReader.IsSfeFile);
                    }
                    _folderExpected[item] = count;
                    _folderDone[item]     = 0;
                    _folderFailed[item]   = 0;
                }
            }
            _fileStatusVersion++;
            OnPropertyChanged(nameof(FileStatusVersion));
        }
            private void OnFileCompleted(string path, bool success)
            {
                if (SelectedPaths.Contains(path))
                {
                    SetFileStatus(path, success ? FileItemStatus.Done : FileItemStatus.Failed);
                    return;
                }
                var folder = SelectedPaths.FirstOrDefault(d =>
                    path.StartsWith(d + "\\", StringComparison.OrdinalIgnoreCase));
                if (folder == null) return;
                if (_folderDone.ContainsKey(folder))
                {
                    _folderDone[folder]++;
                    if (!success) _folderFailed[folder]++;
                }
                if (GetFileStatus(folder) == FileItemStatus.Pending)
                    SetFileStatus(folder, FileItemStatus.Processing);
            }
            private void FinalizeStatuses()
            {
                foreach (var folder in _folderExpected.Keys.ToList())
                {
                    var failed = _folderFailed.TryGetValue(folder, out var f) ? f : 0;
                    var done   = _folderDone.TryGetValue(folder, out var d) ? d : 0;
                    if (failed > 0)                        SetFileStatus(folder, FileItemStatus.Failed);
                    else if (done >= _folderExpected[folder]) SetFileStatus(folder, FileItemStatus.Done);
                    else                                   SetFileStatus(folder, FileItemStatus.Pending);
                }
            }

    public ObservableCollection<string> LogMessages { get; } = new();

    public event Action? ClearPasswordBoxRequested;

    // ── Commands ──────────────────────────────────────
    public ICommand SetEncryptModeCommand  => new RelayCommand(_ => Mode = OperationMode.Encrypt);
    public ICommand SetDecryptModeCommand  => new RelayCommand(_ => Mode = OperationMode.Decrypt);
    public ICommand SelectFilesCommand     => new RelayCommand(_ => SelectFiles(),  _ => IsIdle);
    public ICommand SelectFolderCommand    => new RelayCommand(_ => SelectFolder(), _ => IsIdle);
    public ICommand SelectOutputCommand    => new RelayCommand(_ => SelectOutput(), _ => IsIdle);
    public ICommand ClearFilesCommand      => new RelayCommand(_ => { SelectedPaths.Clear(); UpdatePathsDisplay(); }, _ => IsIdle);
    public ICommand ClearLogCommand        => new RelayCommand(_ => LogMessages.Clear());
    public ICommand ExecuteCommand         => new RelayCommand(async _ => await ExecuteAsync(), _ => IsIdle);
    public ICommand CancelCommand          => new RelayCommand(_ => Cancel(), _ => IsBusy);
    public ICommand OpenSettingsCommand    => new RelayCommand(_ => OpenSettings());
    public ICommand OpenScenariosCommand   => new RelayCommand(_ => OpenScenarios());
    public ICommand OpenOutputFolderCommand => new RelayCommand(_ =>
    {
        try
        {
            if (!string.IsNullOrWhiteSpace(OutputDirectory) && System.IO.Directory.Exists(OutputDirectory))
                System.Diagnostics.Process.Start("explorer.exe", OutputDirectory);
        }
        catch { }
    });

    // ── Methods ───────────────────────────────────────
    private void SelectFiles()
    {
        var dialog = new Microsoft.Win32.OpenFileDialog
        {
            Title       = Mode == OperationMode.Decrypt
                            ? LocalizationService.Get("ModeDecrypt") 
                            : LocalizationService.Get("SelectFile"),
            Multiselect = true,
            Filter      = Mode == OperationMode.Decrypt
                            ? "SFE Files|*.sfe;*.tmp;*.bin|All Files|*.*"
                            : "All Files|*.*"
        };
        if (dialog.ShowDialog() == true)
        {
            foreach (var f in dialog.FileNames)
                if (!SelectedPaths.Contains(f)) SelectedPaths.Add(f);
            UpdatePathsDisplay();
        }
    }

    private void SelectFolder()
    {
        var dialog = new Microsoft.Win32.OpenFolderDialog 
        { 
            Title = LocalizationService.Get("SelectFolder") 
        };
        if (dialog.ShowDialog() == true)
        {
            if (!SelectedPaths.Contains(dialog.FolderName))
                SelectedPaths.Add(dialog.FolderName);
            UpdatePathsDisplay();
        }
    }

    private void SelectOutput()
    {
        var dialog = new Microsoft.Win32.OpenFolderDialog
        { 
            Title = LocalizationService.Get("OutputFolder") 
        };
        if (dialog.ShowDialog() == true) OutputDirectory = dialog.FolderName;
    }

    private async Task ExecuteAsync()
    {
        if (SelectedPaths.Count == 0)
            { LogMessages.Add(LocalizationService.Get("WarnSelectPath")); return; }
        if (string.IsNullOrWhiteSpace(Password))
            { LogMessages.Add(LocalizationService.Get("WarnPassword")); return; }
        if (Settings.UseSecondaryPassword && string.IsNullOrWhiteSpace(SecondPassword))
            { LogMessages.Add(LocalizationService.Get("WarnSecondPassword")); return; }
        if (string.IsNullOrWhiteSpace(OutputDirectory))
            { LogMessages.Add(LocalizationService.Get("WarnOutput")); return; }

        var effectivePassword = Settings.UseSecondaryPassword
            ? Password + "||" + SecondPassword : Password;

        var options = new EncryptionOptions
        {
            RandomizeFilename          = Settings.RandomizeFilename,
            NameStyle                  = Settings.NameStyle,
            DeleteOriginalAfterEncrypt = Settings.DeleteOriginalAfterEncrypt,
            SecureDelete               = Settings.SecureDelete,
            FileFilter                 = Settings.GetResolvedFilter(),
            ChunkSize                  = Settings.ChunkSize,
            CreateBackup               = Settings.CreateBackup,
            BackupPath                 = Settings.BackupPath
        };

        await ExecuteWithOptionsAsync(effectivePassword, options);
    }

    private async Task ExecuteWithOptionsAsync(string password, EncryptionOptions options)
    {
        IsBusy = true;
        _cts   = new CancellationTokenSource();
             ProgressValue = 0; EtaText = ""; SpeedText = "";
            ShowOpenFolder = false;
                _processedFiles = 0; _totalFiles = 0;
                _showRunCounter = true;
                PrepareStatusTracking(options);
                OnPropertyChanged(nameof(FileCountText));
        LogMessages.Clear();
        _lastDecryptedSourceFiles.Clear();

                var progress = new Progress<ProgressInfo>(info =>
    {
        if (info.TotalFiles > 0) ProgressValue = info.Percentage;
            StatusText      = info.Status;
            CurrentFile     = info.CurrentFile;
            _processedFiles = info.ProcessedFiles;
            _totalFiles     = info.TotalFiles;
            OnPropertyChanged(nameof(FileCountText));
                        if (info.CompletedPath != null && info.CompletedSuccess.HasValue)
                        OnFileCompleted(info.CompletedPath, info.CompletedSuccess.Value);
            if (info.BytesPerSecond > 0)
                SpeedText = FormatSpeed(info.BytesPerSecond);
            if (info.TimeRemaining.HasValue)
                EtaText = $"⏱ {FormatETA(info.TimeRemaining.Value)}";
        });

        try
        {
            var paths = SelectedPaths.ToList();
            List<OperationResult> results;

            if (Mode == OperationMode.Encrypt)
                results = await _fileProcessor.EncryptPathsAsync(
                    paths, OutputDirectory, password, options, progress, _cts.Token);
            else
            {
                _lastDecryptedSourceFiles = paths;
                results = await _fileProcessor.DecryptPathsAsync(
                paths, OutputDirectory, password, progress, _cts.Token);
            }

            _loggingService.LogResults(Mode.ToString(), results);
            foreach (var r in results)
                LogMessages.Add(r.Success
                    ? $"✅ {Path.GetFileName(r.FilePath)}"
                    : $"❌ {r.ErrorMessage}");

            int s = results.Count(r => r.Success);
            int f = results.Count(r => !r.Success);
            StatusText = $"{LocalizationService.Get("Done")} — {s} {LocalizationService.Get("Successful")}، {f} {LocalizationService.Get("Failed")}";
                EtaText = ""; SpeedText = "";
                    ShowOpenFolder = s > 0;
                    FinalizeStatuses();
                    Password       = "";
                    SecondPassword = "";
                    CurrentFile    = "";
                    ClearPasswordBoxRequested?.Invoke();

            if (Mode == OperationMode.Decrypt && s > 0)
                AskDeleteSourceFiles();
        }
        catch (Exception ex)
        {
            LogMessages.Add($"❌ {ex.Message}");
            StatusText = LocalizationService.Get("ErrorOccurred");
        }
        finally { IsBusy = false; ProgressValue = 100; }
    }

    public void OpenScenarios()
    {
        var win = new SFE.UI.Views.ScenariosWindow(RunScenario)
        {
            Owner = Application.Current.MainWindow
        };
        win.ShowDialog();
    }

    private async void RunScenario(Scenario scenario, string password)
    {
        Mode = scenario.Mode == "Decrypt"
            ? OperationMode.Decrypt : OperationMode.Encrypt;

        SelectedPaths.Clear();
        foreach (var p in scenario.SourcePaths)
            SelectedPaths.Add(p);
        UpdatePathsDisplay();

        OutputDirectory = scenario.OutputDirectory;

        var options = new EncryptionOptions
        {
            RandomizeFilename          = scenario.RandomizeFilename,
            NameStyle                  = scenario.NameStyle,
            DeleteOriginalAfterEncrypt = scenario.DeleteOriginalAfterEncrypt,
            SecureDelete               = scenario.SecureDelete,
            CreateBackup               = scenario.CreateBackup,
            BackupPath                 = scenario.BackupPath,
            ChunkSize                  = Settings.ChunkSize,
            FileFilter                 = scenario.FilterPreset == FileFilterPreset.Custom
                ? scenario.CustomFileFilter
                    .Split(',')
                    .Select(s => s.Trim().ToLower())
                    .Where(s => !string.IsNullOrEmpty(s))
                    .ToArray()
                : new AppSettings
                    { FilterPreset = scenario.FilterPreset }.GetResolvedFilter()
        };

        await ExecuteWithOptionsAsync(password, options);
    }

    private void ClearInputFields()
    {
        SelectedPaths.Clear();
        UpdatePathsDisplay();
        Password       = "";
        SecondPassword = "";
        CurrentFile    = "";
        ClearPasswordBoxRequested?.Invoke();
    }

    private void AskDeleteSourceFiles()
    {
        var result = MessageBox.Show(
            LocalizationService.Get("AfterDecryptMsg"),
            LocalizationService.Get("Done"),
            MessageBoxButton.YesNo,
            MessageBoxImage.Question);

        if (result == MessageBoxResult.Yes)
        {
            int deleted = 0;
            foreach (var path in _lastDecryptedSourceFiles)
            {
                try
                {
                    if (File.Exists(path)) { File.Delete(path); deleted++; }
                    else if (Directory.Exists(path))
                    {
                        var sfeFiles = Directory
                            .GetFiles(path, "*", SearchOption.AllDirectories)
                            .Where(SFE.Core.FileFormat.SfeFileReader.IsSfeFile);
                        foreach (var f in sfeFiles) { File.Delete(f); deleted++; }
                    }
                }
                catch { }
            }
            LogMessages.Add($"🗑️ {deleted} {LocalizationService.Get("DeletedFiles")}");
        }
    }

    private void Cancel()
    {
        _cts?.Cancel();
        StatusText = LocalizationService.Get("Cancelling");
    }

    public void OpenSettings()
    {
        var mainWindow = Application.Current.Windows
            .OfType<SFE.UI.Views.MainWindow>()
            .FirstOrDefault();

        var win = new SFE.UI.Views.SettingsWindow(Settings)
        {
            Owner = mainWindow
        };
        
        if (win.ShowDialog() == true)
        {
            Settings.Save();
            RefreshAllStrings();
        }
    }

    private void RefreshAllStrings()
    {
        Settings = AppSettings.Load();

        OnPropertyChanged(nameof(Settings));
        OnPropertyChanged(nameof(ShowSecondPassword));
        OnPropertyChanged(nameof(ActionButtonText));
        OnPropertyChanged(nameof(PasswordStrengthText));
        OnPropertyChanged(nameof(ActiveCardHeader));
        OnPropertyChanged(nameof(ActiveAccentColor));
        
        StatusText = LocalizationService.Get("Ready");
        UpdatePathsDisplay();
        LangProvider.Instance.Refresh();
    }

    private static int CalcStrength(string p)
    {
        if (string.IsNullOrEmpty(p)) return 0;
        int s = 0;
        if (p.Length >= 8)  s++;
        if (p.Length >= 12) s++;
        if (p.Any(char.IsUpper) && p.Any(char.IsLower)) s++;
        if (p.Any(char.IsDigit)) s++;
        if (p.Any(c => !char.IsLetterOrDigit(c))) s++;
        return Math.Min(s, 4);
    }

    private static string FormatSpeed(double bps) =>
        bps >= 1048576 ? $"{bps / 1048576:F1} MB/s" : $"{bps / 1024:F0} KB/s";

    private static string FormatETA(TimeSpan t) =>
        t.TotalHours   >= 1 ? $"{(int)t.TotalHours}h {t.Minutes}m" :
        t.TotalMinutes >= 1 ? $"{(int)t.TotalMinutes}m {t.Seconds}s" :
        $"{(int)t.TotalSeconds}s";

    public event PropertyChangedEventHandler? PropertyChanged;
    protected void OnPropertyChanged([CallerMemberName] string? name = null)
        => PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(name));
}

public class RelayCommand : ICommand
{
    private readonly Action<object?> _execute;
    private readonly Func<object?, bool>? _canExecute;
    public RelayCommand(Action<object?> execute, Func<object?, bool>? canExecute = null)
    { _execute = execute; _canExecute = canExecute; }
    public bool CanExecute(object? p) => _canExecute?.Invoke(p) ?? true;
    public void Execute(object? p) => _execute(p);
    public event EventHandler? CanExecuteChanged
    {
        add    => CommandManager.RequerySuggested += value;
        remove => CommandManager.RequerySuggested -= value;
    }
}