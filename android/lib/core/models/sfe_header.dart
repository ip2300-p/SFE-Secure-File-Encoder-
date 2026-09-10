import 'dart:typed_data';

/// معادل SfeHeader.cs
/// این کلاس ساختار هدر فایل .sfe رو نگه می‌داره.
/// ترتیب و طول فیلدها دقیقاً باید با نسخه‌ی ویندوز یکی باشه، وگرنه فایل‌ها خونده نمیشن.
class SfeHeader {
  // "SFE1" -> 0x53 0x46 0x45 0x31
  static const List<int> magicBytes = [0x53, 0x46, 0x45, 0x31];

  int version;
  int algorithmId;

  Uint8List salt; // 16 بایت
  Uint8List nonce; // 24 بایت - nonce پایه برای رمزنگاری محتوا
  Uint8List metaNonce; // 24 بایت - nonce جدا برای رمزنگاری اسم فایل

  int iterations; // پارامتر Argon2id
  int memorySize; // پارامتر Argon2id - بر حسب KiB
  int degreeOfParallelism; // پارامتر Argon2id

  // این فیلدها در بایت‌های خام هدر ذخیره نمیشن؛ داخل همون metadata رمزشده
  // (کنار اسم فایل) جا می‌گیرن، پس فرمت باینری هدر دست‌نخورده می‌مونه.
  String? originalFilename;
  int? originalFileSize; // بر حسب بایت - برای تشخیص فایل ناقص بعد از decrypt

  SfeHeader({
    this.version = 2,
    this.algorithmId = 1,
    required this.salt,
    required this.nonce,
    required this.metaNonce,
    this.iterations = 4,
    this.memorySize = 65536,
    this.degreeOfParallelism = 2,
    this.originalFilename,
    this.originalFileSize,
  });
}
