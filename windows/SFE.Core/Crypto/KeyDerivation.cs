using Konscious.Security.Cryptography;
using System.Security.Cryptography;
using System.Text;

namespace SFE.Core.Crypto;

public static class KeyDerivation
{
    public static byte[] DeriveKey(
        string password,
        byte[] salt,
        uint iterations = 4,
        uint memorySize = 65536,
        uint parallelism = 2)
    {
        var passwordBytes = Encoding.UTF8.GetBytes(password);
        try
        {
            using var argon2 = new Argon2id(passwordBytes);
            argon2.Salt                = salt;
            argon2.Iterations          = (int)iterations;
            argon2.MemorySize          = (int)memorySize;
            argon2.DegreeOfParallelism = (int)parallelism;
            return argon2.GetBytes(32);
        }
        finally
        {
            // پاک کردن passwordBytes از حافظه بعد از استفاده
            CryptographicOperations.ZeroMemory(passwordBytes);
        }
    }

    public static byte[] GenerateSalt()
    {
        var salt = new byte[16];
        RandomNumberGenerator.Fill(salt);
        return salt;
    }

    public static byte[] GenerateNonce()
    {
        var nonce = new byte[24];
        RandomNumberGenerator.Fill(nonce);
        return nonce;
    }
}