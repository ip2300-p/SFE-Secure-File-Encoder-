import 'dart:math';

/// معادل enum DisguisedNameStyle در EncryptionOptions.cs
enum DisguisedNameStyle { none, cacheLike, dataLike, guidShort }

/// معادل DisguisedNameGenerator در EncryptionOptions.cs
///
/// نکته: این اسم فقط پوسته‌ی ظاهری فایل روی دیسکه (برای گول زدن چشم در لیست
/// فایل‌ها). اسم واقعی فایل همچنان رمزنگاری‌شده داخل خود فایل ذخیره میشه و
/// موقع رمزگشایی درست بازیابی میشه - پس این تغییر هیچ اثری روی سازگاری فرمت
/// نداره.
class DisguisedNameGenerator {
  static final Random _rng = Random.secure();

  static const List<String> _cachePrefixes = [
    'cache_tmp',
    'cache_cfg',
    'cache_dat',
    'tmp_store',
    'sys_tmp',
  ];

  static const List<String> _dataPrefixes = [
    'data_cfg',
    'data_bin',
    'app_dat',
    'usr_cfg',
    'cfg_bin',
  ];

  static String generate(DisguisedNameStyle style) {
    final hex = _hexString(8).toUpperCase();

    switch (style) {
      case DisguisedNameStyle.cacheLike:
        return '${_cachePrefixes[_rng.nextInt(_cachePrefixes.length)]}_$hex.tmp';
      case DisguisedNameStyle.dataLike:
        return '${_dataPrefixes[_rng.nextInt(_dataPrefixes.length)]}_$hex.bin';
      case DisguisedNameStyle.guidShort:
        return _hexString(16);
      case DisguisedNameStyle.none:
        // دقیقاً معادل حالت پیش‌فرض (default case) در نسخه‌ی ویندوز
        return '${_hexString(32)}.sfe';
    }
  }

  static String _hexString(int length) {
    const chars = '0123456789abcdef';
    return List.generate(length, (_) => chars[_rng.nextInt(16)]).join();
  }
}
