# Spendroo app

Flutter app for Android (iOS later). Offline first: everything is written to a
local SQLite database (Drift) and synced with the API in the background.

| Folder | Holds |
|---|---|
| `lib/core/` | Config, API client, auth, Drift database, sync engine, Riverpod providers, money formatting, theme |
| `lib/features/` | Screens: auth, onboarding, personal (overview and stats, transactions, budget calendar, accounts, categories), cashbook, settings, shell |
| `lib/l10n/` | English and Bangla strings (`app_en.arb`, `app_bn.arb`); Dart files are generated from them |
| `config/` | Per-flavour settings: `FLAVOR`, `API_URL`, `GOOGLE_SERVER_CLIENT_ID`, `FEEDBACK_EMAIL` |
| `drift_schemas/` | Snapshot of every database schema version, for migrations and their tests |
| `docs/release.md` | Signing, building each flavour, the final app ID, the closed beta |
| `assets/brand/` | Spendroo logos, copied from `Spendroo Business Files/Brand/Spendroo Logo` |
| `tool/` | `set_app_id.py` (changes the application ID), `make_icons.py` (launcher icons from the brand kit) |

## Run

Three flavours, each installable side by side: `dev` (`com.spendroo.app.dev`),
`staging` (`com.spendroo.app.stg`) and `prod` (`com.spendroo.app`). Pair the flavour with its config file:

```
flutter run --flavor dev --dart-define-from-file=config/dev.json
```

VS Code has these as launch configurations. The app ID lives in one place,
`baseApplicationId` in `android/app/build.gradle.kts`. It is final once the
first build is uploaded to Play.

The dev config points at `http://10.0.2.2:8000`, the emulator's address for the
computer running the API's `runserver`. For a phone on USB, run
`adb reverse tcp:8000 tcp:8000` and set **Settings → Server** to
`http://localhost:8000`. Only dev builds may use plain HTTP; staging and prod
require HTTPS. Dev and staging builds can be pointed at any server from
**Settings → Server**; prod builds cannot.

Google sign-in is shown only when `GOOGLE_SERVER_CLIENT_ID` is set (the web
OAuth client the API verifies tokens against).

## After changing code

```
flutter gen-l10n                 # after changing lib/l10n/*.arb (flutter run does this too)
flutter analyze
```

Changing a table in `lib/core/db/database.dart`:

1. Bump `schemaVersion` and add the step in `migration` (`from1To2`, `from2To3`, ...).
2. `dart run build_runner build --delete-conflicting-outputs`
3. `dart run drift_dev make-migrations` — snapshots the schema into `drift_schemas/`,
   regenerates `database.steps.dart` and the tests in `test/drift/`.
4. `flutter test test/drift` checks every upgrade path keeps the data.

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
- **Every user-visible string** is in both `.arb` files; `test/l10n_test.dart` fails otherwise.
- **The personal screens share one month** (`selectedMonthProvider`): overview, transactions and the budget calendar move together.
- **Budgets**: one recurring limit per expense category, plus optional one-month overrides (`month` = `yyyy-MM-01`).

## Branding

The logos, colours and typeface come from `Spendroo Business Files/Brand/Spendroo Logo`
(see its README). To pick up a new version of the logo:

1. Copy the changed files into `assets/brand/` (in-app logo) and `assets/icon/source/`
   (`png/mark/spendroo-mark-1024w.png` as `mark-1024.png`, and the
   `app-icon/android-adaptive/` foreground and monochrome).
2. `python tool/make_icons.py`, then `dart run flutter_launcher_icons`.

Theme colours are in `lib/core/theme.dart`.
