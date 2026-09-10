using System.Security.Cryptography;

namespace SFE.Core.Models;

public enum DisguisedNameStyle
{
    None,
    CacheLike,      // مثل: cache_tmp_A3F2B1C4
    DataLike,       // مثل: data_cfg_B7D1E2F3
    GuidShort       // مثل: f3a2b1c4d5e6f7a8
}

public class EncryptionOptions
{
    public bool RandomizeFilename { get; set; } = false;
    public DisguisedNameStyle NameStyle { get; set; } = DisguisedNameStyle.CacheLike;
    public bool DeleteOriginalAfterEncrypt { get; set; } = false;
    public bool SecureDelete { get; set; } = false;
    public string[]? FileFilter { get; set; }
    public int ChunkSize { get; set; } = 4 * 1024 * 1024;
    public bool CreateBackup { get; set; } = false;
    public string? BackupPath { get; set; }
    public string? SecondaryPassword { get; set; }
    public bool UseSecondaryPassword { get; set; } = false;
}

public static class DisguisedNameGenerator
{
    private static readonly string[] CachePrefixes =
        { "cache_tmp", "cache_cfg", "cache_dat", "tmp_store", "sys_tmp" };
    private static readonly string[] DataPrefixes =
        { "data_cfg", "data_bin", "app_dat", "usr_cfg", "cfg_bin" };

    // 🆕 هش ۸ کاراکتری با RNG رمزنگاری (به جای Random معمولی ۴ کاراکتری)
    private static string RandomHex8()
    {
        Span<byte> buf = stackalloc byte[4];
        RandomNumberGenerator.Fill(buf);
        return Convert.ToHexString(buf);
    }

    public static string Generate(DisguisedNameStyle style)
    {
        return style switch
        {
            DisguisedNameStyle.CacheLike =>
                $"{CachePrefixes[RandomNumberGenerator.GetInt32(0, CachePrefixes.Length)]}_{RandomHex8()}.tmp",
            DisguisedNameStyle.DataLike =>
                $"{DataPrefixes[RandomNumberGenerator.GetInt32(0, DataPrefixes.Length)]}_{RandomHex8()}.bin",
            DisguisedNameStyle.GuidShort =>
                $"{Guid.NewGuid():N}".Substring(0, 16),
            _ => Guid.NewGuid().ToString("N") + ".sfe"
        };
    }
}