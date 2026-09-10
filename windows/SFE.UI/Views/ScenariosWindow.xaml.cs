using SFE.Core.Models;
using SFE.Services;
using System.Windows;
using System.Windows.Controls;

namespace SFE.UI.Views;

public partial class ScenariosWindow : Window
{
    private readonly ScenarioService _scenarioService = new();
    private readonly Action<Scenario, string>? _onRun;
    private Scenario? _currentScenario;

    public ScenariosWindow(Action<Scenario, string>? onRun = null)
    {
        InitializeComponent();
        TitleBarHelper.UseDarkTitleBar(this);
        FlowDirection = LocalizationService.Get("IsRTL") == "True" ? FlowDirection.RightToLeft : FlowDirection.LeftToRight;
        _onRun = onRun;
        LoadList();
    }

    private void LoadList()
    {
        ScenarioList.ItemsSource = null;
        ScenarioList.ItemsSource = _scenarioService.GetAll();
    }

    private void ScenarioList_SelectionChanged(object sender, SelectionChangedEventArgs e)
    {
        if (ScenarioList.SelectedItem is Scenario scenario)
        {
            _currentScenario  = scenario;
            LoadToEditor(scenario);
            SaveBtn.IsEnabled = true;
            RunBtn.IsEnabled  = true;
            EditorTitle.Text  = $"{LocalizationService.Get("Editing")} {scenario.Name}";
        }
    }

    private void LoadToEditor(Scenario s)
    {
        NameBox.Text                  = s.Name;
        ModeCombo.SelectedIndex       = s.Mode == "Decrypt" ? 1 : 0;
        OutputBox.Text                = s.OutputDirectory;
        RandomizeCheck.IsChecked      = s.RandomizeFilename;
        NameStyleCombo.SelectedIndex  = (int)s.NameStyle;
        DeleteOriginalCheck.IsChecked = s.DeleteOriginalAfterEncrypt;
        SecureDeleteCheck.IsChecked   = s.SecureDelete;
        CreateBackupCheck.IsChecked   = s.CreateBackup;
        BackupPathBox.Text            = s.BackupPath;
        SecondPasswordCheck.IsChecked = s.UseSecondaryPassword;
        FilterPresetCombo.SelectedIndex = (int)s.FilterPreset;
        CustomFilterBox.Text          = s.CustomFileFilter;
        CustomFilterBox.Visibility    = s.FilterPreset == FileFilterPreset.Custom
            ? Visibility.Visible : Visibility.Collapsed;

        SourcePathsList.ItemsSource = null;
        SourcePathsList.ItemsSource = s.SourcePaths.ToList();
    }

    private void NewScenario_Click(object sender, RoutedEventArgs e)
    {
        _currentScenario = new Scenario
            { Name = LocalizationService.Get("ScenarioName") };
        LoadToEditor(_currentScenario);
        SaveBtn.IsEnabled         = true;
        RunBtn.IsEnabled          = false;
        EditorTitle.Text          = LocalizationService.Get("SelectOrCreate");
        ScenarioList.SelectedItem = null;
    }

    private void DeleteScenario_Click(object sender, RoutedEventArgs e)
    {
        if (ScenarioList.SelectedItem is not Scenario scenario) return;

        var result = MessageBox.Show(
            $"{LocalizationService.Get("ConfirmDeleteMsg")} «{scenario.Name}»",
            LocalizationService.Get("ConfirmDelete"),
            MessageBoxButton.YesNo,
            MessageBoxImage.Question);

        if (result == MessageBoxResult.Yes)
        {
            _scenarioService.Delete(scenario.Id);
            _currentScenario  = null;
            SaveBtn.IsEnabled = false;
            RunBtn.IsEnabled  = false;
            EditorTitle.Text  = LocalizationService.Get("SelectOrCreate");
            LoadList();
        }
    }

    private void AddFile_Click(object sender, RoutedEventArgs e)
    {
        var dialog = new Microsoft.Win32.OpenFileDialog
            { Multiselect = true, Filter = "All Files|*.*" };
        if (dialog.ShowDialog() == true)
        {
            var current = SourcePathsList.ItemsSource as List<string> ?? new();
            foreach (var f in dialog.FileNames)
                if (!current.Contains(f)) current.Add(f);
            SourcePathsList.ItemsSource = null;
            SourcePathsList.ItemsSource = current;
        }
    }

    private void AddFolder_Click(object sender, RoutedEventArgs e)
    {
        var dialog = new Microsoft.Win32.OpenFolderDialog();
        if (dialog.ShowDialog() == true)
        {
            var current = SourcePathsList.ItemsSource as List<string> ?? new();
            if (!current.Contains(dialog.FolderName))
                current.Add(dialog.FolderName);
            SourcePathsList.ItemsSource = null;
            SourcePathsList.ItemsSource = current;
        }
    }

