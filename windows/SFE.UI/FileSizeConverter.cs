using System;
using System.Globalization;
using System.IO;
using System.Windows.Data;

namespace SFE.UI;

public class FileSizeConverter : IValueConverter
{
    public object Convert(object value, Type targetType, object parameter, CultureInfo culture)
    {
        if (value is string path)
        {
            try
            {
                if (File.Exists(path))
                    return $"{path}\n💾 {FormatSize(new FileInfo(path).Length)}";
                if (Directory.Exists(path))
                    return $"{path}\n📁";
            }
            catch { }
            return path;
        }
        return value ?? "";
    }

    public object ConvertBack(object value, Type targetType, object parameter, CultureInfo culture)
        => throw new NotSupportedException();

    private static string FormatSize(long bytes) =>
        bytes >= 1073741824 ? $"{bytes / 1073741824.0:F2} GB" :
        bytes >= 1048576    ? $"{bytes / 1048576.0:F1} MB" :
        bytes >= 1024       ? $"{bytes / 1024.0:F0} KB" :
                              $"{bytes} B";
}