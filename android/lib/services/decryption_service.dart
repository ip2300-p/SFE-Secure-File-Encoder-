import 'dart:io';
import 'package:path/path.dart' as p;
import '../core/crypto/crypto_engine.dart';
import '../core/crypto/key_derivation.dart';
import '../core/file_format/sfe_file_reader.dart';
import '../core/models/operation_result.dart';
import 'localization_service.dart';

/// معادل DecryptionService.cs
class DecryptionService {
  Future<OperationResult> decryptFile(
    String inputPath,
    String outputDirectory,
    String password, {
    void Function(double percent)? onProgress,
  }) async {
    RandomAccessFile? inputFile;
    RandomAccessFile? outputFile;
    String? outputPath;

    try {
      inputFile = await File(inputPath).open();

      // مرحله ۱: خوندن هدر بدون key، فقط برای گرفتن salt و پارامترهای Argon2
      final headerPartial = await SfeFileReader.readHeader(inputFile);

      final key = await KeyDerivation.deriveKey(
        password,
        headerPartial.salt,
        iterations: headerPartial.iterations,
        memorySize: headerPartial.memorySize,
        parallelism: headerPartial.degreeOfParallelism,
      );

      // مرحله ۲: از اول می‌خونیم تا اسم فایل هم decrypt بشه
      await inputFile.setPosition(0);
      final header = await SfeFileReader.readHeader(inputFile, key: key);

      // موقعیت فعلی = دقیقاً جایی که هدر تموم شده و داده‌ی رمزشده شروع میشه.
      // این رو برای محاسبه‌ی دقیق‌تر درصد پیشرفت لازم داریم (چون حجم کل
      // فایل شامل هدر هم میشه، ولی CryptoEngine فقط روی payload کار می‌کنه).
      final headerSize = await inputFile.position();
      final totalFileSize = await inputFile.length();
      final payloadSize = totalFileSize - headerSize;

      final rawName =
      (header.originalFilename != null && header.originalFilename!.isNotEmpty)
          ? header.originalFilename!
          : 'decrypted_file';
      // 🆕 جلوگیری از Path Traversal: حذف هرگونه مسیر از نام فایل
      final baseName = p.basename(rawName);
      final outputFilename = baseName.isEmpty ? 'decrypted_file' : baseName;
      outputPath = '$outputDirectory/$outputFilename';
      if (await File(outputPath).exists()) {
        final dot = outputFilename.lastIndexOf('.');
        final name = dot > 0 ? outputFilename.substring(0, dot) : outputFilename;
        final ext = dot > 0 ? outputFilename.substring(dot) : '';
        outputPath = '$outputDirectory/${name}_decrypted$ext';
      }

      outputFile = await File(outputPath).open(mode: FileMode.write);

      await CryptoEngine.decryptStream(
        inputFile,
        outputFile,
        key,
        header.nonce,
        onProgress: (processed) {
          if (payloadSize > 0) onProgress?.call(processed / payloadSize * 100);
        },
      );

      // اگه حجم فایل اصلی رو داشتیم (فایل‌های جدیدتر)، با حجم واقعی خروجی
      // مقایسه می‌کنیم. اگه فرق داشت یعنی فایل رمزشده از انتها قطع/ناقص
      // بوده (چون هر chunk جدا معتبره، decrypt ممکنه بدون خطا تموم بشه ولی
      // خروجی کوتاه‌تر از حد انتظار باشه).
      if (header.originalFileSize != null) {
        await outputFile.close();
        outputFile = null;
        final actualSize = await File(outputPath).length();
        if (actualSize != header.originalFileSize) {
          await _cleanupPartialFile(outputPath);
          return OperationResult.fail(AppStrings.t('error_incomplete_file'));
        }
      }

      return OperationResult.ok(outputPath);
    } on FormatException catch (e) {
      // نکته‌ی مهم: این رایج‌ترین حالت خطاست (رمز اشتباه یا فایل خراب) و
      // قبلاً پاک‌سازی فایل ناقص رو نداشت - همینجا هم باید پاک بشه.
      await _cleanupPartialFile(outputPath);
      return OperationResult.fail(e.message);
    } catch (e) {
      await _cleanupPartialFile(outputPath);

      if (_isOutOfSpace(e)) {
        return OperationResult.fail(AppStrings.t('error_out_of_space'));
      }
      if (_isOutOfMemory(e)) {
        return OperationResult.fail(AppStrings.t('error_out_of_memory'));
      }
      return OperationResult.fail('خطا: $e');
    } finally {
      await inputFile?.close();
      await outputFile?.close();
    }
  }

  Future<void> _cleanupPartialFile(String? path) async {
    try {
      if (path != null && await File(path).exists()) {
        await File(path).delete();
      }
    } catch (_) {}
  }

  bool _isOutOfSpace(Object e) {
    final msg = e.toString().toLowerCase();
    return msg.contains('no space left') || msg.contains('enospc');
  }

  bool _isOutOfMemory(Object e) {
    final msg = e.toString().toLowerCase();
    return msg.contains('out of memory') ||
        msg.contains('outofmemory') ||
        msg.contains(' oom') ||
        msg.contains('failed to allocate');
  }
}
