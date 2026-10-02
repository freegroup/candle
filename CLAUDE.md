# Candle

Navigation app for blind and visually impaired people. Flutter app in `app/`, Node/TypeScript
server in `server/`, server deployment in `ansible/`, store texts and upload script in `store/`,
GitHub Pages (privacy policy, `api.json` with the server address) in `docs/`.

## Rules

- Work by `.claude/skills/karpathy-guidelines`: surgical changes, no drive-by fixes, state assumptions.
- Accessibility comes first: every UI change must work with TalkBack/VoiceOver, large system fonts,
  and must not hide content behind system bars.
- Commit, push and releases (version bump, `store/play-upload.mjs`) only when the user asks.
  Commit with `git commit --only -- <paths>`; the user keeps unrelated files staged.
- Never run `dart format` on whole files; keep diffs to the lines that change.
- Never print or commit secrets: `ansible/secrets.env`, `ansible/*.json`, `app/env/dev.json`,
  `app/android/key.properties`.

## App architecture (Flutter architecture guide, MVVM)

- `lib/data/services/` thin wrappers (HTTP, sensors, platform, drift database); `lib/data/repositories/`
  own the data and return `Result`; `lib/domain/models/` immutable models; `lib/ui/<feature>/view_models/`
  `ChangeNotifier` + `Command`; `lib/ui/<feature>/widgets/` display only, created with a
  `build<Feature>Screen()` function that provides the view model; shared widgets, icons, theme in
  `lib/ui/core/`; DI via provider in `lib/config/dependencies.dart`.
- Persistence: drift (`lib/data/services/database/`, run `dart run build_runner build` after schema
  changes); settings: `SettingsRepository`.
- `analysis_options.yaml` has no exclusions: all code passes the strict analysis. Every view model has
  tests with fakes in `test/fakes` or an in-memory drift database.

## Checks

- App: `flutter analyze`, `flutter test` (in `app/`, with `--dart-define-from-file=env/dev.json` for builds).
- Texts: edit `app/lib/l10n/arb/*.arb` (Flutter generates `lib/l10n/gen/`); short screen reader texts in
  `app/lib/l10n/arb/short/*.arb`, then run `dart run tool/gen_short_l10n.dart` (a test fails if forgotten).
- Server: `npm run typecheck`, `npm test` (in `server/`).
