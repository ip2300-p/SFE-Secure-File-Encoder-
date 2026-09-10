using SFE.Core.Crypto;
using SFE.Core.FileFormat;
using SFE.Core.Models;
using System.Security.Cryptography;

namespace SFE.Services;

public class DecryptionService
{
    public async Task<OperationResult> DecryptFileAsync(
        string inputPath,
        string outputDirectory,
        string password,
        CancellationToken cancellationToken = default)
    {
        byte[]? key = null;
        try
        {
            await using var inputStream = File.OpenRead(inputPath);

            // خواندن header بدون key برای گرفتن salt
            var headerPartial = SfeFileReader.ReadHeader(inputStream, key: null);

            // ساخت key
            key = KeyDerivation.DeriveKey(
                password,
                headerPartial.Salt,
                headerPartial.Iterations,
                headerPartial.MemorySize,
                headerPartial.DegreeOfParallelism);

            // خواندن مجدد header با key برای decrypt کردن metadata
            inputStream.Seek(0, SeekOrigin.Begin);
            var header = SfeFileReader.ReadHeader(inputStream, key: key);

            // 🆕 حذف هرگونه مسیر از نام فایل (جلوگیری از Path Traversal)
            var rawName = !string.IsNullOrEmpty(header.OriginalFilename)
                ? header.OriginalFilename
                : Path.GetFileNameWithoutExtension(inputPath);
            var outputFilename = Path.GetFileName(rawName);
            if (string.IsNullOrWhiteSpace(outputFilename))
                outputFilename = Path.GetFileNameWithoutExtension(inputPath);

            var outputPath = Path.Combine(outputDirectory, outputFilename);
            if (File.Exists(outputPath))
            {
                var name = Path.GetFileNameWithoutExtension(outputPath);
                var ext  = Path.GetExtension(outputPath);
                outputPath = Path.Combine(outputDirectory, $"{name}_decrypted{ext}");
            }

            await using var outputStream = File.Create(outputPath);
            await Task.Run(() => CryptoEngine.DecryptStream(
                inputStream, outputStream, key, header.Nonce,
                cancellationToken: cancellationToken), cancellationToken);

            // بررسی کامل‌بودن فایل رمزشده
            if (header.OriginalFileSize.HasValue)
            {
                await outputStream.FlushAsync(cancellationToken);
                if (outputStream.Length != header.OriginalFileSize.Value)
                {
                    outputStream.Close();
                    try { File.Delete(outputPath); } catch { }
                    return OperationResult.Fail(
                        "فایل رمزشده کامل نیست (احتمالاً حین انتقال قطع شده). دوباره فایل رو منتقل کن و امتحان کن.");
                }
            }

            return OperationResult.Ok(outputPath);
        }
        catch (OperationCanceledException)
        {
            return OperationResult.Fail("عملیات توسط کاربر لغو شد.");
        }
        catch (InvalidDataException ex)
        {
            return OperationResult.Fail(ex.Message);
        }
        catch (Exception ex)
        {
            return OperationResult.Fail($"خطا: {ex.Message}");
        }
        finally
        {
            if (key != null)
                CryptographicOperations.ZeroMemory(key);
            GC.Collect();
        }
    }
}