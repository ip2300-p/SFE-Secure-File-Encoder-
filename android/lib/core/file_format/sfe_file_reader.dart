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

    // چک کردن نسخه و الگوریتم - جلوی تلاش برای parse کردن یک فرمت ناشناس
    // (یا فایل خراب/دستکاری‌شده) رو با یه پیام واضح می‌گیره، به‌جای کرش یا
    // نتیجه‌ی نامشخص
    if (version != 2) {
      throw FormatException('نسخه‌ی فایل پشتیبانی نمی‌شود: $version');
    }
    if (algorithmId != 1) {
      throw FormatException('الگوریتم نامعتبر است: $algorithmId');
    }

    final iterations = _readUint32le(await raf.read(4));
    final memorySize = _readUint32le(await raf.read(4));
    final parallelism = _readUint32le(await raf.read(4));
    // 🆕 سقف پارامترهای Argon2 (جلوگیری از DoS حافظه با فایل مخرب/خراب)
    const maxIterations = 64;
    const maxMemorySize = 1048576; // 1GB بر حسب KiB
    const maxParallelism = 16;
    if (iterations == 0 || iterations > maxIterations) {
      throw FormatException('پارامترهای Argon2 نامعتبر است: iterations=$iterations');
    }
    if (memorySize == 0 || memorySize > maxMemorySize) {
      throw FormatException('پارامترهای Argon2 نامعتبر است: memorySize=$memorySize');
    }
    if (parallelism == 0 || parallelism > maxParallelism) {
      throw FormatException('پارامترهای Argon2 نامعتبر است: parallelism=$parallelism');
    }

    final salt = await raf.read(16);
    final nonce = await raf.read(24);
    final metaNonce = await raf.read(24);

    final metaLenBytes = await raf.read(4);
    if (metaLenBytes.length < 4) {
      throw const FormatException('فایل ناقص است (طول metadata ناقص).');
    }
    final metaLen = _readInt32le(metaLenBytes);

    // سقف منطقی برای طول metadata (اسم فایل رمزشده) - جلوی تخصیص حافظه‌ی
    // بی‌رویه به‌خاطر یک فایل خراب یا دستکاری‌شده رو می‌گیره
    const maxMetaLen = 1024 * 1024; // هماهنگ با سقف نسخه‌ی ویندوز
    if (metaLen < 0 || metaLen > maxMetaLen) {
      throw FormatException('طول metadata نامعتبر است: $metaLen');
    }

    final encryptedMeta = await raf.read(metaLen);
    if (encryptedMeta.length < metaLen) {
      throw const FormatException('فایل ناقص است (metadata ناقص).');
    }

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
        final metaString = utf8.decode(decrypted);

        // فرمت: "اسم‌فایل\x00حجم" - اگه \x00 نبود (فایل قدیمی‌تر)، کل رشته
        // اسم فایله و originalFileSize خالی می‌مونه (یعنی چک نمیشه)
        final nullIndex = metaString.indexOf('\u0000');
        if (nullIndex >= 0) {
          header.originalFilename = metaString.substring(0, nullIndex);
          header.originalFileSize =
              int.tryParse(metaString.substring(nullIndex + 1));
        } else {
          header.originalFilename = metaString;
        }
      } catch (_) {
        throw const FormatException('رمز عبور اشتباه است.');
      }
    }

    return header;
  }

  // نکته: raf.read(n) خودش از قبل Uint8List برمی‌گردونه، پس مستقیم ازش
  // استفاده می‌کنیم به‌جای Uint8List.fromList(bytes) که یه کپی اضافه‌ی
  // بی‌مورد از حافظه می‌سازه.
  static int _readUint32le(Uint8List bytes) =>
      ByteData.sublistView(bytes).getUint32(0, Endian.little);

  static int _readInt32le(Uint8List bytes) =>
      ByteData.sublistView(bytes).getInt32(0, Endian.little);
}
