namespace SFE.Core.Models;

public class SfeHeader
{
    public static readonly byte[] MagicBytes = 
        new byte[] { 0x53, 0x46, 0x45, 0x31 }; // "SFE1"

    public byte Version { get; set; } = 2; // نسخه ۲ — metadata رمزشده
    public byte AlgorithmId { get; set; } = 1;
    public byte[] Salt { get; set; } = new byte[16];
    public byte[] Nonce { get; set; } = new byte[24];
    public byte[] MetaNonce { get; set; } = new byte[24]; // nonce جداگانه برای metadata
    public uint Iterations { get; set; } = 4;
    public uint MemorySize { get; set; } = 65536;
    public uint DegreeOfParallelism { get; set; } = 2;
    public long? OriginalFileSize { get; set; }

    // این فیلدها دیگه در Header ذخیره نمیشن
    // فقط بعد از decrypt در حافظه هستن
    public string? OriginalFilename { get; set; }
}