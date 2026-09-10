namespace SFE.Core.Models;

public class OperationResult
{
    public bool Success { get; set; }
    public string? ErrorMessage { get; set; }
    public string? FilePath { get; set; }

    public static OperationResult Ok(string filePath) =>
        new() { Success = true, FilePath = filePath };

    public static OperationResult Fail(string error) =>
        new() { Success = false, ErrorMessage = error };
}