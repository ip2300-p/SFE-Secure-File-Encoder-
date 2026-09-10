using ICSharpCode.SharpZipLib.Zip;
using SFE.Core.Crypto;
using SFE.Core.FileFormat;
using SFE.Core.Models;
using System.Security.Cryptography;
using System.Text;

namespace SFE.Services;

public class EncryptionService
{
    public async Task<OperationResult> EncryptFileAsync(
        string inputPath,
        string outputDirectory,
        string password,
        EncryptionOptions options,
        IProgress<ProgressInfo>? progress = null,
        CancellationToken cancellationToken = default)
    {
        byte[]? key = null;
        string? finalOutputPath = null;
        try
        {
            // بکاپ ZIP رمزدار (🆕 اگر شکست بخورد، خطا بالا می‌آید و کاربر مطلع می‌شود)
            if (options.CreateBackup && !string.IsNullOrEmpty(options.BackupPath))
                await CreateEncryptedZipBackupAsync(
                    new List<string> { inputPath }, options.BackupPath, password);

            var salt  = KeyDerivation.GenerateSalt();
            var nonce = KeyDerivation.GenerateNonce();
            byte[] metaNonce;
            do { metaNonce = KeyDerivation.GenerateNonce(); }
            while (metaNonce.SequenceEqual(nonce));

            var passwordBytes = Encoding.UTF8.GetBytes(password);
            key = KeyDerivation.DeriveKey(password, salt);
            CryptographicOperations.ZeroMemory(passwordBytes);

            var header = new SfeHeader
            {
                Salt             = salt,
                Nonce            = nonce,
                MetaNonce        = metaNonce,
                OriginalFilename = Path.GetFileName(inputPath),
                OriginalFileSize = new FileInfo(inputPath).Length
            };

            string outputFilename = options.RandomizeFilename
                ? DisguisedNameGenerator.Generate(options.NameStyle)
                : Path.GetFileName(inputPath) + ".sfe";
            finalOutputPath = Path.Combine(outputDirectory, outputFilename);

            // 🆕 جلوگیری از بازنویسی بی‌صدا روی فایل موجود
            if (File.Exists(finalOutputPath))
            {
                var baseName = Path.GetFileNameWithoutExtension(outputFilename);
                var ext      = Path.GetExtension(outputFilename);
                var i = 1;
                while (File.Exists(finalOutputPath))
                    finalOutputPath = Path.Combine(outputDirectory, $"{baseName}_{i++}{ext}");
            }

            await using (var inputStream  = File.OpenRead(inputPath))
            await using (var outputStream = File.Create(finalOutputPath))
            {
                SfeFileWriter.WriteHeader(outputStream, header, key);
                var fileProgress = new Progress<long>(b =>
                    progress?.Report(new ProgressInfo
                    {
                        CurrentFile    = Path.GetFileName(inputPath),
                        Status         = LocalizationService.Get("Encrypting"),
                        ProcessedBytes = b
                    }));
                await Task.Run(() => CryptoEngine.EncryptStream(
                    inputStream, outputStream, key, nonce,
                    options.ChunkSize, fileProgress, cancellationToken),
                    cancellationToken);
            }

            // 🆕 راستی‌آزمایی کامل خروجی، فقط وقتی قرار است اصلِ فایل حذف شود
            if (options.DeleteOriginalAfterEncrypt || options.SecureDelete)
            {
                var originalLength = new FileInfo(inputPath).Length;
                using (var verify = File.OpenRead(finalOutputPath))
                {
                    var vHeader = SfeFileReader.ReadHeader(verify, key);
                    var counter = new CountingStream();
                    CryptoEngine.DecryptStream(verify, counter, key, vHeader.Nonce);
                    if (counter.Count != originalLength)
                        throw new InvalidDataException(
                            "راستی‌آزمایی فایل رمزشده ناموفق بود؛ فایل اصلی حذف نشد.");
                }

                GC.Collect();
                GC.WaitForPendingFinalizers();
                Thread.Sleep(100);
                if (options.SecureDelete)
                    SecureDeleteFile(inputPath);
                else
                {
                    for (int i = 0; i < 5; i++)
                    {
                        try { File.Delete(inputPath); break; }
                        catch { Thread.Sleep(200); }
                    }
                }
            }

            return OperationResult.Ok(finalOutputPath);
        }
        catch (OperationCanceledException)
        {
            TryDeleteIncomplete(finalOutputPath);
            return OperationResult.Fail("عملیات توسط کاربر لغو شد.");
        }
        catch (Exception ex)
        {
            TryDeleteIncomplete(finalOutputPath);
            return OperationResult.Fail($"خطا: {ex.Message}");
        }
        finally
        {
            if (key != null)
                CryptographicOperations.ZeroMemory(key);
            GC.Collect(GC.MaxGeneration, GCCollectionMode.Aggressive, true, true);
        }
    }

