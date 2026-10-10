import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/providers.dart';
import '../../core/ui.dart';
import 'profile_repository.dart';

/// Picks a picture and lets the user crop it to a circle. Swapped out in tests,
/// where the platform pickers do not run.
class AvatarPicker {
  const AvatarPicker();

  /// The cropper runs on phones and the web; elsewhere the server squares the picture.
  static bool get canCrop =>
      kIsWeb || defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS;

  static bool get hasCamera =>
      !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);

  /// Null when the user backs out of the picker or the cropper.
  Future<Uint8List?> pick(BuildContext context, ImageSource source) async {
    final picked = await ImagePicker().pickImage(source: source, maxWidth: 2048, maxHeight: 2048);
    if (picked == null || !context.mounted) return null;
    if (!canCrop) return picked.readAsBytes();

    final l10n = context.l10n;
    final colors = context.colors;
    final scheme = Theme.of(context).colorScheme;
    final cropped = await ImageCropper().cropImage(
      sourcePath: picked.path,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      maxWidth: 1024,
      maxHeight: 1024,
      compressFormat: ImageCompressFormat.jpg,
      compressQuality: 90,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: l10n.cropPhoto,
          toolbarColor: colors.header,
          toolbarWidgetColor: colors.onHeader,
          statusBarLight: false,
          activeControlsWidgetColor: scheme.primary,
          lockAspectRatio: true,
          cropStyle: CropStyle.circle,
          aspectRatioPresets: const [CropAspectRatioPreset.square],
        ),
        IOSUiSettings(
          title: l10n.cropPhoto,
          aspectRatioLockEnabled: true,
          resetAspectRatioEnabled: false,
          aspectRatioPickerButtonHidden: true,
          cropStyle: CropStyle.circle,
          doneButtonTitle: l10n.save,
          cancelButtonTitle: l10n.cancel,
        ),
        WebUiSettings(context: context),
      ],
    );
    return cropped?.readAsBytes();
  }
}

final avatarPickerProvider = Provider<AvatarPicker>((ref) => const AvatarPicker());

/// The signed-in user's picture, or their initials.
class UserAvatar extends ConsumerWidget {
  const UserAvatar({super.key, this.size = 40, this.busy = false});

  final double size;
  final bool busy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider).value;
    final url = profile?.avatarUrl;
    final image = url == null ? null : ref.watch(avatarBytesProvider(url)).value;
    return AvatarCircle(initials: profile?.initials ?? '', image: image, size: size, busy: busy);
  }
}

