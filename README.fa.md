# 🔐 SFE - رمزنگاری امن فایل

**ابزار رمزنگاری چندسکویی** برای ویندوز و اندروید با سازگاری کامل فرمت.

**🇮 فارسی** | [🇬🇧 English](README.md)

---

## 📖 درباره

SFE ابزاری برای رمزنگاری و رمزگشایی فایل‌ها با رمزنگاری مدرن و قدرتمند است. فایلی که در **ویندوز** رمزنگاری شود در **اندروید** باز می‌شود و برعکس.

- ✅ **چندسکویی**: فرمت `.sfe` یکسان در ویندوز و اندروید
- ✅ **رمزنگاری قوی**: XChaCha20-Poly1305 (استاندارد IETF)
- ✅ **KDF سخت‌گیر**: Argon2id نسخه ۱.۳ (مقاوم در برابر GPU/ASIC)
- ✅ **رابط مدرن**: تم تاریک Catppuccin، دوزبانه (فارسی/انگلیسی)، پشتیبانی RTL
- ✅ **کاربرپسند**: پیشرفت لحظه‌ای، آیکون وضعیت هر فایل، سناریوها
- ✅ **امن در طراحی**: محافظت Path Traversal، سقف‌های DoS، راستی‌آزمایی قبل از حذف
- ✅ **فایل‌های بزرگ**: پردازش chunkای (پیش‌فرض ۴ مگابایت، تا ۶۴ مگابایت)
- ✅ **محافظت متادیتا**: نام فایل و حجم اصلی رمزنگاری می‌شوند

---

## 🧬 مشخصات فنی

| جزء | مشخصات |
|---|---|
| رمزنگاری | XChaCha20-Poly1305 (IETF) |
| استخراج کلید | Argon2id v1.3 (RFC 9106) |
| پارامترهای Argon2 | ۴ دور، ۶۴ مگابایت حافظه، موازی‌سازی ۲ |
| Nonce / Salt | ۲۴ بایت / ۱۶ بایت |
| اندازه chunk | پیش‌فرض ۴ مگابایت (تنظیم‌پذیر تا ۶۴) |
| پسوند | `.sfe` |
| Magic Bytes | `SFE1` |

### ساختار فایل

```
┌───────────────────────────────────────────────────┐
│ Magic "SFE1"                                      │ 4 B
│ Version (2) + Algorithm (1)                       │ 2 B
│ Argon2: iterations, memory, parallelism           │ 12 B
│ Salt (16) + Nonce (24) + MetaNonce (24)           │ 64 B
│ Encrypted metadata: filename\0size (len-prefixed) │ var
│ Chunks: [len][ciphertext+tag] ...                 │ var
└───────────────────────────────────────────────────┘
```

فایل‌های قدیمی‌تر بدون پسوند حجم همچنان کاملاً سازگارند.

---

## 🚀 پلتفرم‌ها

| | ویندوز | اندروید |
|---|---|---|
| فناوری | C# / .NET 8 / WPF | Flutter 3 / Material 3 |
| کتابخانه رمزنگاری | Sodium.Core + Konscious Argon2id | پکیج `cryptography` (Dart خالص) |
| امکانات اضافه | سناریوها، حذف امن، بکاپ ZIP رمزدار | اشتراک از هر برنامه، قفل بیومتریک، تم روشن/تاریک |

---

## 📦 نصب

### ویندوز
```bash
git clone https://github.com/ip2300-p/SFE-Secure-File-Encoder-.git
cd SFE-Secure-File-Encoder-/windows
dotnet build -c Release
```

### اندروید
```bash
git clone https://github.com/ip2300-p/SFE-Secure-File-Encoder-.git
cd SFE-Secure-File-Encoder-/android
flutter pub get
flutter run
```

---

## 🎯 استفاده

**ویندوز**: اجرای `SFE.exe` → انتخاب فایل/پوشه (drag & drop) → وارد کردن رمز (در صورت دلخواه لایه دوم) → رمزنگاری/رمزگشایی → مشاهده وضعیت ✓/✗ هر فایل → ذخیره در پوشه انتخابی.

**اندروید**: باز کردن برنامه (یا share/open کردن فایل `.sfe` از برنامه دیگر) → افزودن فایل‌ها → وارد کردن رمز → رمزنگاری/رمزگشایی → ذخیره در پوشه پیش‌فرض، انتخاب مسیر، یا اشتراک‌گذاری.

- تنظیمات اندروید: حالت تاریک، زبان، قفل بیومتریک، نام مبدل، اندازه chunk، سناریوها.
- تنظیمات ویندوز: زبان، نام مبدل، فیلتر فایل‌ها، حذف امن، بکاپ رمزدار، سناریوها.

---

## 🔧 گزینه‌های پیکربندی

