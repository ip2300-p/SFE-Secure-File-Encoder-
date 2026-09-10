using System;
using System.Runtime.InteropServices;
using System.Windows;
using System.Windows.Interop;

namespace SFE.UI;

public static class TitleBarHelper
{
    [DllImport("dwmapi.dll")]
    private static extern int DwmSetWindowAttribute(IntPtr hwnd, int attr, ref int attrValue, int attrSize);

    public static void UseDarkTitleBar(Window window)
    {
        window.SourceInitialized += (s, e) =>
        {
            try
            {
                var hwnd = new WindowInteropHelper(window).Handle;
                int value = 1; // DWMWA_USE_IMMERSIVE_DARK_MODE
                DwmSetWindowAttribute(hwnd, 20, ref value, sizeof(int));
            }
            catch { }
        };
    }
}