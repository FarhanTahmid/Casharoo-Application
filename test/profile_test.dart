import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:spendroo/core/api/api_client.dart';
import 'package:spendroo/core/db/database.dart';
import 'package:spendroo/core/providers.dart';
import 'package:spendroo/features/profile/profile_page.dart';
import 'package:spendroo/features/profile/profile_repository.dart';

import 'app_flow_test.dart' show FakeServer, Harness, onePixelPng;

const onboarded = '2026-10-01T00:00:00Z';

/// Hands back a picture as if the user picked and cropped one.
class FakeAvatarPicker extends AvatarPicker {
  final sources = <ImageSource>[];

  @override
  Future<Uint8List?> pick(BuildContext context, ImageSource source) async {
    sources.add(source);
    return onePixelPng;
  }
}

Finder field(String label) => find.widgetWithText(TextFormField, label);

/// The profile screen's list, not the text boxes that scroll inside it.
final profileList = find.descendant(of: find.byType(ListView), matching: find.byType(Scrollable)).first;

/// Signed in, on the profile screen.
Future<Harness> openProfile(WidgetTester tester, FakeServer server, {FakeAvatarPicker? picker}) async {
  final app = Harness(tester, server, overrides: [if (picker != null) avatarPickerProvider.overrideWithValue(picker)]);
  await app.start();
  await app.logIn();
  await tester.tap(find.byIcon(Icons.settings_outlined));
  await app.settle();
  await tester.tap(find.text('@alice'));
  await app.settle();
  expect(find.text('Profile'), findsOneWidget);
  return app;
}

