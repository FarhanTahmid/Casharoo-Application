# Casharoo app

Flutter app for Android (iOS later). Offline first: everything is written to a
local SQLite database (Drift) and synced with the API in the background.

| Folder | Holds |
|---|---|
| `lib/core/` | Config, API client, auth, Drift database, sync engine, Riverpod providers, money formatting, theme |
| `lib/features/` | Screens: auth, onboarding, personal (accounts, transactions, budgets, overview), cashbook, settings, shell |
| `lib/l10n/` | English and Bangla strings (`app_en.arb`, `app_bn.arb`); Dart files are generated from them |
| `config/` | Per-flavour settings: `FLAVOR`, `API_URL`, `GOOGLE_SERVER_CLIENT_ID` |

## Run

Three flavours, each installable side by side: `dev` (`com.example.casharoo.dev`),
`staging` (`.stg`) and `prod`. Pair the flavour with its config file:

```
flutter run --flavor dev --dart-define-from-file=config/dev.json
```

VS Code has these as launch configurations. The app ID lives in one place,
`baseApplicationId` in `android/app/build.gradle.kts`; change it before the first Play upload.

The dev config points at `http://localhost:8000`. With the API's `runserver`
on the computer and a phone on USB:

```
adb reverse tcp:8000 tcp:8000
```

On the emulator, use `http://10.0.2.2:8000` instead. Only dev builds may use
plain HTTP; staging and prod require HTTPS.

Google sign-in is shown only when `GOOGLE_SERVER_CLIENT_ID` is set (the web
OAuth client the API verifies tokens against).

## After changing code

```
dart run build_runner build      # after changing tables in lib/core/db/database.dart
flutter gen-l10n                 # after changing lib/l10n/*.arb (flutter run does this too)
flutter analyze
```

## Tests

```
flutter test
```

On Windows the database tests need a host `sqlite3.dll`; point `SQLITE3_DLL`
at one if it is not on `PATH`.

`test/live_sync_test.dart` runs two devices against a real API and is skipped
by default. With `runserver` up and a user whose email is verified:

```
LIVE_API_URL=http://localhost:8000 LIVE_EMAIL=... LIVE_PASSWORD=... flutter test --run-skipped -t live
```

## Rules the code relies on

- **Money** is an integer in minor units plus a currency code; never a double. Use `Money.parse` and `Money.format`.
- **Writes** go through `LocalStore` (`create`/`update`/`remove`), which also queues them in the outbox.
  Updates queue only the changed columns, so edits from two devices to different fields both survive.
- **Ids** are UUIDv7, made on the device.
- **Every user-visible string** is in both `.arb` files.
