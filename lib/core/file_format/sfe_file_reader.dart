import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';
import '../models/sfe_header.dart';

/// معادل SfeFileReader.cs
class SfeFileReader {
  static final _aead = Xchacha20.poly1305Aead();

  static Future<bool> isSfeFile(String path) async {
    RandomAccessFile? raf;
    try {
      raf = await File(path).open();
      final magic = await raf.read(4);
      return _bytesEqual(magic, SfeHeader.magicBytes);
    } catch (_) {
      return false;
    } finally {
      await raf?.close();
    }
  }

  static bool _bytesEqual(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  /// هدر رو می‌خونه. اگه key بدی، اسم فایل اصلی هم decrypt میشه.
  /// اگه key ندی (null)، فقط برای گرفتن salt و پارامترهای Argon2 استفاده میشه.
  static Future<SfeHeader> readHeader(
    RandomAccessFile raf, {
    Uint8List? key,
  }) async {
    final magic = await raf.read(4);
    if (!_bytesEqual(magic, SfeHeader.magicBytes)) {
      throw const FormatException('فایل معتبر SFE نیست.');
    }

    final version = (await raf.read(1))[0];
    final algorithmId = (await raf.read(1))[0];

    final iterations = _readUint32le(await raf.read(4));
    final memorySize = _readUint32le(await raf.read(4));
    final parallelism = _readUint32le(await raf.read(4));

    final salt = await raf.read(16);
    final nonce = await raf.read(24);
    final metaNonce = await raf.read(24);

    final metaLen = _readInt32le(await raf.read(4));
    final encryptedMeta = await raf.read(metaLen);

    final header = SfeHeader(
      version: version,
      algorithmId: algorithmId,
      salt: salt,
      nonce: nonce,
      metaNonce: metaNonce,
      iterations: iterations,
      memorySize: memorySize,
      degreeOfParallelism: parallelism,
    );

    if (key != null) {
      try {
        final cipherText = encryptedMeta.sublist(0, encryptedMeta.length - 16);
        final macBytes = encryptedMeta.sublist(encryptedMeta.length - 16);
        final secretBox = SecretBox(
          cipherText,
          nonce: header.metaNonce,
          mac: Mac(macBytes),
        );
        final decrypted =
            await _aead.decrypt(secretBox, secretKey: SecretKeyData(key));
        header.originalFilename = utf8.decode(decrypted);
      } catch (_) {
        throw const FormatException('رمز عبور اشتباه است.');
      }
    }

    return header;
  }

  static int _readUint32le(List<int> bytes) =>
      ByteData.sublistView(Uint8List.fromList(bytes)).getUint32(0, Endian.little);

  static int _readInt32le(List<int> bytes) =>
      ByteData.sublistView(Uint8List.fromList(bytes)).getInt32(0, Endian.little);
}
