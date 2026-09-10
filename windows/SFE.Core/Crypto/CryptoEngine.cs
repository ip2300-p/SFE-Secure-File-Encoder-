using Sodium;
using System.Buffers.Binary;
using System.Security.Cryptography;

namespace SFE.Core.Crypto;

public static class CryptoEngine
{
    private const int ChunkSize = 4 * 1024 * 1024; // 4MB

    // ── هر chunk یک nonce منحصربه‌فرد میگیره ──────────
    // nonce chunk = XOR(baseNonce, chunkCounter)
    // این روش استاندارد و امن هست
    private static byte[] DeriveChunkNonce(byte[] baseNonce, long chunkIndex)
    {
        var chunkNonce = (byte[])baseNonce.Clone();
        var indexBytes = new byte[8];
        BinaryPrimitives.WriteInt64LittleEndian(indexBytes, chunkIndex);
        for (int i = 0; i < 8; i++)
            chunkNonce[baseNonce.Length - 8 + i] ^= indexBytes[i];
        return chunkNonce;
    }

    public static void EncryptStream(
        Stream inputStream,
        Stream outputStream,
        byte[] key,
        byte[] baseNonce,
        int chunkSize = ChunkSize,
        IProgress<long>? progress = null,
        CancellationToken cancellationToken = default)
    {
        var buffer = new byte[chunkSize];
        long totalBytesRead = 0;
        long chunkIndex = 0;
        int bytesRead;
        while ((bytesRead = inputStream.Read(buffer, 0, buffer.Length)) > 0)
        {
            cancellationToken.ThrowIfCancellationRequested();
            var chunkNonce = DeriveChunkNonce(baseNonce, chunkIndex);
            var chunk = buffer[..bytesRead];
            var encrypted = SecretAeadXChaCha20Poly1305.Encrypt(chunk, chunkNonce, key);
            CryptographicOperations.ZeroMemory(chunkNonce);
            var lengthBytes = BitConverter.GetBytes(encrypted.Length);
            outputStream.Write(lengthBytes, 0, 4);
            outputStream.Write(encrypted, 0, encrypted.Length);
            totalBytesRead += bytesRead;
            chunkIndex++;
            progress?.Report(totalBytesRead);
        }
    }

    public static void DecryptStream(
        Stream inputStream,
        Stream outputStream,
        byte[] key,
        byte[] baseNonce,
        IProgress<long>? progress = null,
        CancellationToken cancellationToken = default)
    {
        long totalBytesRead = 0;
        long chunkIndex = 0;
        var lengthBuffer = new byte[4];
        while (inputStream.Read(lengthBuffer, 0, 4) == 4)
        {
            cancellationToken.ThrowIfCancellationRequested();
            var chunkLength = BitConverter.ToInt32(lengthBuffer, 0);

            // 🆕 اعتبارسنجی طول chunk (جلوگیری از تخصیص حافظه با فایل مخرب/خراب)
                        if (chunkLength <= 0 || chunkLength > 64 * 1024 * 1024)
                throw new InvalidDataException("ساختار فایل نامعتبر است.");

            var encryptedChunk = new byte[chunkLength];
            inputStream.ReadExactly(encryptedChunk, 0, chunkLength);

            var chunkNonce = DeriveChunkNonce(baseNonce, chunkIndex);
            byte[] decrypted;
            try
            {
                decrypted = SecretAeadXChaCha20Poly1305.Decrypt(
                    encryptedChunk, chunkNonce, key);
            }
            catch
            {
                CryptographicOperations.ZeroMemory(chunkNonce);
                throw new InvalidDataException("رمز عبور اشتباه است یا فایل آسیب دیده.");
            }
            CryptographicOperations.ZeroMemory(chunkNonce);
            outputStream.Write(decrypted, 0, decrypted.Length);
            totalBytesRead += chunkLength;
            chunkIndex++;
            progress?.Report(totalBytesRead);
        }
    }
}