String _errorText(BuildContext context, ProfileErrors errors) =>
    errors.isOffline ? context.l10n.offlineError : errors.message;

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  bool _uploading = false;

  ProfileController get _profile => ref.read(profileProvider.notifier);

  Future<void> _changePhoto(Profile profile) async {
    final l10n = context.l10n;
    final choice = await showAppSheet<String>(
      context,
      title: l10n.changePhoto,
      builder: (context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: Text(l10n.chooseFromGallery),
            onTap: () => Navigator.pop(context, 'gallery'),
          ),
          if (AvatarPicker.hasCamera)
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text(l10n.takePhoto),
              onTap: () => Navigator.pop(context, 'camera'),
            ),
          if (profile.avatarUrl != null)
            ListTile(
              leading: Icon(Icons.delete_outline_rounded, color: Theme.of(context).colorScheme.error),
              title: Text(l10n.removePhoto, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              onTap: () => Navigator.pop(context, 'remove'),
            ),
        ],
      ),
    );
    if (choice == null || !mounted) return;

    if (choice == 'remove') {
      setState(() => _uploading = true);
      final error = await _profile.removeAvatar();
      if (!mounted) return;
      setState(() => _uploading = false);
      context.showMessage(error == null ? l10n.photoRemoved : _errorText(context, error));
      return;
    }

    final bytes = await ref
        .read(avatarPickerProvider)
        .pick(context, choice == 'camera' ? ImageSource.camera : ImageSource.gallery);
    if (bytes == null || !mounted) return;
    setState(() => _uploading = true);
    final error = await _profile.uploadAvatar(bytes);
    if (!mounted) return;
    setState(() => _uploading = false);
    context.showMessage(error == null ? l10n.photoUpdated : _errorText(context, error));
  }

  Future<void> _changePassword(Profile profile) async {
    final changed = await showAppSheet<bool>(
      context,
      title: profile.hasPassword ? context.l10n.changePassword : context.l10n.setPassword,
      builder: (context) => _ChangePasswordForm(hasPassword: profile.hasPassword),
    );
    if (changed != true || !mounted) return;
    if (!profile.hasPassword) await _profile.passwordSet();
    if (mounted) context.showMessage(context.l10n.passwordUpdated);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    final profile = ref.watch(profileProvider).value;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.profile)),
      body: profile == null
          ? Center(
              child: ref.watch(profileProvider).isLoading
                  ? const AppLoader()
                  : Padding(
                      padding: const EdgeInsets.all(AppSpace.xl),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(l10n.needsConnectionRetry, textAlign: TextAlign.center),
                          const SizedBox(height: AppSpace.md),
                          TextButton(onPressed: () => ref.invalidate(profileProvider), child: Text(l10n.retry)),
                        ],
                      ),
                    ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(AppSpace.page, AppSpace.sm, AppSpace.page, AppSpace.xl),
              children: [
                Center(
                  child: Stack(
                    children: [
                      Pressable(
                        onTap: _uploading ? () {} : () => _changePhoto(profile),
                        child: Semantics(
                          button: true,
                          label: l10n.changePhoto,
                          child: UserAvatar(size: 104, busy: _uploading),
                        ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: IgnorePointer(
                          child: CircleAvatar(
                            radius: 16,
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            child: Icon(Icons.photo_camera_outlined, size: 18, color: Theme.of(context).colorScheme.onPrimary),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpace.md),
                Text(profile.displayName, textAlign: TextAlign.center, style: text.titleLarge),
                Text('@${profile.username} · ${profile.email}',
                    textAlign: TextAlign.center, style: text.bodyMedium?.copyWith(color: context.colors.muted)),
                const SizedBox(height: AppSpace.xl),
                _Section(title: l10n.username, child: _UsernameSection(profile: profile)),
                _Section(title: l10n.profileDetails, child: _DetailsSection(profile: profile)),
                _Section(
                  title: l10n.signInAndSecurity,
                  padded: false,
                  child: ListTile(
                    leading: const Icon(Icons.lock_reset_rounded),
                    title: Text(profile.hasPassword ? l10n.changePassword : l10n.setPassword),
                    subtitle: profile.hasPassword ? null : Text(l10n.setPasswordHint),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => _changePassword(profile),
                  ),
                ),
              ],
            ),
    );
  }
}

/// A titled card, like the groups in Settings.
class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child, this.padded = true});

  final String title;
  final Widget child;
  final bool padded;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpace.xs, 0, AppSpace.xs, AppSpace.sm),
            child: Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(color: context.colors.muted)),
          ),
          Card(
            margin: const EdgeInsets.only(bottom: AppSpace.lg),
            clipBehavior: Clip.antiAlias,
            child: padded ? Padding(padding: const EdgeInsets.all(AppSpace.lg), child: child) : child,
          ),
        ],
      );
}

/// The username box: checks with the server while the user types, then asks for
/// the password before saving.
class _UsernameSection extends ConsumerStatefulWidget {
  const _UsernameSection({required this.profile});

  final Profile profile;

  @override
  ConsumerState<_UsernameSection> createState() => _UsernameSectionState();
}

class _UsernameSectionState extends ConsumerState<_UsernameSection> {
  static const debounce = Duration(milliseconds: 400);
  static final _allowed = RegExp(r'^[\w.+-]{1,150}$');

  late final _controller = TextEditingController(text: widget.profile.username);
  Timer? _debounce;

  /// Answers to older checks are dropped when a newer one was asked.
  int _ticket = 0;
  bool _checking = false;
  UsernameCheck? _check;
  bool _saving = false;
  String? _serverError;

  String get _value => _controller.text.trim();
  bool get _unchanged => _value == widget.profile.username;

  bool get _canSave => !_unchanged && !_checking && !_saving && (_check?.available ?? false);

