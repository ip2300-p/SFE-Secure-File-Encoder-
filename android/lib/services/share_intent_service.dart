import 'package:receive_sharing_intent/receive_sharing_intent.dart';

/// دریافت فایل از دو مسیر:
/// ۱. کاربر از یک اپ دیگه (تلگرام، فایل‌منیجر) روی گزینه‌ی «اشتراک‌گذاری» زده
///    و SFE رو به‌عنوان مقصد انتخاب کرده (Share Sheet).
/// ۲. کاربر مستقیم روی یک فایل زده و «باز کردن با SFE» رو انتخاب کرده.
class ShareIntentService {
  /// فایل‌هایی که وقتی اپ باز/در پس‌زمینه هست به اشتراک گذاشته میشن
  static void listen(void Function(List<String> paths) onFiles) {
    ReceiveSharingIntent.instance.getMediaStream().listen((value) {
      final paths = value.map((f) => f.path).toList();
      if (paths.isNotEmpty) onFiles(paths);
    });
  }

  /// فایلی که باعث باز شدن اپ از حالت کاملاً بسته (cold start) شده
  static Future<void> consumeInitial(
    void Function(List<String> paths) onFiles,
  ) async {
    final initial = await ReceiveSharingIntent.instance.getInitialMedia();
    final paths = initial.map((f) => f.path).toList();
    if (paths.isNotEmpty) onFiles(paths);
    ReceiveSharingIntent.instance.reset();
  }
}
