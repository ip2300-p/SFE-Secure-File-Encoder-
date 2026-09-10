using SFE.Core.Models;
using Sodium;
using System.Text;

namespace SFE.Core.FileFormat;

public static class SfeFileReader
{
    // سقف‌های منطقی برای جلوگیری از DoS با فایل خراب/مخرب
    private const int  MaxMetaLength  = 1024 * 1024;   // 1MB برای metadata کافی است
    private const uint MaxMemorySize  = 1_048_576;     // 1GB (واحد KB)
    private const uint MaxIterations  = 64;
    private const uint MaxParallelism = 16;

    public static bool IsSfeFile(string path)
    {
        try
        {
            using var fs = File.OpenRead(path);
            var magic = new byte[4];
            if (fs.Read(magic, 0, 4) < 4) return false;
            return magic.SequenceEqual(SfeHeader.MagicBytes);
        }
        catch { return false; }
    }

    public static SfeHeader ReadHeader(Stream stream, byte[]? key = null)
    {
        // بررسی Magic Bytes
        var magic = new byte[4];
        stream.ReadExactly(magic, 0, 4);
        if (!magic.SequenceEqual(SfeHeader.MagicBytes))
            throw new InvalidDataException("فایل معتبر SFE نیست.");

        var header = new SfeHeader();

        // Version & Algorithm
        header.Version     = (byte)stream.ReadByte();
        header.AlgorithmId = (byte)stream.ReadByte();

        // 🆕 بررسی پشتیبانی نسخه و الگوریتم
        if (header.Version != 2)
            throw new InvalidDataException("نسخه این فایل پشتیبانی نمی‌شود (نیاز به نسخه جدیدتر برنامه است).");
        if (header.AlgorithmId != 1)
            throw new InvalidDataException("الگوریتم رمزنگاری این فایل پشتیبانی نمی‌شود.");

        // Argon2 Parameters
        var iterBytes = new byte[4];
        stream.ReadExactly(iterBytes, 0, 4);
        header.Iterations = BitConverter.ToUInt32(iterBytes, 0);

        var memBytes = new byte[4];
        stream.ReadExactly(memBytes, 0, 4);
        header.MemorySize = BitConverter.ToUInt32(memBytes, 0);

        var parBytes = new byte[4];
        stream.ReadExactly(parBytes, 0, 4);
        header.DegreeOfParallelism = BitConverter.ToUInt32(parBytes, 0);

        // 🆕 سقف پارامترهای Argon2 (جلوگیری از تخصیص حافظه توسط فایل مخرب)
        if (header.Iterations is 0 or > MaxIterations)
            throw new InvalidDataException("پارامترهای Argon2 فایل نامعتبر است.");
        if (header.MemorySize is 0 or > MaxMemorySize)
            throw new InvalidDataException("پارامترهای Argon2 فایل نامعتبر است.");
        if (header.DegreeOfParallelism is 0 or > MaxParallelism)
            throw new InvalidDataException("پارامترهای Argon2 فایل نامعتبر است.");

        // Salt و Nonce
        header.Salt = new byte[16];
        stream.ReadExactly(header.Salt, 0, 16);
        header.Nonce = new byte[24];
        stream.ReadExactly(header.Nonce, 0, 24);

        // MetaNonce
        header.MetaNonce = new byte[24];
        stream.ReadExactly(header.MetaNonce, 0, 24);

        // خواندن metadata رمزشده
        var metaLenBytes = new byte[4];
        stream.ReadExactly(metaLenBytes, 0, 4);
        var metaLength = BitConverter.ToInt32(metaLenBytes, 0);

        // 🆕 اعتبارسنجی طول metadata (جلوگیری از تخصیص حافظه عظیم)
        if (metaLength < 0 || metaLength > MaxMetaLength)
            throw new InvalidDataException("هدر فایل نامعتبر است.");

        var encryptedMeta = new byte[metaLength];
        stream.ReadExactly(encryptedMeta, 0, metaLength);

        // رمزگشایی metadata (فقط اگر key داریم)
        if (key != null)
        {
            try
            {
                var decryptedMeta = SecretAeadXChaCha20Poly1305.Decrypt(
                    encryptedMeta, header.MetaNonce, key);
                var metaString = Encoding.UTF8.GetString(decryptedMeta);
                var nullIndex = metaString.IndexOf('\0');
                if (nullIndex >= 0)
                {
                    header.OriginalFilename = metaString.Substring(0, nullIndex);
                    if (long.TryParse(metaString.Substring(nullIndex + 1), out var size))
                        header.OriginalFileSize = size;
                }
                else
                {
                    header.OriginalFilename = metaString;
                }
            }
            catch
            {
                throw new InvalidDataException("رمز عبور اشتباه است.");
            }
        }
        return header;
    }
}