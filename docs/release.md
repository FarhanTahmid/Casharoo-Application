# Releasing the Android app

## Flavours

| Flavour | Application ID | Config | Talks to | Use |
|---|---|---|---|---|
| `dev` | `<id>.dev` | `config/dev.json` | a local `runserver` (plain HTTP allowed) | development |
| `staging` | `<id>.stg` | `config/staging.json` | the staging API (HTTPS) | testers, closed beta stage 1 |
| `prod` | `<id>` | `config/prod.json` | production (HTTPS) | Play Store |

`<id>` is `baseApplicationId` in `android/app/build.gradle.kts`, currently the
placeholder `com.example.casharoo`.

Dev and staging builds show **Settings → Server**, where a tester can point the
app at another API (for example a Cloudflare tunnel to a developer's machine).
Switching signs out and clears the phone. Prod builds always use `API_URL`.

## Signing

`android/key.properties` (gitignored) points at the upload keystore:

```
storeFile=C:/path/to/upload-keystore.jks
storePassword=...
keyAlias=upload
keyPassword=...
```

- With it, debug and release builds are signed with that key (so the SHA-1
  registered for Google sign-in matches in both).
- Without it (CI, a fresh clone), debug builds use Android's default debug key
  and release builds stop with an error instead of producing an unsigned package.

Keep the keystore and its passwords outside the repository and backed up. Once
Play App Signing is on, Google holds the app signing key; losing the upload key
is recoverable through Play Console support, but slowly.

## Build

```
# Dev, for the emulator or a USB phone
flutter build apk --debug --flavor dev --dart-define-from-file=config/dev.json

# Staging APK for testers (stage 1 of the beta)
flutter build apk --release --flavor staging --dart-define-from-file=config/staging.json --build-number=<n>

# Play upload
flutter build appbundle --release --flavor prod --dart-define-from-file=config/prod.json --build-number=<n>
```

`--build-number` becomes the Android `versionCode`; every upload needs a higher
one. The version name comes from `version:` in `pubspec.yaml`.

## Before the first Play upload: the final application ID

Play never allows the ID to change after the first upload, even to a test track.

1. Choose the ID (reverse domain you control, e.g. `com.casharoo.app`).
2. `python tool/set_app_id.py <id>` — updates `baseApplicationId`, `namespace`,
   the Kotlin package of `MainActivity.kt` and the iOS bundle IDs.
3. `flutter clean`, rebuild, run the app.

### After changing the ID

- **Google sign-in:** create Android OAuth clients in Google Cloud for
  `<id>`, `<id>.stg` and `<id>.dev`, each with the SHA-1 of the key that signs
  it (`keytool -list -v -keystore <keystore>`; for Play builds also add the
  Play App Signing SHA-1 from Play Console). Put the web client ID in
  `GOOGLE_SERVER_CLIENT_ID` in the config files and the API's
  `WEB_OAUTH2_CLIENT_ID`/`ANDROID_OAUTH2_CLIENT_ID`.
- **Firebase (push, Phase 3+):** register the new IDs and download fresh
  `google-services.json` / `GoogleService-Info.plist`. The ones on disk are for
  the placeholder ID.
- **API:** set `ALLOWED_HOSTS`/`CSRF_TRUSTED_ORIGINS` for the real domain.

## Closed beta

### Stage 1 — staging APK, shared directly (possible now)

1. Run staging as described in the API's `docs/staging-local.md` and note the
   tunnel address it prints.
2. Build the staging APK (above) and share `build/app/outputs/flutter-apk/app-staging-release.apk`.
3. Testers install it (allow "install unknown apps"), open **Settings → Server**,
   paste the tunnel address, then sign up. Email codes arrive from the
   SMTP account configured for staging.
4. Set `FEEDBACK_EMAIL` in `config/staging.json` to show a "Send feedback" entry.

The quick-tunnel address changes whenever the tunnel restarts; testers then
update **Settings → Server**. A named tunnel on a real domain removes this step.

### Stage 2 — Play closed testing (needs the founder's accounts)

- [ ] Final application ID chosen and applied (above)
- [ ] Play Console developer account
- [ ] Privacy policy URL, Data safety form, content rating, app category
- [ ] Upload keystore created; Play App Signing enabled on first upload
- [ ] Stable staging host (named tunnel or server) in a `config/beta.json`, or production live
- [ ] Google OAuth clients for the new IDs
- [ ] `flutter build appbundle --flavor prod ...` uploaded to the closed testing track

New personal Play developer accounts must run a closed test with at least
12 testers for 14 consecutive days before they can apply for production access,
so gather the tester list early.
