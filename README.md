# 🔐 SFE - Secure File Encryption

**Cross-platform encryption tool** for Windows and Android with full format compatibility.

[![Flutter](https://img.shields.io/badge/Android-Flutter-blue?logo=flutter)](https://flutter.dev) [![.NET](https://img.shields.io/badge/Windows-.NET-purple?logo=dotnet)](https://dotnet.microsoft.com) [![License](https://img.shields.io/badge/license-MIT-green)](https://github.com/ip2300-p/SFE-Secure-File-Encoder-/blob/main/LICENSE)

---

## 📖 About

SFE (Secure File Encryption) is a cross-platform encryption tool that allows you to encrypt and decrypt files using strong cryptography. Files encrypted on **Windows** can be decrypted on **Android** and vice versa.

### Why SFE?

- ✅ **Cross-platform**: Windows + Android support
- ✅ **Strong encryption**: XChaCha20-Poly1305 (highly secure)
- ✅ **Memory-hard KDF**: Argon2id (resistant to GPU/ASIC attacks)
- ✅ **Compatible format**: Same `.sfe` file structure across platforms
- ✅ **Chunk-based**: Handles large files efficiently (4 MB chunks by default, configurable on Android)
- ✅ **Metadata protection**: Filename (and original file size) is encrypted too

---

## 🧬 Technical Specifications

| Component             | Specification                                 |
| ---------------------- | --------------------------------------------- |
| **Encryption**        | XChaCha20-Poly1305 (IETF)                     |
| **Key Derivation**    | Argon2id (v1.3)                               |
| **Argon2 Parameters** | Iterations: 4, Memory: 64 MiB, Parallelism: 2 |
| **Nonce Size**        | 24 bytes (XChaCha20)                          |
| **Salt Size**         | 16 bytes                                      |
| **Chunk Size**        | 4 MB (default, adjustable on Android)         |
| **File Extension**    | `.sfe`                                        |
| **Magic Bytes**       | `SFE1` (0x53 0x46 0x45 0x31)                  |

### File Format Structure

```
┌─────────────────────────────────────────────────────────┐
│ Magic Bytes (SFE1)                                     │ 4 bytes
├─────────────────────────────────────────────────────────┤
│ Version (2) + Algorithm (1)                            │ 2 bytes
├─────────────────────────────────────────────────────────┤
│ Argon2: Iterations, MemorySize, Parallelism            │ 12 bytes
├─────────────────────────────────────────────────────────┤
│ Salt (16) + Nonce (24) + MetaNonce (24)               │ 64 bytes
├─────────────────────────────────────────────────────────┤
│ Encrypted Metadata: filename [+ original size]          │ variable
│ (length-prefixed, encrypted with MetaNonce)             │
├─────────────────────────────────────────────────────────┤
│ Chunks: [Length][Ciphertext+Tag] for each 4MB chunk   │ variable
└─────────────────────────────────────────────────────────┘
```

> The encrypted metadata block stores the original filename. Newer files also
> pack the original file size in the same block (separated by a null byte),
> used to detect truncated/incomplete files after decryption. Older files
> without this suffix remain fully compatible — the size check is simply
> skipped for them.

---

## 🚀 Platform Versions

### Windows (C# / .NET)

- **Framework**: .NET 8.0
- **UI**: WPF
- **Cryptography**: Sodium.Core (libsodium) for XChaCha20-Poly1305, Konscious.Security.Cryptography for Argon2id
- **Location**: `/windows/` *(verify this matches your actual folder layout)*

### Android (Flutter)

- **Framework**: Flutter 3.x
- **UI**: Material Design 3
- **Cryptography**: [`cryptography`](https://pub.dev/packages/cryptography) package (pure Dart implementation of both XChaCha20-Poly1305 and Argon2id — no native/FFI dependency)
- **Location**: `/android/` *(verify this matches your actual folder layout)*

---

## 📦 Installation

### Windows

```
# Clone the repository
git clone https://github.com/ip2300-p/SFE-Secure-File-Encoder-.git
cd SFE-Secure-File-Encoder-/windows

# Build with Visual Studio
dotnet build -c Release
```

### Android

```
# Clone the repository
git clone https://github.com/ip2300-p/SFE-Secure-File-Encoder-.git
cd SFE-Secure-File-Encoder-/android

# Get dependencies
flutter pub get

# Run on device
flutter run
```

---

## 🎯 Usage

### Windows (WPF)

1. Launch `SFE.exe`
2. Select file(s) or folder
3. Enter password (optionally enable a secondary password)
4. Click **Encrypt** or **Decrypt**
5. Output saved to the specified directory

### Android (Flutter)

1. Launch the app (or tap a `.sfe` file / use "Share" from another app to open it directly in SFE)
2. Add one or more files
3. Enter password (optionally enable a secondary password)
4. Tap **Encrypt** or **Decrypt**
5. Save the output: pick a location on the spot, use the default folder configured in Settings, or share it directly to another app

Additional Android-only options (all in **Settings**):

- Dark mode
- Language (Persian / English)
- App lock (device biometric / PIN / pattern)
- Randomized output filenames (with several disguise styles)
- Adjustable chunk size
- Scenarios: save a named combination of the above settings and re-apply it later

---

## 🔧 Configuration Options

| Option                       | Description                           | Default     | Platform          |
| ---------------------------- | -------------------------------------- | ----------- | ------------------ |
| `RandomizeFilename`          | Use a disguised name for the output file | `false`   | Windows & Android  |
| `NameStyle`                  | Style: CacheLike, DataLike, GuidShort  | `CacheLike` | Windows & Android  |
| `UseSecondaryPassword`       | Combine a second password with the first before key derivation | `false` | Windows & Android |
| `ChunkSize`                  | Size of each encryption chunk          | `4 MB`      | Windows & Android  |
| `DeleteOriginalAfterEncrypt` | Remove the source file after encryption | `false`    | Windows only. **On Android this currently only clears the app's internal temporary copy — the real source file (e.g. in Gallery/Downloads) is not touched**, due to Android's storage-permission model. |
| `SecureDelete`               | Overwrite source file before deletion  | `false`     | Windows only — not available on Android |
| `CreateBackup`               | Create an encrypted ZIP backup         | `false`     | Windows only — not available on Android |

---

## 🔒 Security Considerations

- **Password Strength**: Use strong passwords (12+ characters, mixed case, numbers, symbols)
- **Key Storage**: Keys are **never** stored on disk - only held in memory during operation
- **Memory Zeroing**: Keys are securely wiped from memory after use (Windows uses `CryptographicOperations.ZeroMemory`)
- **Randomness**: Uses cryptographically secure random generators (`Random.secure()` in Dart, `RandomNumberGenerator.Fill()` in C#)
- **Nonce Reuse**: Each chunk has a unique nonce derived from a base nonce + chunk counter; the filename/metadata block uses a separate, independently-generated nonce

---

## ⚠️ Known Limitations

- **Android cannot delete the original source file.** Due to Android's scoped-storage permission model, the app only has access to a temporary copy it creates for processing. Deleting the real file (e.g. in Gallery/Downloads) would require a separate Storage-Access-Framework-based file picker, which is not currently implemented.
- **Backup ZIP and Secure Delete are Windows-only features** and are not planned for Android.
- The Android app does not yet support Windows-style Scenarios that store source file paths — Android Scenarios only save a combination of settings (chunk size, filename randomization, default output folder), since files are picked ad-hoc rather than from a fixed location.

---

## 📂 Repository Structure

> ⚠️ The layout below is illustrative — please double-check it matches your actual repository before relying on it.

```
sfe/
├── README.md                      # This file
├── LICENSE                        # MIT License
├── .gitignore                     # Git ignore rules
│
├── windows/                       # Windows version (C#)
│   ├── SFE.sln                    # Visual Studio solution
│   ├── SFE/                       # Main project
│   │   ├── Crypto/                # Crypto engine (CryptoEngine.cs)
│   │   ├── Services/               # Encryption/Decryption services
│   │   ├── Models/                 # Data models
│   │   └── MainWindow.xaml         # WPF UI
│   └── README.md                  # Windows-specific docs
│
├── android/                       # Android version (Flutter)
│   ├── lib/
│   │   ├── core/
│   │   │   ├── crypto/            # Crypto engine (Dart)
│   │   │   ├── file_format/       # SFE reader/writer
│   │   │   └── models/            # Data models
│   │   ├── services/               # Encryption/Decryption/settings services
│   │   ├── screens/                 # UI screens
│   │   └── main.dart               # Main app entry
│   ├── pubspec.yaml                # Flutter dependencies
│   └── README.md                   # Android-specific docs
│
└── docs/                          # Shared documentation
    ├── file-format.md             # Detailed file format spec
    └── api.md                     # API documentation
```

---

## 🛠️ Development

### Prerequisites

**Windows:**

- Visual Studio 2022 (or newer)
- .NET 8.0 SDK
- Windows 10/11

**Android:**

- Flutter SDK 3.x
- Android Studio
- Android SDK (minSdk 21+; some plugins such as biometric app-lock may raise the effective minimum — check your build output)
- Android device or emulator

### Building from Source

```
# Clone repository
git clone https://github.com/ip2300-p/SFE-Secure-File-Encoder-.git
cd SFE-Secure-File-Encoder-

# Windows build
cd windows
dotnet restore
dotnet build -c Release

# Android build
cd ../android
flutter clean
flutter pub get
flutter build apk --release
```

---

## 🧪 Testing

```
# Windows tests
cd windows
dotnet test

# Android tests
cd ../android
flutter test
```

---

## 🤝 Contributing

Contributions are welcome! Please follow these steps:

1. **Fork** the repository
2. **Create a feature branch** (`git checkout -b feature/amazing-feature`)
3. **Commit changes** (`git commit -m 'Add amazing feature'`)
4. **Push to branch** (`git push origin feature/amazing-feature`)
5. **Open a Pull Request**

### Code Style

- **C#**: Follow Microsoft .NET coding conventions
- **Dart**: Follow the effective Dart style guide
- **Commits**: Use conventional commit messages

---

## 📄 License

This project is licensed under the **MIT License** - see the [LICENSE](https://github.com/ip2300-p/SFE-Secure-File-Encoder-/blob/main/LICENSE) file for details.

---

## 📊 Status

| Platform | Status    | Version |
| -------- | --------- | ------- |
| Windows  | 🟢 Stable  | 1.0.0   |
| Android  | 🟢 Stable (see Known Limitations above) | 1.0.0   |
| iOS      | 🔜 Planned | -       |
| macOS    | 🔜 Planned | -       |
| Linux    | 🔜 Planned | -       |

---

## 📞 Contact & Support

- **Issues**: [GitHub Issues](https://github.com/ip2300-p/SFE-Secure-File-Encoder-/issues)
- **Discussions**: [GitHub Discussions](https://github.com/ip2300-p/SFE-Secure-File-Encoder-/discussions)

---

## ⭐ Show your support

If you found this project helpful, please give it a ⭐ on GitHub!

---

**Built with ❤️ for secure file sharing across platforms**
