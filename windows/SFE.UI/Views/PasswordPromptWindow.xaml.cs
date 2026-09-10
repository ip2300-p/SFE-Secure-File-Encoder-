using SFE.Core.Models;
using System.Windows;
using System.Windows.Controls;

namespace SFE.UI.Views;

public partial class PasswordPromptWindow : Window
{
    public string Password { get; private set; } = "";
    private readonly bool _useSecondPassword;
    private bool _pwdVisible = false;
    private bool _secondPwdVisible = false;

    public PasswordPromptWindow(Scenario scenario)
    {
        InitializeComponent();
        TitleBarHelper.UseDarkTitleBar(this);
        _useSecondPassword = scenario.UseSecondaryPassword;
        ScenarioNameText.Text = $"{LocalizationService.Get("ScenarioPrefix")} {scenario.Name}";
        if (_useSecondPassword)
            SecondPwdPanel.Visibility = Visibility.Visible;
    }

    private void TogglePwd_Click(object sender, RoutedEventArgs e)
    {
        _pwdVisible = !_pwdVisible;
        if (_pwdVisible)
        {
            PwdBoxVisible.Text = PwdBox.Password;
            PwdBox.Visibility = Visibility.Collapsed;
            PwdBoxVisible.Visibility = Visibility.Visible;
        }
        else
        {
            PwdBox.Password = PwdBoxVisible.Text;
            PwdBoxVisible.Visibility = Visibility.Collapsed;
            PwdBox.Visibility = Visibility.Visible;
        }
    }

    private void ToggleSecondPwd_Click(object sender, RoutedEventArgs e)
    {
        _secondPwdVisible = !_secondPwdVisible;
        if (_secondPwdVisible)
        {
            SecondPwdBoxVisible.Text = SecondPwdBox.Password;
            SecondPwdBox.Visibility = Visibility.Collapsed;
            SecondPwdBoxVisible.Visibility = Visibility.Visible;
        }
        else
        {
            SecondPwdBox.Password = SecondPwdBoxVisible.Text;
            SecondPwdBoxVisible.Visibility = Visibility.Collapsed;
            SecondPwdBox.Visibility = Visibility.Visible;
        }
    }

    private string GetMainPassword()   => _pwdVisible ? PwdBoxVisible.Text : PwdBox.Password;
    private string GetSecondPassword() => _secondPwdVisible ? SecondPwdBoxVisible.Text : SecondPwdBox.Password;

    private void RunBtn_Click(object sender, RoutedEventArgs e)
    {
        if (string.IsNullOrWhiteSpace(GetMainPassword()))
        {
            MessageBox.Show(LocalizationService.Get("WarnEnterPassword"),
                LocalizationService.Get("Error"), MessageBoxButton.OK, MessageBoxImage.Warning);
            return;
        }
        if (_useSecondPassword && string.IsNullOrWhiteSpace(GetSecondPassword()))
        {
            MessageBox.Show(LocalizationService.Get("WarnEnterSecondPassword"),
                LocalizationService.Get("Error"), MessageBoxButton.OK, MessageBoxImage.Warning);
            return;
        }
        Password = _useSecondPassword
            ? GetMainPassword() + "||" + GetSecondPassword()
            : GetMainPassword();
        DialogResult = true;
    }

    private void CancelBtn_Click(object sender, RoutedEventArgs e)
    {
        DialogResult = false;
    }
}