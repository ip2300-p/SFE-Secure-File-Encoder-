using SFE.Core.Models;
using SFE.Services;
using System.Windows;
using System.Windows.Controls;

namespace SFE.UI.Views;

public partial class SettingsWindow : Window
{
    private readonly AppSettings _settings;

    public SettingsWindow(AppSettings settings)
    {
        InitializeComponent();
        TitleBarHelper.UseDarkTitleBar(this);
        _settings = settings;
        LoadSettings();
        WireCheckboxLogic();
        FlowDirection = _settings.Language == "fa" ? FlowDirection.RightToLeft : FlowDirection.LeftToRight;
    }

    private void LoadSettings()
    {
        LanguageCombo.SelectedIndex   = _settings.Language == "en" ? 1 : 0;
        RandomizeCheck.IsChecked      = _settings.RandomizeFilename;
        NameStyleCombo.SelectedIndex  = (int)_settings.NameStyle;
        DeleteOriginalCheck.IsChecked = _settings.DeleteOriginalAfterEncrypt;
        SecureDeleteCheck.IsChecked   = _settings.SecureDelete;
        CreateBackupCheck.IsChecked   = _settings.CreateBackup;
        BackupPathBox.Text            = _settings.BackupPath ?? "";
        SecondPasswordCheck.IsChecked = _settings.UseSecondaryPassword;
        DeleteOriginalCheck.IsEnabled = !_settings.SecureDelete;
        VersionText.Text = "v" + (System.Reflection.Assembly.GetExecutingAssembly()
        .GetName().Version?.ToString() ?? "1.0.0");

        FilterPresetCombo.SelectedIndex = (int)_settings.FilterPreset;
        CustomFilterBox.Text            = _settings.CustomFileFilter ?? "";

        if (_settings.FilterPreset == FileFilterPreset.Custom)
        {
            CustomFilterBox.Visibility  = Visibility.Visible;
            CustomFilterHint.Visibility = Visibility.Visible;
        }
    }

   private bool _prevDeleteOriginal; // متغیر جدید

private void WireCheckboxLogic()
{
    SecureDeleteCheck.Checked += (s, e) =>
    {
        _prevDeleteOriginal = DeleteOriginalCheck.IsChecked == true;
        DeleteOriginalCheck.IsChecked = false;
        DeleteOriginalCheck.IsEnabled = false;
    };
    SecureDeleteCheck.Unchecked += (s, e) =>
    {
        DeleteOriginalCheck.IsEnabled = true;
        DeleteOriginalCheck.IsChecked = _prevDeleteOriginal;
    };
}

    private void FilterPresetCombo_SelectionChanged(object sender, SelectionChangedEventArgs e)
    {
        if (CustomFilterBox == null) return;
        var isCustom = FilterPresetCombo.SelectedIndex == 4;
        CustomFilterBox.Visibility  = isCustom ? Visibility.Visible : Visibility.Collapsed;
        CustomFilterHint.Visibility = isCustom ? Visibility.Visible : Visibility.Collapsed;
    }

    private void SelectBackupPath_Click(object sender, RoutedEventArgs e)
    {
        var dialog = new Microsoft.Win32.OpenFolderDialog { Title = LocalizationService.Get("SelectBackupFolder") };
        if (dialog.ShowDialog() == true)
            BackupPathBox.Text = dialog.FolderName;
    }

    private void SaveButton_Click(object sender, RoutedEventArgs e)
    {
        _settings.Language                   = LanguageCombo.SelectedIndex == 1 ? "en" : "fa";
        _settings.RandomizeFilename          = RandomizeCheck.IsChecked == true;
        _settings.NameStyle                  = (DisguisedNameStyle)NameStyleCombo.SelectedIndex;
        _settings.DeleteOriginalAfterEncrypt = DeleteOriginalCheck.IsChecked == true;
        _settings.SecureDelete               = SecureDeleteCheck.IsChecked == true;
        _settings.CreateBackup               = CreateBackupCheck.IsChecked == true;
        _settings.BackupPath                 = BackupPathBox.Text.Trim();
        _settings.UseSecondaryPassword       = SecondPasswordCheck.IsChecked == true;
        _settings.FilterPreset               = (FileFilterPreset)FilterPresetCombo.SelectedIndex;
        _settings.CustomFileFilter           = CustomFilterBox.Text.Trim();

        _settings.Save();

        LocalizationService.Load(_settings.Language);
        FlowDirection = _settings.Language == "fa" ? FlowDirection.RightToLeft : FlowDirection.LeftToRight;
        LangProvider.Instance.Refresh();

        // ست کردن DialogResult جهت اطلاع به MainViewModel برای آپدیت UI
        DialogResult = true;
        Close();
    }

    private void CopyVersion_Click(object sender, RoutedEventArgs e)
{
    try
    {
        var version = System.Reflection.Assembly.GetExecutingAssembly()
            .GetName().Version?.ToString() ?? "1.0.0";
        System.Windows.Clipboard.SetText($"Secure File Encoder v{version}");
        MessageBox.Show(
            LocalizationService.Get("VersionCopied"),
            LocalizationService.Get("Successful"),
            MessageBoxButton.OK, MessageBoxImage.Information);
    }
    catch { }
}
private void OpenGitHub_Click(object sender, RoutedEventArgs e)
{
    try
    {
        System.Diagnostics.Process.Start(new System.Diagnostics.ProcessStartInfo
        {
            FileName = "https://github.com/ip2300-p/SFE-Secure-File-Encoder-",
            UseShellExecute = true
        });
    }
    catch { }
}
}