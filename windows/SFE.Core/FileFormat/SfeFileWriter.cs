using SFE.Core.Models;
using Sodium;
using System.Text;

namespace SFE.Core.FileFormat;

public static class SfeFileWriter
{
    public static void WriteHeader(Stream stream, SfeHeader header, byte[] key)
    {
        // Magic Bytes
        stream.Write(SfeHeader.MagicBytes, 0, 4);

        // Version & Algorithm
        stream.WriteByte(header.Version);
        stream.WriteByte(header.AlgorithmId);

        // Argon2 Parameters (لازمه تا بتونیم key رو بسازیم)
        stream.Write(BitConverter.GetBytes(header.Iterations), 0, 4);
        stream.Write(BitConverter.GetBytes(header.MemorySize), 0, 4);
        stream.Write(BitConverter.GetBytes(header.DegreeOfParallelism), 0, 4);

        // Salt و Nonce اصلی
        stream.Write(header.Salt, 0, 16);
        stream.Write(header.Nonce, 0, 24);

        // MetaNonce — برای رمزنگاری metadata
        stream.Write(header.MetaNonce, 0, 24);

        // رمزنگاری metadata (اسم فایل)
        var filename = header.OriginalFilename ?? "unknown";
        var metaString = header.OriginalFileSize.HasValue
            ? $"{filename}\0{header.OriginalFileSize.Value}"
            : filename;
        var filenameBytes = Encoding.UTF8.GetBytes(metaString);
        var encryptedMeta = SecretAeadXChaCha20Poly1305.Encrypt(
            filenameBytes, header.MetaNonce, key);

        // نوشتن metadata رمزشده
        stream.Write(BitConverter.GetBytes(encryptedMeta.Length), 0, 4);
        stream.Write(encryptedMeta, 0, encryptedMeta.Length);
    }
}