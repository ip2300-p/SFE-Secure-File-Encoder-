using SFE.Core.Models;

namespace SFE.Services;

public class LoggingService
{
    private readonly string _logPath;
    private readonly object _lock = new();

    public LoggingService()
    {
        var appDir = AppDomain.CurrentDomain.BaseDirectory;
        _logPath = Path.Combine(appDir, "sfe_log.txt");
    }

    public void Log(string operation, string filePath, bool success, string? error = null)
    {
        try
        {
            // 🆕 فقط نام فایل (بدون مسیر) — حفظ حریم خصوصی
        var line = $"[{DateTime.Now:yyyy-MM-dd HH:mm:ss}] " +
                   $"{operation} | " +
                   $"{Path.GetFileName(filePath)} | " +
                   $"{(success ? "OK" : "FAIL")}";
        if (!success && error != null)
            line += $" | {error}";

            lock (_lock)
            {
                File.AppendAllText(_logPath, line + Environment.NewLine);
            }
        }
        catch
        {
            // Logging نباید برنامه رو crash کنه
        }
    }

    public void LogResults(string operation, List<OperationResult> results)
    {
        foreach (var result in results)
        {
            Log(operation,
                result.FilePath ?? "نامشخص",
                result.Success,
                result.ErrorMessage);
        }
    }
}