void main() {
  group('Profile model', () {
    test('reads what the server sends and falls back on missing fields', () {
      final profile = Profile.fromJson({
        'id': 'u1', 'email': 'farhan@example.com', 'username': 'farhan', 'first_name': 'Farhan', 'last_name': 'Tahmid',
        'avatar_url': '/api/v1/me/avatar/?v=abc', 'has_password': false,
      });
      expect((profile.displayName, profile.initials, profile.hasPassword), ('Farhan Tahmid', 'FT', false));
      expect(Profile.fromJson(profile.toJson()).avatarUrl, '/api/v1/me/avatar/?v=abc');

      final bare = Profile.fromJson({'email': 'x@example.com', 'username': 'x'});
      expect((bare.displayName, bare.initials, bare.hasPassword, bare.avatarUrl), ('x', 'X', true, null));
    });

    test('server errors are kept per field', () {
      final errors = ProfileErrors.fromResponse(ApiResponse(400, {'password': ['Incorrect password.'], 'detail': 'x'}));
      expect(errors['password'], 'Incorrect password.');
      expect(errors.isOffline, isFalse);
      expect(ProfileErrors.fromResponse(ApiResponse(500, null)).message, contains('500'));
    });
  });

  testWidgets('log in with a username', (tester) async {
    final server = FakeServer(onboardedAt: onboarded);
    final app = Harness(tester, server);
    await app.start();
    await tester.enterText(field('Email or username'), 'alice');
    await tester.enterText(field('Password'), 'correct-horse');
    await tester.tap(find.widgetWithText(FilledButton, 'Log in'));
    await app.settle();
    expect(server.logins.single, {'username': 'alice', 'password': 'correct-horse'});
    expect(find.text('Total balance'), findsOneWidget);
    await app.stop();
  }, timeout: const Timeout(Duration(seconds: 60)));

  testWidgets('log in with an email sends it as the email', (tester) async {
    final server = FakeServer(onboardedAt: onboarded);
    final app = Harness(tester, server);
    await app.start();
    await app.logIn();
    expect(server.logins.single, {'email': 'alice@example.com', 'password': 'correct-horse'});
    await app.stop();
  }, timeout: const Timeout(Duration(seconds: 60)));

  testWidgets('sign-up asks for the password twice', (tester) async {
    final server = FakeServer();
    final app = Harness(tester, server);
    await app.start();
    await tester.tap(find.text('New here? Create an account'));
    await app.settle();

    await tester.enterText(field('Email'), 'new@example.com');
    await tester.enterText(field('Password'), 'long-enough-1');
    await tester.enterText(field('Confirm password'), 'long-enough-2');
    await tester.tap(find.widgetWithText(FilledButton, 'Create account'));
    await app.settle();
    expect(find.text("Passwords don't match"), findsOneWidget);
    expect(server.signups, isEmpty);

    await tester.enterText(field('Confirm password'), 'long-enough-1');
    await tester.tap(find.widgetWithText(FilledButton, 'Create account'));
    await app.settle();
    expect(server.signups.single, {'email': 'new@example.com', 'password': 'long-enough-1'});
    expect(find.text('Check your email'), findsOneWidget);
    await app.stop();
  }, timeout: const Timeout(Duration(seconds: 60)));

  testWidgets('change username: checked while typing, suggestions, password to confirm', (tester) async {
    final server = FakeServer(onboardedAt: onboarded);
    final app = await openProfile(tester, server);
    expect(find.text('This is your username'), findsOneWidget);

    // Quick typing asks the server once, after a pause
    await tester.enterText(field('Username'), 'bo');
    await tester.pump(const Duration(milliseconds: 100));
    await tester.enterText(field('Username'), 'bob');
    await tester.pump(const Duration(milliseconds: 100));
    expect(server.usernameChecks, isEmpty);
    await app.settle();
    expect(server.usernameChecks, ['bob']);
    expect(find.text('Already taken'), findsOneWidget);

    // An @ is refused without asking
    await tester.enterText(field('Username'), 'bob@home');
    await app.settle();
    expect(find.text('Use letters, numbers and . _ + - only'), findsOneWidget);
    expect(server.usernameChecks, ['bob']);

    await tester.enterText(field('Username'), 'bob');
    await app.settle();
    await tester.tap(find.widgetWithText(ActionChip, 'bob1234'));
    await app.settle();
    expect(find.text('Available'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Change username'));
    await app.settle();
    expect(find.text('Enter your password to confirm this change.'), findsOneWidget);
    await tester.enterText(find.descendant(of: find.byType(BottomSheet), matching: field('Password')), 'wrong');
    await tester.tap(find.widgetWithText(FilledButton, 'Confirm'));
    await app.settle();
    expect(find.text('Incorrect password.'), findsOneWidget); // the sheet stays open
    expect(server.username, 'alice');

    await tester.enterText(find.descendant(of: find.byType(BottomSheet), matching: field('Password')), 'correct-horse');
    await tester.tap(find.widgetWithText(FilledButton, 'Confirm'));
    await app.settle();
    expect(server.username, 'bob1234');
    expect(server.usernameChanges.last, {'username': 'bob1234', 'password': 'correct-horse'});
    expect(find.text('Username changed.'), findsOneWidget);
    expect(find.text('@bob1234 · alice@example.com'), findsOneWidget);

    // The profile is kept for offline use, and goes on logout
    expect(await app.run(app.db.getSetting(profileSettingKey)), contains('bob1234'));
    await app.run(app.container.read(authControllerProvider.notifier).logOut());
    expect(await app.run(app.db.getSetting(profileSettingKey)), isNull);
    await app.stop();
  }, timeout: const Timeout(Duration(seconds: 90)));

  testWidgets('a Google account changes its username without a password, then sets one', (tester) async {
    final server = FakeServer(onboardedAt: onboarded)..hasPassword = false;
    final app = await openProfile(tester, server);

    await tester.enterText(field('Username'), 'alice.g');
    await app.settle();
    await tester.tap(find.widgetWithText(FilledButton, 'Change username'));
    await app.settle();
    expect(find.text('Enter your password to confirm this change.'), findsNothing);
    expect(server.usernameChanges.single, {'username': 'alice.g'});
    expect(server.username, 'alice.g');

    await tester.scrollUntilVisible(find.text('Set a password'), 100, scrollable: profileList);
    await tester.ensureVisible(find.text('Set a password'));
    await tester.pump();
    await tester.tap(find.text('Set a password'));
    await app.settle();
    expect(field('Current password'), findsNothing);
    await tester.enterText(field('New password'), 'first-pass-123');
    await tester.enterText(field('Confirm new password'), 'first-pass-123');
    await tester.tap(find.descendant(of: find.byType(BottomSheet), matching: find.widgetWithText(FilledButton, 'Save')));
    await app.settle();
    expect(server.passwordChanges.single, {'new_password': 'first-pass-123'});
    expect(find.text('Password updated.'), findsOneWidget);
    // Closing the sheet gives the focus back to the username box, up the list
    await tester.scrollUntilVisible(find.text('Change password'), 100, scrollable: profileList);
    expect(find.text('Change password'), findsOneWidget);
    await app.stop();
  }, timeout: const Timeout(Duration(seconds: 90)));

  testWidgets('change password needs the current one and a matching confirmation', (tester) async {
    final server = FakeServer(onboardedAt: onboarded);
    final app = await openProfile(tester, server);
    await tester.scrollUntilVisible(find.text('Change password'), 100, scrollable: profileList);
    await tester.ensureVisible(find.text('Change password'));
    await tester.pump();
    await tester.tap(find.text('Change password'));
    await app.settle();
    final save = find.descendant(of: find.byType(BottomSheet), matching: find.widgetWithText(FilledButton, 'Save'));

    await tester.enterText(field('Current password'), 'not-it');
    await tester.enterText(field('New password'), 'new-long-pass');
    await tester.enterText(field('Confirm new password'), 'new-long-typo');
    await tester.tap(save);
    await app.settle();
    expect(find.text("Passwords don't match"), findsOneWidget);
    expect(server.passwordChanges, isEmpty);

    await tester.enterText(field('Confirm new password'), 'new-long-pass');
    await tester.tap(save);
    await app.settle();
    expect(find.text('Please type your current password.'), findsOneWidget);

    await tester.enterText(field('Current password'), 'correct-horse');
    await tester.tap(save);
    await app.settle();
    expect(server.passwordChanges.last, {'current_password': 'correct-horse', 'new_password': 'new-long-pass'});
    expect(find.text('Password updated.'), findsOneWidget);
    await app.stop();
  }, timeout: const Timeout(Duration(seconds: 90)));

  testWidgets('profile photo: picked and cropped, uploaded, shown, removed', (tester) async {
    final server = FakeServer(onboardedAt: onboarded);
    final picker = FakeAvatarPicker();
    final app = await openProfile(tester, server, picker: picker);

    await tester.tap(find.byType(UserAvatar));
    await app.settle();
    expect(find.text('Remove photo'), findsNothing); // nothing to remove yet
    await tester.tap(find.text('Choose from gallery'));
    await app.settle();
    expect(picker.sources, [ImageSource.gallery]);
    expect(server.avatarUploads.single, startsWith('multipart/form-data'));
    expect(find.text('Profile photo updated.'), findsOneWidget);
    expect(server.avatarFetches, greaterThan(0));
    expect(find.byType(Image), findsWidgets);

    await tester.tap(find.byType(UserAvatar));
    await app.settle();
    await tester.tap(find.text('Remove photo'));
    await app.settle();
    expect(server.avatarUrl, isNull);
    expect(find.text('Profile photo removed.'), findsOneWidget);
    await app.stop();
  }, timeout: const Timeout(Duration(seconds: 90)));
}
