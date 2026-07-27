import 'dart:io';
import 'dart:typed_data';
import 'package:path/path.dart' as p;
import '../core/crypto/crypto_engine.dart';
import '../core/crypto/key_derivation.dart';
import '../core/file_format/sfe_file_writer.dart';
import '../core/models/sfe_header.dart';
import '../core/models/operation_result.dart';
import '../core/models/disguised_name.dart';
import 'localization_service.dart';

/// معادل EncryptionService.cs
/// قابلیت‌های بکاپ و حذف امن به‌عمد پورت نشدن (تصمیم گرفته شد که در اسکوپ
/// اندروید نیازی بهشون نیست).
class EncryptionService {
  Future<OperationResult> encryptFile(
    String inputPath,
    String outputDirectory,
    String password, {
    int chunkSize = CryptoEngine.defaultChunkSize,
    bool randomizeFilename = false,
    DisguisedNameStyle nameStyle = DisguisedNameStyle.cacheLike,
    void Function(double percent)? onProgress,
  }) async {
    String? finalOutputPath;

    try {
      final salt = KeyDerivation.generateSalt();
      final nonce = KeyDerivation.generateNonce();

      Uint8List metaNonce;
      do {
        metaNonce = KeyDerivation.generateNonce();
      } while (_bytesEqual(metaNonce, nonce));

      final key = await KeyDerivation.deriveKey(password, salt);

      final header = SfeHeader(
        salt: salt,
        nonce: nonce,
        metaNonce: metaNonce,
        originalFilename: p.basename(inputPath),
      );

      // نکته‌ی سازگاری: چه اسم واقعی رو نگه داریم چه اسم مستعار بذاریم،
      // اسم اصلی همیشه رمزشده داخل header ذخیره میشه (بالا)، پس روی
      // سازگاری با نسخه‌ی ویندوز هیچ اثری نداره.
      final outputFilename = randomizeFilename
          ? DisguisedNameGenerator.generate(nameStyle)
          : '${p.basename(inputPath)}.sfe';
      finalOutputPath = p.join(outputDirectory, outputFilename);

      final inputFile = await File(inputPath).open();
      final outputFile = await File(finalOutputPath).open(mode: FileMode.write);

      try {
        await SfeFileWriter.writeHeader(outputFile, header, key);

        final totalSize = await inputFile.length();
        await CryptoEngine.encryptStream(
          inputFile,
          outputFile,
          key,
          nonce,
          chunkSize: chunkSize,
          onProgress: (processed) {
            if (totalSize > 0) {
              onProgress?.call(processed / totalSize * 100);
            }
          },
        );
      } finally {
        await inputFile.close();
        await outputFile.close();
      }

      return OperationResult.ok(finalOutputPath);
    } catch (e) {
      // اگه خطا خورد، فایل ناقص رو پاک می‌کنیم
      try {
        if (finalOutputPath != null && await File(finalOutputPath).exists()) {
          await File(finalOutputPath).delete();
        }
      } catch (_) {}

      if (_isOutOfSpace(e)) {
        return OperationResult.fail(AppStrings.t('error_out_of_space'));
      }
      return OperationResult.fail('خطا: $e');
    }
  }

  /// تشخیص best-effort اینکه آیا خطا به‌خاطر تمام شدن فضای ذخیره‌سازی بوده
  bool _isOutOfSpace(Object e) {
    final msg = e.toString().toLowerCase();
    return msg.contains('no space left') || msg.contains('enospc');
  }

  bool _bytesEqual(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
