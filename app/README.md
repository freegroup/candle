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

Build settings come from `env/<name>.json` (not in git), passed with
`--dart-define-from-file`. Copy the template and fill it in:

```sh
cp env/example.json env/dev.json
```

| Key | Purpose |
|-----|---------|
| `ORS_API_KEY` | openrouteservice.org key for pedestrian routing |
| `PLAY_CLOUD_PROJECT_NUMBER` | Google Cloud project for Play Integrity (Android sign-in at the Candle server) |
| `CANDLE_API_URL` | development only: use this server instead of looking it up (e.g. `http://10.0.2.2:8080`) |
| `DEBUG_ATTESTATION_TOKEN` | development only: lets simulators/emulators register at a local server with the same token |

Localizations (`lib/l10n/app_localizations*.dart`) are generated from the `.arb`
files on `flutter pub get`.

## Candle server

At start the app reads the server address from
[docs/api.json](../docs/api.json) (GitHub Pages) and registers the installation
anonymously with App Attest (iOS) / Play Integrity (Android), see
[server/README.md](../server/README.md). Without that file or server the app
works offline. Simulators and emulators cannot attest: run the server locally
with `DEBUG_ATTESTATION_TOKEN` and set `CANDLE_API_URL` + the same token.

## Run

```sh
flutter pub get
flutter run --dart-define-from-file=env/dev.json
```

## Release builds

```sh
# Android: signing via android/key.properties, or the environment variables
# CANDLE_KEYSTORE_PATH, CANDLE_KEYSTORE_PASSWORD, CANDLE_KEY_ALIAS, CANDLE_KEY_PASSWORD
flutter build appbundle --release

# iOS
flutter build ipa --release
```
