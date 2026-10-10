import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/widgets.dart' show StringCharacters;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/auth/auth_repository.dart';
import '../../core/db/database.dart';
import '../../core/providers.dart';

/// The signed-in user, as /api/v1/me/ reports them.
class Profile {
  const Profile({
    required this.id,
    required this.email,
    required this.username,
    this.firstName = '',
    this.lastName = '',
    this.bio = '',
    this.phone = '',
    this.avatarUrl,
    this.hasPassword = true,
  });

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
        id: json['id'] as String? ?? '',
        email: json['email'] as String? ?? '',
        username: json['username'] as String? ?? '',
        firstName: json['first_name'] as String? ?? '',
        lastName: json['last_name'] as String? ?? '',
        bio: json['bio'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
        avatarUrl: json['avatar_url'] as String?,
        hasPassword: json['has_password'] as bool? ?? true,
      );

  final String id;
  final String email;
  final String username;
  final String firstName;
  final String lastName;
  final String bio;
  final String phone;

  /// Changes whenever the picture does. Null without one.
  final String? avatarUrl;

  /// False for an account made with Google until a password is set.
  final bool hasPassword;

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'username': username,
        'first_name': firstName,
        'last_name': lastName,
        'bio': bio,
        'phone': phone,
        'avatar_url': avatarUrl,
        'has_password': hasPassword,
      };

  String get fullName => '$firstName $lastName'.trim();

  /// The name to show: the full name, else the username.
  String get displayName => fullName.isNotEmpty ? fullName : username;

  /// One or two letters for the picture placeholder.
  String get initials {
    final words = displayName.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return '?';
    return words.take(2).map((w) => w.characters.first.toUpperCase()).join();
  }
}

/// Whether a username can be taken, as the server answered while the user typed.
class UsernameCheck {
  const UsernameCheck({required this.available, this.current = false, this.reason, this.suggestions = const []});

  factory UsernameCheck.fromJson(Map<String, dynamic> json) => UsernameCheck(
        available: json['available'] as bool? ?? false,
        current: json['current'] as bool? ?? false,
        reason: json['reason'] as String?,
        suggestions: ((json['suggestions'] as List?) ?? const []).cast<String>(),
      );

  final bool available;

  /// It is the user's own username already.
  final bool current;

  /// 'taken' or 'invalid' when not available.
  final String? reason;

  /// Free usernames like the one that was taken.
  final List<String> suggestions;
}

/// Why a profile change was refused, per field, as Django REST framework reports it.
class ProfileErrors {
  const ProfileErrors(this.fields);

  /// The request never reached the server.
  static const offline = ProfileErrors({'detail': 'offline'});

  factory ProfileErrors.fromResponse(ApiResponse response) {
    final body = response.body;
    if (body is! Map || body.isEmpty) return ProfileErrors({'detail': 'Request failed (${response.statusCode}).'});
    return ProfileErrors({
      for (final MapEntry(:key, :value) in body.entries)
        '$key': value is List ? value.join(' ') : '$value',
    });
  }

  final Map<String, String> fields;

  String? operator [](String field) => fields[field];

  bool get isOffline => fields['detail'] == 'offline';

  /// Everything the server said, for a message.
  String get message => fields.values.join(' ');
}

class ProfileRepository {
  ProfileRepository(this._api);

  final ApiClient _api;
  static const _me = '/api/v1/me/';

  Future<Profile?> fetch() async {
    final response = await _api.get(_me);
    return response.ok && response.body is Map ? Profile.fromJson(response.json) : null;
  }

  Future<(Profile?, ProfileErrors?)> update(Map<String, Object?> fields) =>
      _profileCall(() => _api.patch(_me, fields));

  Future<UsernameCheck?> checkUsername(String username) async {
    final response = await _api.get('${_me}username/check/', query: {'username': username});
    return response.ok && response.body is Map ? UsernameCheck.fromJson(response.json) : null;
  }

  /// [password] is needed unless the account has none.
  Future<(Profile?, ProfileErrors?)> changeUsername(String username, {String? password}) =>
      _profileCall(() => _api.post('${_me}username/', {'username': username, 'password': ?password}));