    private void RemovePath_Click(object sender, RoutedEventArgs e)
    {
        if (SourcePathsList.SelectedItem is string selected)
        {
            var current = (SourcePathsList.ItemsSource as List<string> ?? new()).ToList();
            current.Remove(selected);
            SourcePathsList.ItemsSource = null;
            SourcePathsList.ItemsSource = current;
        }
    }

    private void SelectOutput_Click(object sender, RoutedEventArgs e)
    {
        var dialog = new Microsoft.Win32.OpenFolderDialog
            { Title = LocalizationService.Get("OutputFolder") };
        if (dialog.ShowDialog() == true)
            OutputBox.Text = dialog.FolderName;
    }

    private void SelectBackup_Click(object sender, RoutedEventArgs e)
    {
        var dialog = new Microsoft.Win32.OpenFolderDialog
            { Title = LocalizationService.Get("BackupPath") };
        if (dialog.ShowDialog() == true)
            BackupPathBox.Text = dialog.FolderName;
    }

    private void FilterPreset_Changed(object sender, SelectionChangedEventArgs e)
    {
        if (CustomFilterBox == null) return;
        CustomFilterBox.Visibility = FilterPresetCombo.SelectedIndex == 4
            ? Visibility.Visible : Visibility.Collapsed;
    }

    private void SaveScenario_Click(object sender, RoutedEventArgs e)
{
    if (_currentScenario == null) return;

    // 1. بررسی نام سناریو
    if (string.IsNullOrWhiteSpace(NameBox.Text))
    {
        MessageBox.Show(LocalizationService.Get("EnterName"), LocalizationService.Get("Error"), MessageBoxButton.OK, MessageBoxImage.Warning);
        return;
    }

    // 2. بررسی لیست مسیرهای مبدا
    var sourceList = SourcePathsList.ItemsSource as List<string> ?? new List<string>();
    if (sourceList.Count == 0)
    {
        MessageBox.Show(LocalizationService.Get("EnterSourcePaths"), LocalizationService.Get("Error"), MessageBoxButton.OK, MessageBoxImage.Warning);
        return;
    }

    // 3. ذخیره‌سازی مقادیر
    _currentScenario.Name = NameBox.Text.Trim();
    _currentScenario.Mode = ModeCombo.SelectedIndex == 1 ? "Decrypt" : "Encrypt";
    _currentScenario.SourcePaths = sourceList;
    _currentScenario.OutputDirectory = OutputBox.Text.Trim();
    _currentScenario.RandomizeFilename = RandomizeCheck.IsChecked == true;
    _currentScenario.NameStyle = (DisguisedNameStyle)NameStyleCombo.SelectedIndex;
    _currentScenario.DeleteOriginalAfterEncrypt = DeleteOriginalCheck.IsChecked == true;
    _currentScenario.SecureDelete = SecureDeleteCheck.IsChecked == true;
    _currentScenario.CreateBackup = CreateBackupCheck.IsChecked == true;
    _currentScenario.BackupPath = BackupPathBox.Text.Trim();
    _currentScenario.UseSecondaryPassword = SecondPasswordCheck.IsChecked == true;
    _currentScenario.FilterPreset = (FileFilterPreset)FilterPresetCombo.SelectedIndex;
    _currentScenario.CustomFileFilter = CustomFilterBox.Text.Trim();

    _scenarioService.Save(_currentScenario);
    LoadList();
    RunBtn.IsEnabled = true;
    EditorTitle.Text = $"{LocalizationService.Get("Editing")} {_currentScenario.Name}";

    MessageBox.Show(
        LocalizationService.Get("ScenarioSaved"),
        LocalizationService.Get("Successful"),
        MessageBoxButton.OK,
        MessageBoxImage.Information);
}

    private void RunScenario_Click(object sender, RoutedEventArgs e)
    {
        if (_currentScenario == null) return;

        if (_currentScenario.SourcePaths.Count == 0)
        {
            MessageBox.Show(LocalizationService.Get("EnterSourcePaths"),
            LocalizationService.Get("Error"), MessageBoxButton.OK, MessageBoxImage.Warning);
            return;
        }

        if (string.IsNullOrWhiteSpace(_currentScenario.OutputDirectory))
        {
            MessageBox.Show(LocalizationService.Get("EnterOutput"),
            LocalizationService.Get("Error"), MessageBoxButton.OK, MessageBoxImage.Warning);
            return;
        }

        var pwdDialog = new PasswordPromptWindow(_currentScenario) { Owner = this };

        if (pwdDialog.ShowDialog() == true)
        {
            _scenarioService.UpdateLastRun(_currentScenario.Id);
            _onRun?.Invoke(_currentScenario, pwdDialog.Password);
            Close();
        }
    }
private void RemoveSinglePath_Click(object sender, RoutedEventArgs e)
{
    if (sender is Button btn && btn.DataContext is string path)
    {
        var current = SourcePathsList.ItemsSource as List<string> ?? new List<string>();
        if (current.Contains(path))
        {
            current.Remove(path);
            SourcePathsList.ItemsSource = null;
            SourcePathsList.ItemsSource = current;
        }
    }
}

}