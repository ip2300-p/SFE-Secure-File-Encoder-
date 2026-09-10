using System;
using System.Windows;
using SFE.UI.Views;
using SFE.Core.Models;
using SFE.Services;

namespace SFE.UI;

public partial class App : Application
{
    public App()
    {
        AppDomain.CurrentDomain.UnhandledException += (s, e) =>
        {
            LogAndShowException(e.ExceptionObject as Exception);
        };

        DispatcherUnhandledException += (s, e) =>
        {
            LogAndShowException(e.Exception);
            e.Handled = true;
        };
    }

    protected override void OnStartup(StartupEventArgs e)
{
    base.OnStartup(e);
    try
    {
        var settings = AppSettings.Load();
        LocalizationService.Load(settings.Language);
        MainWindow mainWindow = new MainWindow();
        mainWindow.Show();
    }
        catch (Exception ex)
        {
            LogAndShowException(ex);
            Shutdown();
        }
    }

    private static void LogAndShowException(Exception? ex)
    {
        if (ex == null) return;
        
        string fullError = $"[SFE CRASH REPORT]\n" +
                          $"Message: {ex.Message}\n\n" +
                          $"InnerException: {ex.InnerException?.Message}\n\n" +
                          $"StackTrace:\n{ex.StackTrace}";
        
        Console.WriteLine(fullError);
        MessageBox.Show(fullError, "SFE Error Debugger", MessageBoxButton.OK, MessageBoxImage.Error);
    }
}