  /// [bytes] is the picture the user cropped; the server shrinks it.
  Future<(Profile?, ProfileErrors?)> uploadAvatar(List<int> bytes) =>
      _profileCall(() => _api.upload('${_me}avatar/', field: 'file', bytes: bytes, filename: 'avatar.jpg'));

  Future<ProfileErrors?> removeAvatar() async {
    final response = await _api.delete('${_me}avatar/');
    return response.ok ? null : ProfileErrors.fromResponse(response);
  }

  Future<Uint8List?> avatarBytes(String url) => _api.getBytes(url);

  Future<(Profile?, ProfileErrors?)> _profileCall(Future<ApiResponse> Function() request) async {
    final response = await request();
    if (response.ok && response.body is Map) return (Profile.fromJson(response.json), null);
    return (null, ProfileErrors.fromResponse(response));
  }
}

final profileRepositoryProvider = Provider<ProfileRepository>((ref) => ProfileRepository(ref.watch(apiClientProvider)));

/// The signed-in user's profile. The last copy shows straight away, offline too,
/// and is refreshed from the server.
class ProfileController extends AsyncNotifier<Profile?> {
  ProfileRepository get _repo => ref.read(profileRepositoryProvider);
  AppDatabase get _db => ref.read(databaseProvider);

  @override
  Future<Profile?> build() async {
    final step = ref.watch(authControllerProvider.select((auth) => auth.step));
    if (step != AuthStep.signedIn) return null;
    final cached = await _db.getSetting(profileSettingKey);
    if (cached != null) {
      unawaited(refresh());
      return Profile.fromJson((jsonDecode(cached) as Map).cast<String, dynamic>());
    }
    try {
      final profile = await _repo.fetch();
      if (profile != null) await _keep(profile);
      return profile;
    } on OfflineException {
      return null;
    }
  }

  Future<void> refresh() async {
    try {
      final profile = await _repo.fetch();
      if (profile != null) await _set(profile);
    } on OfflineException {
      // The copy on the phone stays
    }
  }

  Future<ProfileErrors?> updateDetails({
    required String firstName,
    required String lastName,
    required String bio,
    required String phone,
  }) =>
      _apply(() => _repo.update({'first_name': firstName, 'last_name': lastName, 'bio': bio, 'phone': phone}));

  Future<UsernameCheck?> checkUsername(String username) async {
    try {
      return await _repo.checkUsername(username);
    } on OfflineException {
      return null;
    }
  }

  Future<ProfileErrors?> changeUsername(String username, {String? password}) =>
      _apply(() => _repo.changeUsername(username, password: password));

  Future<ProfileErrors?> uploadAvatar(List<int> bytes) => _apply(() => _repo.uploadAvatar(bytes));

  Future<ProfileErrors?> removeAvatar() async {
    try {
      final error = await _repo.removeAvatar();
      final profile = state.value;
      if (error == null && profile != null) {
        await _set(Profile.fromJson({...profile.toJson(), 'avatar_url': null}));
      }
      return error;
    } on OfflineException {
      return ProfileErrors.offline;
    }
  }

  /// After a password is set for the first time, the account has one.
  Future<void> passwordSet() async {
    final profile = state.value;
    if (profile != null && !profile.hasPassword) {
      await _set(Profile.fromJson({...profile.toJson(), 'has_password': true}));
    }
  }

  Future<ProfileErrors?> _apply(Future<(Profile?, ProfileErrors?)> Function() call) async {
    try {
      final (profile, error) = await call();
      if (profile != null) await _set(profile);
      return error;
    } on OfflineException {
      return ProfileErrors.offline;
    }
  }

  Future<void> _set(Profile profile) async {
    // An answer that lands after logging out belongs to nobody
    if (ref.read(authControllerProvider).step != AuthStep.signedIn) return;
    await _keep(profile);
    state = AsyncData(profile);
  }

  Future<void> _keep(Profile profile) => _db.setSetting(profileSettingKey, jsonEncode(profile.toJson()));
}

final profileProvider = AsyncNotifierProvider<ProfileController, Profile?>(ProfileController.new);

/// The picture behind an avatar URL. Kept while the app runs; the URL changes with the picture.
final avatarBytesProvider = FutureProvider.family<Uint8List?, String>((ref, url) async {
  try {
    return await ref.read(profileRepositoryProvider).avatarBytes(url);
  } on OfflineException {
    return null;
  }
});
