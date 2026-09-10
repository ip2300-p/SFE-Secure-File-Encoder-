import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:cryptography/cryptography.dart';

/// معادل KeyDerivation.cs
///
/// نکته‌ی مهم سازگاری:
/// نسخه‌ی ویندوز از Konscious.Security.Cryptography.Argon2id استفاده می‌کنه که
/// پیاده‌سازی استاندارد Argon2 (نسخه‌ی 0x13 / RFC 9106) هست و واحد حافظه رو بر
/// حسب KiB می‌گیره. اینجا از Argon2id خود پکیج cryptography استفاده می‌کنیم که
/// یک پیاده‌سازی خالص Dart از همون استاندارده (بدون هیچ کتابخانه‌ی native، پس
/// دیگه مشکل بارگذاری .so پیش نمیاد). چون پارامترها (iterations, memory بر
/// حسب KiB, parallelism, salt) دقیقاً یکی هستن، خروجی هم باید دقیقاً یکی بشه.
///
/// چون Argon2id عمداً کند و سنگینه، محاسبه رو در یک Isolate جدا (پس‌زمینه)
/// اجرا می‌کنیم تا رابط کاربری برنامه در حین محاسبه فریز نشه.
class KeyDerivation {
  static Future<Uint8List> deriveKey(
    String password,
    Uint8List salt, {
    int iterations = 4,
    int memorySize = 65536, // KiB - همون واحدی که Konscious استفاده می‌کنه
    int parallelism = 2,
  }) {
    final params = _Argon2Params(
      password: password,
      salt: salt,
      iterations: iterations,
      memorySize: memorySize,
      parallelism: parallelism,
    );
    return compute(_deriveKeyIsolate, params);
  }

  static Uint8List generateSalt() => _randomBytes(16);

  static Uint8List generateNonce() => _randomBytes(24);

  static Uint8List _randomBytes(int length) {
    final rnd = Random.secure();
    return Uint8List.fromList(
      List<int>.generate(length, (_) => rnd.nextInt(256)),
    );
  }
}

class _Argon2Params {
  final String password;
  final Uint8List salt;
  final int iterations;
  final int memorySize;
  final int parallelism;

  _Argon2Params({
    required this.password,
    required this.salt,
    required this.iterations,
    required this.memorySize,
    required this.parallelism,
  });
}

// این تابع باید top-level یا static باشه تا compute() بتونه در Isolate
// جدا اجراش کنه.
Future<Uint8List> _deriveKeyIsolate(_Argon2Params p) async {
  final algorithm = Argon2id(
    parallelism: p.parallelism,
    memory: p.memorySize,
    iterations: p.iterations,
    hashLength: 32,
  );

  final secretKey = await algorithm.deriveKeyFromPassword(
    password: p.password,
    nonce: p.salt, // در این پکیج، پارامتر nonce همون salt الگوریتم Argon2 است
  );

  final bytes = await secretKey.extractBytes();
  return Uint8List.fromList(bytes);
}
