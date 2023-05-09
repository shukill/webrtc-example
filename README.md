# webrtc_example

Demonstrates how to use the webrtc plugin.

## Getting Started

Make sure your flutter is using the `dev` channel.

```bash
flutter channel dev
./scripts/project_tools.sh create
```

Android/iOS

```bash
flutter run
```

macOS

```bash
flutter run -d macos
```

Web

```bash
dart compile js ../web/e2ee.worker.dart -o web/e2ee.worker.dart.js
flutter run -d web
```

Windows

```bash
flutter channel master
flutter create --platforms windows .
flutter run -d windows
```

# webrtc-example
