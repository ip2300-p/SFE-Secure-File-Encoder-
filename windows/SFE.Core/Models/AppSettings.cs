using System.Text.Json;

namespace SFE.Core.Models;

public enum FileFilterPreset { All, Images, Videos, Documents, Custom }

public class AppSettings
{
    public string Language { get; set; } = "fa";
    public bool RandomizeFilename { get; set; } = false;
    public DisguisedNameStyle NameStyle { get; set; } = DisguisedNameStyle.CacheLike;
    public bool DeleteOriginalAfterEncrypt { get; set; } = false;
    public bool SecureDelete { get; set; } = false;
    public bool CreateBackup { get; set; } = false;
    public string BackupPath { get; set; } = "";
    public bool UseSecondaryPassword { get; set; } = false;
    public FileFilterPreset FilterPreset { get; set; } = FileFilterPreset.All;
    public string CustomFileFilter { get; set; } = "";
    public int ChunkSize { get; set; } = 4 * 1024 * 1024;

    public string[] GetResolvedFilter() => FilterPreset switch
    {
        FileFilterPreset.Images    => new[] { "jpg","jpeg","png","gif","webp","bmp","heic" },
        FileFilterPreset.Videos    => new[] { "mp4","mkv","avi","mov","wmv","flv" },
        FileFilterPreset.Documents => new[] { "pdf","docx","xlsx","pptx","txt","doc" },
        FileFilterPreset.Custom    => CustomFileFilter
                                        .Split(',')
                                        .Select(s => s.Trim().ToLower())
                                        .Where(s => !string.IsNullOrEmpty(s))
                                        .ToArray(),
        _ => Array.Empty<string>()
    };

    private static readonly string SettingsPath =
        Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "settings.json");

    public static AppSettings Load()
{
    try
    {
        if (File.Exists(SettingsPath))
        {
            var json = File.ReadAllText(SettingsPath);
            var settings = JsonSerializer.Deserialize<AppSettings>(json)
                           ?? new AppSettings();
            // لود زبان
            LocalizationService.Load(settings.Language);
            return settings;
        }
    }
    catch { }
    LocalizationService.Load("fa");
    return new AppSettings();
}

    public void Save()
    {
        try
        {
            var json = JsonSerializer.Serialize(this, new JsonSerializerOptions { WriteIndented = true });
            File.WriteAllText(SettingsPath, json);
        }
        catch { }
    }
}