| گزینه | پیش‌فرض | پلتفرم |
|---|---|---|
| RandomizeFilename (سبک‌های CacheLike / DataLike / GuidShort) | false | هر دو |
| UseSecondaryPassword (رمز دولایه) | false | هر دو |
| ChunkSize | ۴ مگابایت | هر دو |
| DeleteOriginalAfterEncrypt | false | ویندوز (اندروید: فقط کپی موقت) |
| SecureDelete (بازنویسی ۳مرحله‌ای) | false | ویندوز |
| CreateBackup (ZIP رمزدار) | false | ویندوز |

---

## 🔒 امنیت

- کلیدها هرگز روی دیسک ذخیره نمی‌شوند و پس از استفاده از حافظه پاک می‌شوند.
- تولید اعداد تصادفی با CSPRNG (`RandomNumberGenerator.Fill` و `Random.secure()`).
- nonce یکتا برای هر chunk (nonce پایه ⊕ شمارنده)؛ nonce جداگانه برای متادیتا.
- **سخت‌سازی نسخه ۱.۱**: پاک‌سازی نام فایل (ضد Path Traversal)، سقف‌های DoS (متادیتا ۱ مگابایت، chunk ۶۴ مگابایت، پارامترهای Argon2)، راستی‌آزمایی قبل از حذف، پسوند برای نام‌های تکراری، نام مبدل ۸ کاراکتری، لاگ فقط با نام فایل.
- رمز قوی انتخاب کنید (۱۲+ کاراکتر). فراموشی رمز = غیرقابل بازیابی.

---

## ⚠️ محدودیت‌های شناخته‌شده

- اندروید به‌دلیل scoped storage نمی‌تواند فایل اصلی را حذف کند؛ حذف امن و بکاپ ZIP فقط در ویندوز است.
- سناریوهای اندروید فقط تنظیمات را ذخیره می‌کنند (نه مسیر فایل‌ها).
- همگام‌سازی ابری وجود ندارد؛ انتقال فایل دستی است.

---

## 📂 ساختار مخزن

```
SFE-Secure-File-Encoder-/
├── README.md / README.fa.md
├── LICENSE (MIT)
├── windows/
│   ├── SFE.UI/          # برنامه WPF (Views, ViewModels, Assets, App.xaml)
│   ├── SFE.Core/        # Crypto, FileFormat, Models
│   ├── SFE.Services/    # Encryption/Decryption/FileProcessor/Scenario
│   └── SFE.sln
└── android/
    ├── lib/core/        # crypto, file_format, models (Dart)
    ├── lib/services/    # encryption, settings, scenarios, localization
    ├── lib/screens/     # home, settings, lock
    └── pubspec.yaml
```

---

## 🛠️ توسعه

**پیش‌نیازها**: Visual Studio 2022 + .NET 8 SDK (ویندوز) · Flutter 3.x + Android SDK با minSdk 21 (اندروید).

```bash
# ویندوز
cd windows && dotnet restore && dotnet build -c Release
# اندروید
cd android && flutter clean && flutter pub get && flutter build apk --release
```

### چک‌لیست تست دستی
- [ ] رمزنگاری در ویندوز → رمزگشایی در اندروید (و برعکس)
- [ ] نام مبدل (هر ۳ سبک) + رمز دوم
- [ ] فایل بزرگ (>۱ گیگابایت)، لغو وسط عملیات
- [ ] فایل `.sfe` خراب/قطع‌شده
- [ ] قفل برنامه و سناریوها (اندروید)

---

## 🗺️ نقشه راه

| پلتفرم | وضعیت |
|---|---|
| ویندوز | 🟢 پایدار ۱.۱.۰ |
| اندروید | 🟢 پایدار ۱.۱.۰ |
| iOS (از طریق PWA) | 🔮 احتمال آینده |
| macOS / Linux بومی | ❌ در برنامه نیست |

ایده‌های آینده: PWA برای iOS، یکپارچگی اختیاری ابری، هسته WebAssembly.

---

## 🤝 مشارکت

Fork → شاخه (`feature/x`) → commit (پیام قراردادی) → push → PR.
سبک: `dotnet format` برای C# و `dart format` برای Dart.
گزارش باگ: پلتفرم، مراحل بازتولید، انتظار/واقعیت، در صورت امکان نمونه `.sfe`.

---

## 📄 مجوز

MIT — فایل [LICENSE](LICENSE) را ببینید.

## 📞 تماس

- مشکلات: https://github.com/ip2300-p/SFE-Secure-File-Encoder-/issues
- گفتگو: https://github.com/ip2300-p/SFE-Secure-File-Encoder-/discussions

---

**ساخته‌شده با ❤️ برای اشتراک امن فایل در همه سکوها**
