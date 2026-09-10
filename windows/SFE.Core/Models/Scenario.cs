namespace SFE.Core.Models;

public class Scenario
{
    public string Id { get; set; } = Guid.NewGuid().ToString("N");
    public string Name { get; set; } = "";
    public string Mode { get; set; } = "Encrypt"; // Encrypt / Decrypt
    public List<string> SourcePaths { get; set; } = new();
    public string OutputDirectory { get; set; } = "";
    public bool RandomizeFilename { get; set; } = false;
    public DisguisedNameStyle NameStyle { get; set; } = DisguisedNameStyle.CacheLike;
    public bool DeleteOriginalAfterEncrypt { get; set; } = false;
    public bool SecureDelete { get; set; } = false;
    public bool CreateBackup { get; set; } = false;
    public string BackupPath { get; set; } = "";
    public FileFilterPreset FilterPreset { get; set; } = FileFilterPreset.All;
    public string CustomFileFilter { get; set; } = "";
    public bool UseSecondaryPassword { get; set; } = false;
    public DateTime CreatedAt { get; set; } = DateTime.Now;
    public DateTime? LastRunAt { get; set; }
}