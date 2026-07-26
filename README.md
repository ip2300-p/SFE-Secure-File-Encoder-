# 🔐 SFE - Secure File Encryption

**Cross-platform encryption tool** for Windows and Android with full format compatibility.

[![Flutter](https://img.shields.io/badge/Android-Flutter-blue?logo=flutter)](https://flutter.dev)
[![.NET](https://img.shields.io/badge/Windows-.NET-purple?logo=dotnet)](https://dotnet.microsoft.com)
[![License](https://img.shields.io/badge/license-MIT-green)](LICENSE)

---

## 📖 About

SFE (Secure File Encryption) is a cross-platform encryption tool that allows you to encrypt and decrypt files using strong cryptography. Files encrypted on **Windows** can be decrypted on **Android** and vice versa.

### Why SFE?
- ✅ **Cross-platform**: Windows + Android support
- ✅ **Strong encryption**: XChaCha20-Poly1305 (highly secure)
- ✅ **Memory-hard KDF**: Argon2id (resistant to GPU/ASIC attacks)
- ✅ **Compatible format**: Same `.sfe` file structure across platforms
- ✅ **Chunk-based**: Handles large files efficiently (4MB chunks)
- ✅ **Metadata protection**: Filename is encrypted too

---

## 🧬 Technical Specifications

| Component | Specification |
|-----------|---------------|
| **Encryption** | XChaCha20-Poly1305 (IETF) |
| **Key Derivation** | Argon2id (v1.3) |
| **Argon2 Parameters** | Iterations: 4, Memory: 64 MiB, Parallelism: 2 |
| **Nonce Size** | 24 bytes (XChaCha20) |
| **Salt Size** | 16 bytes |
| **Chunk Size** | 4 MB |
| **File Extension** | `.sfe` |
| **Magic Bytes** | `SFE1` (0x53 0x46 0x45 0x31) |

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
│ Encrypted Filename (length-prefixed)                   │ variable
├─────────────────────────────────────────────────────────┤
│ Chunks: [Length][Ciphertext+Tag] for each 4MB chunk   │ variable
└─────────────────────────────────────────────────────────┘
```

---

## 🚀 Platform Versions

### Windows (C# / .NET)
- **Framework**: .NET 8.0
- **UI**: WPF / Console
- **Cryptography**: Sodium.Core (libsodium)
- **Location**: `/windows/`

### Android (Flutter)
- **Framework**: Flutter 3.x
- **UI**: Material Design
- **Cryptography**: `cryptography` package (Dart)
- **KDF**: `argon2_ffi`
- **Location**: `/android/`

---

## 📦 Installation

### Windows
```bash
# Clone the repository
git clone https://github.com/ip2300-p/sfe.git
cd sfe/windows

# Build with Visual Studio
dotnet build -c Release
```

### Android
```bash
# Clone the repository
git clone https://github.com/ip2300-p/sfe.git
cd sfe/android

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
3. Enter password
4. Click **Encrypt** or **Decrypt**
5. Output saved to specified directory

### Android (Flutter)
1. Launch app
2. Tap **Select File**
3. Choose a file from storage
4. Enter password
5. Tap **Encrypt** or **Decrypt**
6. File saved in app's external storage directory

---

## 🔧 Configuration Options

| Option | Description | Default |
|--------|-------------|---------|
| `RandomizeFilename` | Use disguised name for output | `false` |
| `NameStyle` | Style: CacheLike, DataLike, GuidShort | `CacheLike` |
| `DeleteOriginalAfterEncrypt` | Remove source file after encryption | `false` |
| `SecureDelete` | Overwrite source file before deletion | `false` |
| `CreateBackup` | Create encrypted ZIP backup | `false` |
| `ChunkSize` | Size of each encryption chunk | `4 MB` |

---

## 🔒 Security Considerations

- **Password Strength**: Use strong passwords (12+ characters, mixed case, numbers, symbols)
- **Key Storage**: Keys are **never** stored on disk - only held in memory during operation
- **Memory Zeroing**: Keys are securely wiped from memory after use
- **Randomness**: Uses cryptographically secure random generators (`Random.secure()` in Dart, `RNGCryptoServiceProvider` in C#)
- **Nonce Reuse**: Each chunk has a unique nonce derived from a base nonce + chunk counter

---

## 📂 Repository Structure

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
│   │   ├── Services/              # Encryption/Decryption services
│   │   ├── Models/                # Data models
│   │   └── MainWindow.xaml        # WPF UI
│   └── README.md                  # Windows-specific docs
│
├── android/                       # Android version (Flutter)
│   ├── lib/
│   │   ├── core/
│   │   │   ├── crypto/            # Crypto engine (Dart)
│   │   │   ├── file_format/       # SFE reader/writer
│   │   │   └── models/            # Data models
│   │   ├── services/              # Encryption/Decryption services
│   │   └── main.dart              # Main app entry
│   ├── pubspec.yaml               # Flutter dependencies
│   └── README.md                  # Android-specific docs
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
- Flutter SDK 3.0+
- Android Studio
- Android SDK (API 21+)
- Android device or emulator

### Building from Source

```bash
# Clone repository
git clone https://github.com/ip2300-p/sfe.git
cd sfe

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

```bash
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
- **Dart**: Follow effective Dart style guide
- **Commits**: Use conventional commit messages

---

## 📄 License

This project is licensed under the **MIT License** - see the [LICENSE](LICENSE) file for details.

---

## 📊 Status

| Platform | Status | Version |
|----------|--------|---------|
| Windows  | 🟢 Stable | 1.0.0 |
| Android  | 🟢 Stable | 1.0.0 |
| iOS      | 🔜 Planned | - |
| macOS    | 🔜 Planned | - |
| Linux    | 🔜 Planned | - |

---

## 📞 Contact & Support

- **Issues**: [GitHub Issues](https://github.com/ip2300-p/sfe/issues)
- **Discussions**: [GitHub Discussions](https://github.com/ip2300-p/sfe/discussions)

---

## ⭐ Show your support

If you found this project helpful, please give it a ⭐ on GitHub!

---

**Built with ❤️ for secure file sharing across platforms**
