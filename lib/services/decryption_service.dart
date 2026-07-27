import 'dart:io';
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

      final outputFilename =
          (header.originalFilename != null && header.originalFilename!.isNotEmpty)
              ? header.originalFilename!
              : 'decrypted_file';

      outputPath = '$outputDirectory/$outputFilename';
      if (await File(outputPath).exists()) {
        final dot = outputFilename.lastIndexOf('.');
        final name = dot > 0 ? outputFilename.substring(0, dot) : outputFilename;
        final ext = dot > 0 ? outputFilename.substring(dot) : '';
        outputPath = '$outputDirectory/${name}_decrypted$ext';
      }

      outputFile = await File(outputPath).open(mode: FileMode.write);

      final totalSize = await inputFile.length();
      await CryptoEngine.decryptStream(
        inputFile,
        outputFile,
        key,
        header.nonce,
        onProgress: (processed) {
          if (totalSize > 0) onProgress?.call(processed / totalSize * 100);
        },
      );

      return OperationResult.ok(outputPath);
    } on FormatException catch (e) {
      return OperationResult.fail(e.message);
    } catch (e) {
      if (_isOutOfSpace(e)) {
        return OperationResult.fail(AppStrings.t('error_out_of_space'));
      }
      return OperationResult.fail('خطا: $e');
    } finally {
      await inputFile?.close();
      await outputFile?.close();
    }
  }

  bool _isOutOfSpace(Object e) {
    final msg = e.toString().toLowerCase();
    return msg.contains('no space left') || msg.contains('enospc');
  }
}