  @override
  void didUpdateWidget(_UsernameSection old) {
    super.didUpdateWidget(old);
    if (old.profile.username != widget.profile.username && _controller.text.trim() == old.profile.username) {
      _controller.text = widget.profile.username;
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _changed(String _) {
    _debounce?.cancel();
    _ticket++;
    setState(() {
      _serverError = null;
      _check = null;
      _checking = false;
      if (_unchanged) return;
      if (!_allowed.hasMatch(_value)) {
        // No need to ask the server about an @ or a space
        _check = const UsernameCheck(available: false, reason: 'invalid');
        return;
      }
      _checking = true;
    });
    if (_checking) _debounce = Timer(debounce, () => _ask(_value));
  }

  Future<void> _ask(String username) async {
    final ticket = _ticket;
    final check = await ref.read(profileProvider.notifier).checkUsername(username);
    if (!mounted || ticket != _ticket) return;
    setState(() {
      _checking = false;
      _check = check;
    });
  }

  void _useSuggestion(String username) {
    _debounce?.cancel();
    _ticket++;
    _controller.text = username;
    // The server just said it is free
    setState(() {
      _serverError = null;
      _checking = false;
      _check = const UsernameCheck(available: true);
    });
  }

  Future<void> _save() async {
    final l10n = context.l10n;
    final profile = ref.read(profileProvider.notifier);
    final username = _value;
    ProfileErrors? errors;
    if (widget.profile.hasPassword) {
      final answer = await confirmWithPassword(
        context,
        (password) => profile.changeUsername(username, password: password),
      );
      if (answer == null) return; // cancelled
      (errors,) = answer;
    } else {
      // Made with Google: there is no password to confirm with
      setState(() => _saving = true);
      errors = await profile.changeUsername(username);
      if (!mounted) return;
      setState(() => _saving = false);
    }
    if (!mounted) return;
    if (errors == null) {
      setState(() => _check = null);
      context.showMessage(l10n.usernameChanged);
    } else if (errors['username'] != null) {
      setState(() => _serverError = errors!['username']);
    } else {
      context.showMessage(_errorText(context, errors));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    Widget status(IconData? icon, String label, Color color) => Row(
          key: ValueKey(label),
          children: [
            if (icon != null) Icon(icon, size: 18, color: color) else AppLoader(size: 5, color: color),
            const SizedBox(width: AppSpace.sm),
            Expanded(child: Text(label, style: text.bodyMedium?.copyWith(color: color))),
          ],
        );

    final check = _check;
    final Widget line = _unchanged
        ? status(Icons.verified_user_outlined, l10n.usernameYours, context.colors.muted)
        : _checking
            ? status(null, l10n.usernameChecking, context.colors.muted)
            : check == null
                ? const SizedBox.shrink()
                : check.available
                    ? status(Icons.check_circle_rounded, l10n.usernameAvailable, context.colors.moneyIn)
                    : status(
                        Icons.cancel_rounded,
                        check.reason == 'taken' ? l10n.usernameTaken : l10n.usernameInvalid,
                        scheme.error,
                      );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: _controller,
          autocorrect: false,
          enableSuggestions: false,
          maxLength: 150,
          buildCounter: quietCounter,
          decoration: InputDecoration(
            labelText: l10n.username,
            prefixText: '@',
            helperText: l10n.usernameHint,
            errorText: _serverError,
          ),
          onChanged: _changed,
        ),
        const SizedBox(height: AppSpace.sm),
        AnimatedSwitcher(duration: context.motion(AppMotion.standard), child: line),
        if (!_checking && (check?.suggestions.isNotEmpty ?? false)) ...[
          const SizedBox(height: AppSpace.md),
          Text(l10n.usernameSuggestions, style: text.bodySmall?.copyWith(color: context.colors.muted)),
          const SizedBox(height: AppSpace.xs),
          Wrap(
            spacing: AppSpace.sm,
            runSpacing: AppSpace.xs,
            children: [
              for (final suggestion in check!.suggestions)
                ActionChip(label: Text(suggestion), onPressed: () => _useSuggestion(suggestion)),
            ],
          ),
        ],
        const SizedBox(height: AppSpace.lg),
        BusyButton(label: l10n.changeUsername, busy: _saving, onPressed: _canSave ? _save : null),
      ],
    );
  }
}

/// Name, about and phone, saved together.
class _DetailsSection extends ConsumerStatefulWidget {
  const _DetailsSection({required this.profile});

  final Profile profile;

  @override
  ConsumerState<_DetailsSection> createState() => _DetailsSectionState();
}

class _DetailsSectionState extends ConsumerState<_DetailsSection> {
  late final _firstName = TextEditingController(text: widget.profile.firstName);
  late final _lastName = TextEditingController(text: widget.profile.lastName);
  late final _bio = TextEditingController(text: widget.profile.bio);
  late final _phone = TextEditingController(text: widget.profile.phone);
  bool _saving = false;

