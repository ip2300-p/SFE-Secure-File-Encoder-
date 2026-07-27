/// معادل OperationResult.cs
class OperationResult {
  final bool success;
  final String? errorMessage;
  final String? filePath;

  OperationResult._({required this.success, this.errorMessage, this.filePath});

  factory OperationResult.ok(String filePath) =>
      OperationResult._(success: true, filePath: filePath);

  factory OperationResult.fail(String error) =>
      OperationResult._(success: false, errorMessage: error);
}
