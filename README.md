# 🔐 SFE - Secure File Encryption

**Cross-platform encryption tool** for Windows and Android with full format compatibility.

**🇬🇧 English** | [🇮🇷 فارسی](README.fa.md)

---

## 📖 About

SFE (Secure File Encryption) encrypts and decrypts files with strong, modern cryptography. Files encrypted on **Windows** can be decrypted on **Android** and vice versa.

- ✅ **Cross-platform**: identical `.sfe` format on Windows & Android
- ✅ **Strong encryption**: XChaCha20-Poly1305 (IETF)
- ✅ **Memory-hard KDF**: Argon2id v1.3 (GPU/ASIC resistant)
- ✅ **Modern UI**: Catppuccin dark theme, bilingual (Persian/English), RTL support
- ✅ **User-friendly**: real-time progress, per-file status icons, scenarios
- ✅ **Secure by design**: path-traversal protection, DoS limits, pre-deletion verification
- ✅ **Large files**: chunked processing (4 MB default, up to 64 MB)
- ✅ **Metadata protection**: filename & original size encrypted

---

## 🧬 Technical Specifications

| Component | Specification |
|---|---|
| Encryption | XChaCha20-Poly1305 (IETF) |
| Key derivation | Argon2id v1.3 (RFC 9106) |
| Argon2 parameters | 4 iterations, 64 MiB memory, parallelism 2 |
| Nonce / Salt | 24 bytes / 16 bytes |
| Chunk size | 4 MB default (configurable, max 64 MB) |
| Extension | `.sfe` |
| Magic bytes | `SFE1` |

### File format

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

Older files without the size suffix stay fully compatible.

---

## 🚀 Platforms

| | Windows | Android |
|---|---|---|
| Stack | C# / .NET 8 / WPF | Flutter 3 / Material 3 |
| Crypto libs | Sodium.Core + Konscious Argon2id | `cryptography` (pure Dart) |
| Extras | scenarios, secure delete, encrypted ZIP backup | share-from-anywhere, biometric app lock, light/dark theme |

---

## 📦 Installation

### Windows
```bash
git clone https://github.com/ip2300-p/SFE-Secure-File-Encoder-.git
cd SFE-Secure-File-Encoder-/windows
dotnet build -c Release
```

### Android
```bash
git clone https://github.com/ip2300-p/SFE-Secure-File-Encoder-.git
cd SFE-Secure-File-Encoder-/android
flutter pub get
flutter run
```

---

## 🎯 Usage

**Windows**: run `SFE.exe` → pick files/folders (drag & drop) → enter password (optional second layer) → Encrypt/Decrypt → watch per-file ✓/✗ status → output saved to chosen folder.

**Android**: open the app (or share/open a `.sfe` from another app) → add files → enter password → Encrypt/Decrypt → save to chosen folder, pick a location, or share.

- Settings (Android): dark mode, language, biometric app lock, disguised filenames, chunk size, scenarios.
- Settings (Windows): language, disguised filenames, file filters, secure delete, encrypted backup, scenarios.

---

## 🔧 Configuration Options

| Option | Default | Platform |
|---|---|---|
| RandomizeFilename (CacheLike / DataLike / GuidShort) | false | both |
| UseSecondaryPassword (two-layer key) | false | both |
| ChunkSize | 4 MB | both |
| DeleteOriginalAfterEncrypt | false | Windows (Android: temp copy only) |
| SecureDelete (3-pass overwrite) | false | Windows |
| CreateBackup (encrypted ZIP) | false | Windows |

---

## 🔒 Security

- Keys never touch disk; zeroed from memory after use (`CryptographicOperations.ZeroMemory` / explicit wipe).
- CSPRNG everywhere (`RandomNumberGenerator.Fill`, `Random.secure()`).
- Unique nonce per chunk (base nonce ⊕ counter); separate meta nonce.
- **v1.1 hardening**: path-traversal sanitization, DoS caps (metadata 1 MB, chunk 64 MB, Argon2 params), verify-before-delete, filename collision suffixes, 8-hex disguised names, privacy-safe logs (filenames only).
- Use a strong password (12+ chars). Forgotten password = no recovery.

---

## ⚠️ Known Limitations

- Android cannot delete the original source file (scoped storage); secure delete & ZIP backup are Windows-only.
- Android scenarios store settings only (no source paths).
- No cloud sync; files move manually between devices.

---

## 📂 Repository Structure

```
SFE-Secure-File-Encoder-/
├── README.md / README.fa.md
├── LICENSE (MIT)
├── windows/
│   ├── SFE.UI/          # WPF app (Views, ViewModels, Assets, App.xaml)
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

## 🛠️ Development

**Prerequisites**: Visual Studio 2022 + .NET 8 SDK (Windows) · Flutter 3.x + Android SDK, minSdk 21 (Android).

```bash
# Windows
cd windows && dotnet restore && dotnet build -c Release
# Android
cd android && flutter clean && flutter pub get && flutter build apk --release
```

### Manual test checklist
- [ ] Encrypt on Windows → decrypt on Android (and vice versa)
- [ ] Disguised names (all 3 styles) + secondary password
- [ ] Large file (>1 GB), cancel mid-operation
- [ ] Corrupted/truncated `.sfe`
- [ ] App lock & scenarios (Android)

---

## 🗺️ Roadmap

| Platform | Status |
|---|---|
| Windows | 🟢 Stable 1.1.0 |
| Android | 🟢 Stable 1.1.0 |
| iOS (via PWA) | 🔮 Possible future |
| macOS / Linux native | ❌ Not planned |

Future ideas: PWA for iOS, optional cloud integration, WebAssembly core.

---

## 🤝 Contributing

Fork → branch (`feature/x`) → commit (conventional messages) → push → PR.
Style: `dotnet format` (C#), `dart format` (Dart).
Bug reports: platform, steps, expected/actual, sample `.sfe` if possible.

---

## 📄 License

MIT — see [LICENSE](LICENSE).

## 📞 Contact

- Issues: https://github.com/ip2300-p/SFE-Secure-File-Encoder-/issues
- Discussions: https://github.com/ip2300-p/SFE-Secure-File-Encoder-/discussions

---

**Built with ❤️ for secure file sharing across platforms**
