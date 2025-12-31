# i2pd iOS - Anonymous Network Router

A full-featured iOS client for the I2P anonymous network, built with Flutter and the i2pd C++ daemon.

## Features

- **Full I2P Router**: Complete i2pd daemon running natively on iOS
- **HTTP Proxy**: Browse .i2p sites via local proxy (port 4444)
- **SOCKS5 Proxy**: Route any app through I2P (port 4447)
- **SAM Bridge**: Support for I2P applications (port 7656)
- **Tunnel Management**: Create client and server tunnels
- **Real-time Stats**: Monitor bandwidth, tunnels, and network status
- **Background Execution**: Continues running when app is minimized
- **Dark Theme**: Purple I2P themed dark interface

## Building

### Option 1: GitHub Actions (Free, No Mac Required)

1. Fork this repository to your GitHub account
2. Go to repository Settings → Secrets and add:
   - For unsigned builds (sideloading): No secrets needed
   - For signed builds: Add Apple Developer certificates (see below)
3. Go to Actions tab and run "Build iOS App" workflow
4. Download the IPA from workflow artifacts

### Option 2: Local Build (Requires Mac)

```bash
# Install Flutter
brew install flutter

# Clone and build
git clone https://github.com/YOUR_USERNAME/i2pd-ios.git
cd i2pd-ios
flutter pub get
flutter build ios --release
```

## Installing on iPhone

### Method 1: AltStore (Free, No Jailbreak)

1. Install [AltStore](https://altstore.io/) on your computer
2. Connect your iPhone
3. Install the .ipa file through AltStore
4. Re-sign every 7 days (AltStore does this automatically)

### Method 2: Sideloadly (Free, No Jailbreak)

1. Download [Sideloadly](https://sideloadly.io/)
2. Connect your iPhone
3. Drag the .ipa file into Sideloadly
4. Enter your Apple ID
5. Click Start

### Method 3: TrollStore (Permanent, Requires Specific iOS Versions)

If your device supports [TrollStore](https://github.com/opa334/TrollStore):
1. Install TrollStore
2. Open the .ipa with TrollStore
3. App is permanently installed (no re-signing needed)

### Method 4: Apple Developer Account ($99/year)

1. Add your device to Apple Developer portal
2. Create provisioning profile
3. Build with signing or use TestFlight

## GitHub Secrets Setup (For Signed Builds)

To build signed IPAs via GitHub Actions:

1. **BUILD_CERTIFICATE_BASE64**: Your Apple Development certificate (.p12) encoded in base64
   ```bash
   base64 -i certificate.p12 | pbcopy
   ```

2. **P12_PASSWORD**: Password for the .p12 file

3. **PROVISIONING_PROFILE_BASE64**: Your provisioning profile encoded in base64
   ```bash
   base64 -i profile.mobileprovision | pbcopy
   ```

4. **KEYCHAIN_PASSWORD**: Any random password for temporary keychain

## Configuration

Default ports (configurable in Settings):
- HTTP Proxy: 127.0.0.1:4444
- SOCKS Proxy: 127.0.0.1:4447
- SAM Bridge: 127.0.0.1:7656

## Using I2P on iOS

### Safari/Browser
Configure proxy in Settings → Wi-Fi → [Your Network] → Configure Proxy → Manual:
- Server: 127.0.0.1
- Port: 4444

### Apps with SOCKS Support
Use SOCKS5 proxy: 127.0.0.1:4447

### I2P Applications
Apps supporting SAM protocol can connect to: 127.0.0.1:7656

## Battery Considerations

I2P is designed for always-on operation. To save battery:
- Enable "No Transit" in settings (don't relay others' traffic)
- Use "Low" bandwidth setting
- The app automatically reduces activity in background

## Project Structure

```
i2pd-ios/
├── lib/
│   ├── main.dart              # App entry point
│   ├── screens/               # UI screens
│   │   ├── home_screen.dart
│   │   ├── settings_screen.dart
│   │   └── logs_screen.dart
│   ├── widgets/               # Reusable UI components
│   │   ├── status_card.dart
│   │   ├── stats_grid.dart
│   │   ├── proxy_settings.dart
│   │   └── tunnel_list.dart
│   ├── services/              # Business logic
│   │   └── i2pd_service.dart
│   ├── native/                # FFI bridge
│   │   └── i2pd_bridge.dart
│   └── theme/
│       └── app_theme.dart
├── ios/
│   ├── Runner/
│   │   ├── AppDelegate.swift  # iOS app delegate
│   │   ├── I2pdBridge.swift   # Native i2pd wrapper
│   │   └── Info.plist
│   └── Frameworks/            # i2pd static library
├── .github/
│   └── workflows/
│       └── build-ios.yml      # GitHub Actions CI/CD
└── pubspec.yaml
```

## License

This project is licensed under BSD 3-Clause License, same as i2pd.

## Credits

- [i2pd](https://github.com/PurpleI2P/i2pd) - C++ I2P daemon
- [I2P Project](https://geti2p.net/) - Anonymous network protocol
- [Flutter](https://flutter.dev/) - Cross-platform UI framework

## Support

- i2pd Documentation: https://i2pd.readthedocs.io/
- I2P Forum: https://i2pforum.net/
- GitHub Issues: Report bugs and feature requests
