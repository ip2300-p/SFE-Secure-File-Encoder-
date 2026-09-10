import 'dart:io';
import 'package:path/path.dart' as p;
import '../core/crypto/crypto_engine.dart';
import '../core/crypto/key_derivation.dart';
import '../core/file_format/sfe_file_writer.dart';
import '../core/models/sfe_header.dart';
import '../core/models/operation_result.dart';
import '../core/models/disguised_name.dart';
import 'localization_service.dart';

/// معادل EncryptionService.cs
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
    RandomAccessFile? inputFile;
    RandomAccessFile? outputFile;

    try {
      final salt = KeyDerivation.generateSalt();
      final nonce = KeyDerivation.generateNonce();

      // نکته: nonce و metaNonce هر کدوم ۲۴ بایت کاملاً تصادفی (۱۹۲ بیت) هستن.
      // احتمال برابر شدن تصادفی‌شون (۲^-۱۹۲) عملاً صفره - دقیقاً همون دلیلی
      // که XChaCha20 با nonce بلند طراحی شده تا نیازی به چک یکتایی نباشه.
      final metaNonce = KeyDerivation.generateNonce();

      final key = await KeyDerivation.deriveKey(password, salt);

      inputFile = await File(inputPath).open();
      final totalSize = await inputFile.length();

      final header = SfeHeader(
        salt: salt,
        nonce: nonce,
        metaNonce: metaNonce,
        originalFilename: p.basename(inputPath),
        originalFileSize: totalSize,
      );

      final outputFilename = randomizeFilename
          ? DisguisedNameGenerator.generate(nameStyle)
          : '${p.basename(inputPath)}.sfe';
      // 🆕 جلوگیری از بازنویسی بی‌صدای فایل هم‌نام (جلوگیری از نابودی داده)
      var effectivePath = p.join(outputDirectory, outputFilename);
      if (await File(effectivePath).exists()) {
        final dot = outputFilename.lastIndexOf('.');
        final base = dot > 0 ? outputFilename.substring(0, dot) : outputFilename;
        final ext = dot > 0 ? outputFilename.substring(dot) : '';
        var i = 1;
        while (await File(effectivePath).exists()) {
          effectivePath = p.join(outputDirectory, '${base}_$i$ext');
          i++;
        }
      }
      finalOutputPath = effectivePath;
      outputFile = await File(effectivePath).open(mode: FileMode.write);

      await SfeFileWriter.writeHeader(outputFile, header, key);

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

      return OperationResult.ok(finalOutputPath);
    } catch (e) {
      await _cleanupPartialFile(finalOutputPath);

      if (_isOutOfSpace(e)) {
        return OperationResult.fail(AppStrings.t('error_out_of_space'));
      }
      if (_isOutOfMemory(e)) {
        return OperationResult.fail(AppStrings.t('error_out_of_memory'));
      }
      return OperationResult.fail('خطا: $e');
    } finally {
      // با چک null، هر دو فایل رو (حتی اگه فقط یکی‌شون باز شده باشه) می‌بندیم
      await inputFile?.close();
      await outputFile?.close();
    }
  }

  Future<void> _cleanupPartialFile(String? path) async {
    try {
      if (path != null && await File(path).exists()) {
        await File(path).delete();
      }
    } catch (_) {
      // اگه پاک کردن هم با خطا مواجه شد، دیگه کاری نمی‌تونیم بکنیم؛ خطای
      // اصلی (که باعث ورود به catch شده) مهم‌تر از این خطای ثانویه‌ست.
    }
  }

  /// تشخیص best-effort اینکه آیا خطا به‌خاطر تمام شدن فضای ذخیره‌سازی بوده
  bool _isOutOfSpace(Object e) {
    final msg = e.toString().toLowerCase();
    return msg.contains('no space left') || msg.contains('enospc');
  }

  /// تشخیص best-effort اینکه آیا خطا به‌خاطر کمبود حافظه‌ی RAM (نه فضای
  /// دیسک) بوده - مثلاً وقتی گوشی قدیمی نمی‌تونه ۶۴ مگابایت برای Argon2id
  /// تخصیص بده. این با _isOutOfSpace فرق داره چون اون درباره‌ی دیسکه.
  bool _isOutOfMemory(Object e) {
    final msg = e.toString().toLowerCase();
    return msg.contains('out of memory') ||
        msg.contains('outofmemory') ||
        msg.contains(' oom') ||
        msg.contains('failed to allocate');
  }
}
