# candle

Accessible navigation app for iOS and Android.

## Toolchain

| Tool    | Version                          |
|---------|----------------------------------|
| Flutter | 3.44.x (pinned in `.fvmrc`)      |
| Android | AGP 9.4, Gradle 9.6, Java 17, compileSdk 37 |
| iOS     | Xcode 27, deployment target iOS 15 |

With [FVM](https://fvm.app) installed, `fvm install` picks up the pinned version.

## Setup

`lib/auth/secrets.dart` is not in git. Create it with the API keys:

```dart
var OPENSTREETMAP_API_KEY = "<openrouteservice key>";
```

Localizations (`lib/l10n/app_localizations*.dart`) are generated from the `.arb`
files on `flutter pub get`.

## Run

```sh
flutter pub get
flutter run
```

## Release builds

```sh
# Android: signing via android/key.properties, or the environment variables
# CANDLE_KEYSTORE_PATH, CANDLE_KEYSTORE_PASSWORD, CANDLE_KEY_ALIAS, CANDLE_KEY_PASSWORD
flutter build appbundle --release

# iOS
flutter build ipa --release
```