    private static void TryDeleteIncomplete(string? path)
    {
        try
        {
            if (path != null && File.Exists(path))
                File.Delete(path);
        }
        catch { }
    }

    // ── بکاپ رمزدار ───────────────────────────────────
    public static async Task CreateEncryptedZipBackupAsync(
        List<string> filePaths, string backupDir, string password)
    {
        byte[]? key = null;
        string? zipPath = null;
        try
        {
            Directory.CreateDirectory(backupDir);
            var baseName = $"backup_{DateTime.Now:yyyyMMdd_HHmmss}";
            zipPath      = Path.Combine(Path.GetTempPath(), baseName + ".zip");
            var outPath  = Path.Combine(backupDir, baseName + ".sfe.bak");

            await Task.Run(() =>
            {
                using var fs  = File.Create(zipPath);
                using var zip = new ZipOutputStream(fs);
                zip.SetLevel(5);
                foreach (var filePath in filePaths)
                {
                    if (!File.Exists(filePath)) continue;
                    var entry = new ZipEntry(Path.GetFileName(filePath))
                        { IsUnicodeText = true };
                    zip.PutNextEntry(entry);
                    using var input = File.OpenRead(filePath);
                    var buffer = new byte[4096];
                    int bytesRead;
                    while ((bytesRead = input.Read(buffer, 0, buffer.Length)) > 0)
                        zip.Write(buffer, 0, bytesRead);
                    zip.CloseEntry();
                }
                zip.Finish();
            });

            var salt  = KeyDerivation.GenerateSalt();
            var nonce = KeyDerivation.GenerateNonce();
            byte[] metaNonce;
            do { metaNonce = KeyDerivation.GenerateNonce(); }
            while (metaNonce.SequenceEqual(nonce));
            key = KeyDerivation.DeriveKey(password, salt);

            var header = new SfeHeader
            {
                Salt             = salt,
                Nonce            = nonce,
                MetaNonce        = metaNonce,
                OriginalFilename = baseName + ".zip"
            };

            await using (var inputStream  = File.OpenRead(zipPath))
            await using (var outputStream = File.Create(outPath))
            {
                SfeFileWriter.WriteHeader(outputStream, header, key);
                await Task.Run(() => CryptoEngine.EncryptStream(
                    inputStream, outputStream, key, nonce));
            }
        }
        // 🆕 catch خالی حذف شد — خطا به بالا منتقل می‌شود تا کاربر بفهمد بکاپ ساخته نشد
        finally
        {
            try
            {
                if (zipPath != null && File.Exists(zipPath))
                    File.Delete(zipPath);
            }
            catch { }
            if (key != null)
                CryptographicOperations.ZeroMemory(key);
        }
    }

    // ── حذف امن ──────────────────────────────────────
    private static void SecureDeleteFile(string path)
    {
        try
        {
            var length = new FileInfo(path).Length;
            for (int attempt = 0; attempt < 5; attempt++)
            {
                try
                {
                    using (var stream = new FileStream(
                        path, FileMode.Open, FileAccess.Write,
                        FileShare.None, 4096, FileOptions.WriteThrough))
                    {
                        var rng = RandomNumberGenerator.Create();
                        for (int pass = 0; pass < 3; pass++)
                        {
                            stream.Seek(0, SeekOrigin.Begin);
                            var buf = new byte[4096];
                            long written = 0;
                            while (written < length)
                            {
                                rng.GetBytes(buf);
                                var toWrite = (int)Math.Min(buf.Length, length - written);
                                stream.Write(buf, 0, toWrite);
                                written += toWrite;
                            }
                            stream.Flush();
                        }
                    }
                    for (int delAttempt = 0; delAttempt < 5; delAttempt++)
                    {
                        try
                        {
                            GC.Collect();
                            GC.WaitForPendingFinalizers();
                            File.Delete(path);
                            return;
                        }
                        catch { Thread.Sleep(200); }
                    }
                }
                catch { Thread.Sleep(300); }
            }
            throw new IOException("فایل در دسترس نیست.");
        }
        catch (Exception ex)
        {
            throw new IOException($"حذف امن ناموفق: {ex.Message}");
        }
    }

    // 🆕 استریم شمارنده برای راستی‌آزمایی (بدون نوشتن واقعی)
    private sealed class CountingStream : Stream
    {
        public long Count { get; private set; }
        public override bool CanRead  => false;
        public override bool CanSeek  => false;
        public override bool CanWrite => true;
        public override long Length   => Count;
        public override long Position { get => Count; set => throw new NotSupportedException(); }
        public override void Write(byte[] buffer, int offset, int count) => Count += count;
        public override void Flush() { }
        public override int  Read(byte[] buffer, int offset, int count) => throw new NotSupportedException();
        public override long Seek(long offset, SeekOrigin origin) => throw new NotSupportedException();
        public override void SetLength(long value) => throw new NotSupportedException();
    }
}