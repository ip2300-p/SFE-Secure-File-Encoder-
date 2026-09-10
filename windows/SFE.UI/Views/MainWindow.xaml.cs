using System.Windows;
using System.Windows.Controls;
using SFE.UI.ViewModels;

namespace SFE.UI.Views;

public partial class MainWindow : Window
{
    private readonly MainViewModel _vm;
    private bool _isPasswordVisible = false;

    public MainWindow()
    {
        InitializeComponent();
        TitleBarHelper.UseDarkTitleBar(this);
        _vm = new MainViewModel();
        DataContext = _vm;
        _vm.ClearPasswordBoxRequested += () =>
        {
            TxtPassword.Clear();
            TxtPasswordVisible.Clear();
            TxtSecondPassword.Clear();
        };
    }

    private void PasswordBox_PasswordChanged(object sender, RoutedEventArgs e)
    {
        if (DataContext is MainViewModel vm && !_isPasswordVisible && sender is PasswordBox pb)
        {
            vm.Password = pb.Password;
        }
    }

    private void TogglePasswordVisibility_Click(object sender, RoutedEventArgs e)
    {
        if (DataContext is not MainViewModel vm) return;
        _isPasswordVisible = !_isPasswordVisible;
        if (_isPasswordVisible)
        {
            TxtPasswordVisible.Text = TxtPassword.Password;
            TxtPassword.Visibility = Visibility.Collapsed;
            TxtPasswordVisible.Visibility = Visibility.Visible;
            TxtPasswordVisible.TextChanged += VisiblePassword_TextChanged;
        }
        else
        {
            TxtPasswordVisible.TextChanged -= VisiblePassword_TextChanged;
            TxtPassword.Password = TxtPasswordVisible.Text;
            TxtPasswordVisible.Visibility = Visibility.Collapsed;
            TxtPassword.Visibility = Visibility.Visible;
        }
    }

    private void VisiblePassword_TextChanged(object sender, TextChangedEventArgs e)
    {
        if (DataContext is MainViewModel vm && _isPasswordVisible)
        {
            vm.Password = TxtPasswordVisible.Text;
        }
    }

    private void TxtSecondPassword_PasswordChanged(object sender, RoutedEventArgs e)
    {
        if (DataContext is MainViewModel vm && sender is PasswordBox pb)
        {
            vm.SecondPassword = pb.Password;
        }
    }

    private void DropArea_Drop(object sender, DragEventArgs e)
    {
        if (e.Data.GetDataPresent(DataFormats.FileDrop))
        {
            string[] files = (string[])e.Data.GetData(DataFormats.FileDrop);
            _vm.AddDroppedPaths(files);
            e.Handled = true;
        }
    }

    private void RemoveFile_Click(object sender, RoutedEventArgs e)
    {
        if (sender is Button btn && btn.DataContext is string filePath)
        {
            _vm.SelectedPaths.Remove(filePath);
            _vm.UpdatePathsDisplay();
        }
    }
}