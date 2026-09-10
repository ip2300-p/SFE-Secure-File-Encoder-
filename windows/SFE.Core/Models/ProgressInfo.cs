namespace SFE.Core.Models;

public class ProgressInfo
{
    public string CurrentFile { get; set; } = "";
    public int TotalFiles { get; set; }
    public int ProcessedFiles { get; set; }
    public double Percentage { get; set; }
    public string Status { get; set; } = "";
    public double BytesPerSecond { get; set; }
    public TimeSpan? TimeRemaining { get; set; }
    public long TotalBytes { get; set; }
    public long ProcessedBytes { get; set; }
    public string? CompletedPath { get; set; }
    public bool? CompletedSuccess { get; set; }
}