  @override
  void dispose() {
    for (final controller in [_firstName, _lastName, _bio, _phone]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = context.l10n;
    setState(() => _saving = true);
    final errors = await ref.read(profileProvider.notifier).updateDetails(
          firstName: _firstName.text.trim(),
          lastName: _lastName.text.trim(),
          bio: _bio.text.trim(),
          phone: _phone.text.trim(),
        );
    if (!mounted) return;
    setState(() => _saving = false);
    context.showMessage(errors == null ? l10n.profileSaved : _errorText(context, errors));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _firstName,
                maxLength: 30,
                buildCounter: quietCounter,
                textCapitalization: TextCapitalization.words,
                autofillHints: const [AutofillHints.givenName],
                decoration: InputDecoration(labelText: l10n.firstName),
              ),
            ),
            const SizedBox(width: AppSpace.md),
            Expanded(
              child: TextFormField(
                controller: _lastName,
                maxLength: 30,
                buildCounter: quietCounter,
                textCapitalization: TextCapitalization.words,
                autofillHints: const [AutofillHints.familyName],
                decoration: InputDecoration(labelText: l10n.lastName),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpace.md),
        TextFormField(
          controller: _phone,
          maxLength: 20,
          buildCounter: quietCounter,
          keyboardType: TextInputType.phone,
          autofillHints: const [AutofillHints.telephoneNumber],
          decoration: InputDecoration(labelText: l10n.phone, prefixIcon: const Icon(Icons.phone_outlined)),
        ),
        const SizedBox(height: AppSpace.md),
        TextFormField(
          controller: _bio,
          maxLength: 500,
          buildCounter: quietCounter,
          minLines: 2,
          maxLines: 5,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(labelText: l10n.bio, alignLabelWithHint: true),
        ),
        const SizedBox(height: AppSpace.lg),
        BusyButton(label: l10n.save, busy: _saving, onPressed: _save),
      ],
    );
  }
}


/// Asks for the password, then runs [action] with it. A wrong password keeps the
/// sheet open with the reason under the field. Null when cancelled, else what
/// [action] answered: null inside means it went through.
Future<(ProfileErrors?,)?> confirmWithPassword(
  BuildContext context,
  Future<ProfileErrors?> Function(String password) action,
) =>
    showAppSheet<(ProfileErrors?,)>(
      context,
      title: context.l10n.confirmChange,
      builder: (context) => _ConfirmPasswordForm(action: action),
    );

class _ConfirmPasswordForm extends StatefulWidget {
  const _ConfirmPasswordForm({required this.action});

  final Future<ProfileErrors?> Function(String password) action;

  @override
  State<_ConfirmPasswordForm> createState() => _ConfirmPasswordFormState();
}

class _ConfirmPasswordFormState extends State<_ConfirmPasswordForm> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final errors = await widget.action(_password.text);
    if (!mounted) return;
    if (errors?['password'] != null) {
      setState(() {
        _busy = false;
        _error = errors!['password'];
      });
      return;
    }
    Navigator.pop(context, (errors,));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.confirmWithPassword, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: AppSpace.lg),
          PasswordField(
            controller: _password,
            label: l10n.password,
            autofocus: true,
            errorText: _error,
            validator: (value) => (value ?? '').isEmpty ? l10n.enterCurrentPassword : null,
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: AppSpace.lg),
          BusyButton(label: l10n.confirmChange, busy: _busy, onPressed: _submit),
        ],
      ),
    );
  }
}

/// Current, new and again-new password. Without a password yet (Google), only the new one twice.
class _ChangePasswordForm extends ConsumerStatefulWidget {
  const _ChangePasswordForm({required this.hasPassword});

  final bool hasPassword;

  @override
  ConsumerState<_ChangePasswordForm> createState() => _ChangePasswordFormState();
}

class _ChangePasswordFormState extends ConsumerState<_ChangePasswordForm> {
  final _formKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final error = await ref.read(authControllerProvider.notifier).changePassword(
          current: widget.hasPassword ? _current.text : null,
          next: _next.text,
        );
    if (!mounted) return;
    if (error != null) {
      setState(() {
        _busy = false;
        _error = authErrorText(context, error);
      });
      return;
    }
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.hasPassword) ...[
            PasswordField(
              controller: _current,
              label: l10n.currentPassword,
              autofocus: true,
              textInputAction: TextInputAction.next,
              validator: (value) => (value ?? '').isEmpty ? l10n.enterCurrentPassword : null,
            ),
            const SizedBox(height: AppSpace.md),
          ] else ...[
            Text(l10n.setPasswordHint, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: AppSpace.lg),
          ],
          PasswordField(
            controller: _next,
            label: l10n.newPassword,
            newPassword: true,
            autofocus: !widget.hasPassword,
            textInputAction: TextInputAction.next,
            validator: (value) {
              final short = validateNewPassword(context, value);
              if (short != null) return short;
              return widget.hasPassword && value == _current.text ? l10n.passwordSameAsCurrent : null;
            },
          ),
          const SizedBox(height: AppSpace.md),
          PasswordField(
            controller: _confirm,
            label: l10n.confirmNewPassword,
            newPassword: true,
            validator: (value) => validatePasswordMatch(context, value, _next),
            onSubmitted: (_) => _submit(),
          ),
          if (_error != null) ...[
            const SizedBox(height: AppSpace.md),
            Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
          const SizedBox(height: AppSpace.lg),
          BusyButton(label: l10n.save, busy: _busy, onPressed: _submit),
        ],
      ),
    );
  }
}
