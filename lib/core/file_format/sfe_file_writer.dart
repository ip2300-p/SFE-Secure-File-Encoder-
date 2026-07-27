import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';
import '../models/sfe_header.dart';

/// معادل SfeFileWriter.cs
/// ترتیب نوشتن بایت‌ها دقیقاً باید با نسخه‌ی ویندوز یکی باشه.
class SfeFileWriter {
  static final _aead = Xchacha20.poly1305Aead();

  static Future<void> writeHeader(
    RandomAccessFile raf,
    SfeHeader header,
    Uint8List key,
  ) async {
    // Magic Bytes
    await raf.writeFrom(Uint8List.fromList(SfeHeader.magicBytes));

    // Version & Algorithm (هر کدوم ۱ بایت)
    await raf.writeFrom(Uint8List.fromList([header.version]));
    await raf.writeFrom(Uint8List.fromList([header.algorithmId]));

    // پارامترهای Argon2 (لازمه تا بشه دوباره key رو ساخت)
    await raf.writeFrom(_uint32le(header.iterations));
    await raf.writeFrom(_uint32le(header.memorySize));
    await raf.writeFrom(_uint32le(header.degreeOfParallelism));

    // Salt و Nonce اصلی
    await raf.writeFrom(header.salt);
    await raf.writeFrom(header.nonce);

    // MetaNonce - برای رمزنگاری اسم فایل
    await raf.writeFrom(header.metaNonce);

    // رمزنگاری اسم فایل
    final filename = header.originalFilename ?? 'unknown';
    final filenameBytes = utf8.encode(filename);

    final secretBox = await _aead.encrypt(
      filenameBytes,
      secretKey: SecretKeyData(key),
      nonce: header.metaNonce,
    );

    final encryptedMeta =
        Uint8List(secretBox.cipherText.length + secretBox.mac.bytes.length);
    encryptedMeta.setRange(
        0, secretBox.cipherText.length, secretBox.cipherText);
    encryptedMeta.setRange(
        secretBox.cipherText.length, encryptedMeta.length, secretBox.mac.bytes);

    await raf.writeFrom(_int32le(encryptedMeta.length));
    await raf.writeFrom(encryptedMeta);
  }

  static Uint8List _uint32le(int value) {
    final b = ByteData(4);
    b.setUint32(0, value, Endian.little);
    return b.buffer.asUint8List();
  }

  static Uint8List _int32le(int value) {
    final b = ByteData(4);
    b.setInt32(0, value, Endian.little);
    return b.buffer.asUint8List();
  }
}
