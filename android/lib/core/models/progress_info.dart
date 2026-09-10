/// معادل ProgressInfo.cs (نسخه‌ی ساده‌شده برای شروع)
class ProgressInfo {
  final String currentFile;
  final double percentage; // 0 تا 100
  final String status;

  ProgressInfo({
    this.currentFile = '',
    this.percentage = 0,
    this.status = '',
  });
}
