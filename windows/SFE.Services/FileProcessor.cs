using SFE.Core.FileFormat;
using SFE.Core.Models;
using System.Diagnostics;

namespace SFE.Services;

public class FileProcessor
{
    private readonly EncryptionService _encryptionService = new();
    private readonly DecryptionService _decryptionService = new();

    public async Task<List<OperationResult>> EncryptPathsAsync(
        List<string> inputPaths,
        string outputDirectory,
        string password,
        EncryptionOptions options,
        IProgress<ProgressInfo>? progress = null,
        CancellationToken cancellationToken = default)
    {
        var files = new List<string>();
        foreach (var path in inputPaths)
        {
            if (File.Exists(path)) files.Add(path);
            else if (Directory.Exists(path))
                files.AddRange(GetFiles(path, options.FileFilter));
        }

        if (options.CreateBackup && !string.IsNullOrEmpty(options.BackupPath))
            await EncryptionService.CreateEncryptedZipBackupAsync(
                files, options.BackupPath, password);

        var results       = new List<OperationResult>();
        int total         = files.Count;
        int processed     = 0;
        long totalBytes   = files.Sum(f => new FileInfo(f).Length);
        long processedBytes = 0;
        var stopwatch     = Stopwatch.StartNew();

        foreach (var file in files)
        {
            cancellationToken.ThrowIfCancellationRequested();
            var fileSize = new FileInfo(file).Length;
            double elapsed = Math.Max(stopwatch.Elapsed.TotalSeconds, 0.001);

            progress?.Report(new ProgressInfo
            {
                CurrentFile     = Path.GetFileName(file),
                TotalFiles      = total,
                ProcessedFiles  = processed,
                Percentage      = total > 0 ? (double)processed / total * 100 : 0,
                Status          = LocalizationService.Get("Encrypting"),
                TotalBytes      = totalBytes,
                ProcessedBytes  = processedBytes,
                BytesPerSecond  = processedBytes / elapsed,
                TimeRemaining   = processedBytes > 0
                    ? TimeSpan.FromSeconds((totalBytes - processedBytes) / (processedBytes / elapsed))
                    : null
            });

            var optNoBackup = new EncryptionOptions
            {
                RandomizeFilename          = options.RandomizeFilename,
                NameStyle                  = options.NameStyle,
                DeleteOriginalAfterEncrypt = options.DeleteOriginalAfterEncrypt,
                SecureDelete               = options.SecureDelete,
                FileFilter                 = options.FileFilter,
                ChunkSize                  = options.ChunkSize,
                CreateBackup               = false
            };

            var result = await _encryptionService.EncryptFileAsync(
                file, outputDirectory, password, optNoBackup, progress, cancellationToken);
            results.Add(result);
            processed++;
            processedBytes += fileSize;

            // 🆕 گزارش لحظه‌ای پایان هر فایل (برای آیکون لیست و شمارنده)
            double elapsed2 = Math.Max(stopwatch.Elapsed.TotalSeconds, 0.001);
            progress?.Report(new ProgressInfo
            {
                CurrentFile      = Path.GetFileName(file),
                TotalFiles       = total,
                ProcessedFiles   = processed,
                Percentage       = total > 0 ? (double)processed / total * 100 : 0,
                Status           = LocalizationService.Get("Encrypting"),
                TotalBytes       = totalBytes,
                ProcessedBytes   = processedBytes,
                BytesPerSecond   = processedBytes / elapsed2,
                CompletedPath    = file,
                CompletedSuccess = result.Success
            });
        }

        progress?.Report(new ProgressInfo
        {
            TotalFiles = total, ProcessedFiles = processed,
            Percentage = 100,  Status = LocalizationService.Get("Done"),
            TotalBytes = totalBytes, ProcessedBytes = totalBytes
        });

        return results;
    }

    public async Task<List<OperationResult>> DecryptPathsAsync(
        List<string> inputPaths,
        string outputDirectory,
        string password,
        IProgress<ProgressInfo>? progress = null,
        CancellationToken cancellationToken = default)
    {
        var files = new List<string>();
        foreach (var path in inputPaths)
        {
            if (File.Exists(path))
            {
                if (SfeFileReader.IsSfeFile(path)) files.Add(path);
            }
            else if (Directory.Exists(path))
            {
                var all = Directory.GetFiles(path, "*", SearchOption.AllDirectories);
                files.AddRange(all.Where(SfeFileReader.IsSfeFile));
            }
        }

        var results   = new List<OperationResult>();
        int total     = files.Count;
        int processed = 0;

        foreach (var file in files)
        {
            cancellationToken.ThrowIfCancellationRequested();
            progress?.Report(new ProgressInfo
            {
                CurrentFile    = Path.GetFileName(file),
                TotalFiles     = total,
                ProcessedFiles = processed,
                Percentage     = total > 0 ? (double)processed / total * 100 : 0,
                Status         = LocalizationService.Get("Decrypting")
            });

            var result = await _decryptionService.DecryptFileAsync(
                file, outputDirectory, password, cancellationToken);
            results.Add(result);
            processed++;

            progress?.Report(new ProgressInfo
            {
                CurrentFile      = Path.GetFileName(file),
                TotalFiles       = total,
                ProcessedFiles   = processed,
                Percentage       = total > 0 ? (double)processed / total * 100 : 0,
                Status           = LocalizationService.Get("Decrypting"),
                CompletedPath    = file,
                CompletedSuccess = result.Success
            });
        }

        progress?.Report(new ProgressInfo
        {
            TotalFiles     = total,
            ProcessedFiles = processed,
            Percentage     = 100,
            Status         = LocalizationService.Get("Done")
        });

        return results;
    }

    private static List<string> GetFiles(string path, string[]? filter)
    {
        var all = Directory.GetFiles(path, "*", SearchOption.AllDirectories).ToList();
        if (filter == null || filter.Length == 0) return all;
        return all.Where(f =>
            filter.Contains(Path.GetExtension(f).TrimStart('.').ToLower())).ToList();
    }
}