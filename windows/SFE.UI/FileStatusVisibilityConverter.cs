using System;
using System.Globalization;
using System.Windows;
using System.Windows.Data;
using SFE.UI.ViewModels;

namespace SFE.UI;

public class FileStatusVisibilityConverter : IMultiValueConverter
{
    public object Convert(object[] values, Type targetType, object parameter, CultureInfo culture)
    {
        if (values == null || values.Length < 3) return Visibility.Collapsed;
        if (values[0] is not string path) return Visibility.Collapsed;
        if (values[2] is not MainViewModel vm) return Visibility.Collapsed;
        var want = parameter as string ?? "";
        var status = vm.GetFileStatus(path);
        string key = status switch
        {
            FileItemStatus.Done       => "Check",
            FileItemStatus.Failed     => "Cross",
            FileItemStatus.Processing => "Clock",
            _                         => vm.IsBusy ? "Clock" : "Trash"
        };
        return key == want ? Visibility.Visible : Visibility.Collapsed;
    }

    public object[] ConvertBack(object value, Type[] targetTypes, object parameter, CultureInfo culture)
        => throw new NotSupportedException();
}