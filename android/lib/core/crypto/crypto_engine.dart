import 'dart:io';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';

/// معادل CryptoEngine.cs
/// رمزنگاری/رمزگشایی chunk به chunk با XChaCha20-Poly1305 (ساختار IETF ترکیبی:
/// ciphertext + 16 بایت tag پشت سرهم، دقیقاً مثل خروجی Sodium.Core در نسخه‌ی ویندوز)
class CryptoEngine {
  static const int defaultChunkSize = 4 * 1024 * 1024; // 4MB
  static const int _macLength = 16;

  static final _aead = Xchacha20.poly1305Aead();

  // nonce هر chunk = baseNonce با 8 بایت آخر XOR شده با شماره chunk (little-endian)
  static Uint8List _deriveChunkNonce(Uint8List baseNonce, int chunkIndex) {
    final chunkNonce = Uint8List.fromList(baseNonce);
    final indexBytes = ByteData(8)..setInt64(0, chunkIndex, Endian.little);
    for (int i = 0; i < 8; i++) {
      chunkNonce[baseNonce.length - 8 + i] ^= indexBytes.getUint8(i);
    }
    return chunkNonce;
  }

  static Future<void> encryptStream(
    RandomAccessFile input,
    RandomAccessFile output,
    Uint8List key,
    Uint8List baseNonce, {
    int chunkSize = defaultChunkSize,
    void Function(int processedBytes)? onProgress,
  }) async {
    final secretKey = SecretKeyData(key);
    int chunkIndex = 0;
    int totalRead = 0;

    while (true) {
      final chunk = await input.read(chunkSize);
      if (chunk.isEmpty) break;

      final chunkNonce = _deriveChunkNonce(baseNonce, chunkIndex);
      final secretBox = await _aead.encrypt(
        chunk,
        secretKey: secretKey,
        nonce: chunkNonce,
      );

      // ciphertext + tag پشت سر هم، همون فرمتی که ویندوز می‌نویسه
      final encrypted = Uint8List(secretBox.cipherText.length + _macLength);
      encrypted.setRange(0, secretBox.cipherText.length, secretBox.cipherText);
      encrypted.setRange(
          secretBox.cipherText.length, encrypted.length, secretBox.mac.bytes);

      final lengthBytes = ByteData(4)
        ..setInt32(0, encrypted.length, Endian.little);
      await output.writeFrom(lengthBytes.buffer.asUint8List());
      await output.writeFrom(encrypted);

      // پیشرفت بر اساس حجم خام خونده‌شده از فایل ورودی (همون واحدی که
      // totalSize در EncryptionService بر مبنای اون حساب میشه)
      totalRead += chunk.length;
      chunkIndex++;
      onProgress?.call(totalRead);
    }
  }

  static Future<void> decryptStream(
    RandomAccessFile input,
    RandomAccessFile output,
    Uint8List key,
    Uint8List baseNonce, {
    void Function(int processedBytes)? onProgress,
  }) async {
    final secretKey = SecretKeyData(key);
    int chunkIndex = 0;
    int totalRead = 0;

    while (true) {
      final lengthBuffer = await input.read(4);

      // ۰ بایت خوندیم = پایان طبیعی فایل
      if (lengthBuffer.isEmpty) break;

      // کمتر از ۴ بایت = فایل ناقص/آسیب‌دیده (نصفه کپی شده و غیره)
      if (lengthBuffer.length < 4) {
        throw const FormatException(
            'فایل ناقص یا آسیب‌دیده است (هدر chunk ناقص).');
      }

      final chunkLength =
          ByteData.sublistView(lengthBuffer).getInt32(0, Endian.little);

      // 🆕 سقف منطقی: بزرگ‌ترین chunk مجاز در هر دو پلتفرم + تگ MAC (جلوگیری از DoS)
      const maxChunkLength = 64 * 1024 * 1024;
      if (chunkLength < _macLength || chunkLength > maxChunkLength) {
        throw const FormatException('فایل آسیب‌دیده است (طول chunk نامعتبر).');
      }

      final encryptedChunk = await input.read(chunkLength);
      if (encryptedChunk.length < chunkLength) {
        throw const FormatException('فایل ناقص یا آسیب‌دیده است (chunk ناقص).');
      }

      final chunkNonce = _deriveChunkNonce(baseNonce, chunkIndex);
      final cipherText = encryptedChunk.sublist(0, chunkLength - _macLength);
      final macBytes = encryptedChunk.sublist(chunkLength - _macLength);

      List<int> decrypted;
      try {
        final secretBox = SecretBox(
          cipherText,
          nonce: chunkNonce,
          mac: Mac(macBytes),
        );
        decrypted = await _aead.decrypt(secretBox, secretKey: secretKey);
      } on SecretBoxAuthenticationError {
        throw const FormatException('رمز عبور اشتباه است یا فایل آسیب دیده.');
      } catch (e) {
        // خطاهای دیگه (مثلاً کمبود حافظه حین decrypt) رو هم واضح گزارش بده
        throw FormatException('خطای رمزگشایی: $e');
      }

      await output.writeFrom(decrypted);

      // نکته‌ی مهم: بر اساس حجم decrypted شده جمع می‌زنیم (نه chunkLength
      // رمزشده‌ی روی دیسک که ۱۶ بایت tag رو هم داخلش داره) تا با totalSize
      // (که در DecryptionService بر مبنای حجم واقعی payload حساب میشه)
      // هماهنگ باشه و درصد پیشرفت دقیق‌تر بشه.
      totalRead += decrypted.length;
      chunkIndex++;
      onProgress?.call(totalRead);
    }
  }
}
