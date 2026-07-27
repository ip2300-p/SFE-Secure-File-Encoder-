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
      if (lengthBuffer.length < 4) break; // به انتهای فایل رسیدیم

      final chunkLength =
          ByteData.sublistView(lengthBuffer).getInt32(0, Endian.little);

      if (chunkLength < _macLength) {
        throw const FormatException('فایل آسیب‌دیده است (طول chunk نامعتبر).');
      }

      final encryptedChunk = await input.read(chunkLength);
      if (encryptedChunk.length < chunkLength) {
        throw const FormatException('فایل ناقص یا آسیب‌دیده است.');
      }

      final chunkNonce = _deriveChunkNonce(baseNonce, chunkIndex);
      final cipherText =
          encryptedChunk.sublist(0, chunkLength - _macLength);
      final macBytes = encryptedChunk.sublist(chunkLength - _macLength);

      List<int> decrypted;
      try {
        final secretBox = SecretBox(
          cipherText,
          nonce: chunkNonce,
          mac: Mac(macBytes),
        );
        decrypted = await _aead.decrypt(secretBox, secretKey: secretKey);
      } catch (_) {
        throw const FormatException(
            'رمز عبور اشتباه است یا فایل آسیب دیده.');
      }

      await output.writeFrom(decrypted);

      totalRead += chunkLength;
      chunkIndex++;
      onProgress?.call(totalRead);
    }
  }
}
