using System.Xml.Linq;

namespace SFE.Core.Models;

public static class LocalizationService
{
    private static Dictionary<string, string> _strings = new();
    private static string _currentLang = "fa";

    public static string CurrentLang => _currentLang;

    public static void Load(string lang)
    {
        _currentLang = lang;
        var langDir  = Path.Combine(
            AppDomain.CurrentDomain.BaseDirectory, "lang");
        var filePath = Path.Combine(langDir, $"{lang}.xml");

        // اگه فایل زبان وجود نداشت، فارسی رو لود کن
        if (!File.Exists(filePath))
            filePath = Path.Combine(langDir, "fa.xml");

        if (!File.Exists(filePath)) return;

        try
        {
            var doc = XDocument.Load(filePath);
            _strings = doc.Root?
                .Elements("string")
                .Where(e => e.Attribute("key") != null)
                .ToDictionary(
                    e => e.Attribute("key")!.Value,
                    e => e.Value)
                ?? new Dictionary<string, string>();
        }
        catch { }
    }

    public static string Get(string key) =>
        _strings.TryGetValue(key, out var val) ? val : $"[{key}]";

    // لیست زبان‌های موجود
    public static List<string> GetAvailableLanguages()
    {
        var langDir = Path.Combine(
            AppDomain.CurrentDomain.BaseDirectory, "lang");

        if (!Directory.Exists(langDir)) return new List<string> { "fa" };

        return Directory.GetFiles(langDir, "*.xml")
            .Select(f => Path.GetFileNameWithoutExtension(f))
            .ToList();
    }
}