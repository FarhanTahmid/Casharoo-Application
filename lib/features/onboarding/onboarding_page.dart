import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/auth/auth_repository.dart';
import '../../core/db/database.dart';
import '../../core/db/local_store.dart';
import '../../core/providers.dart';
import '../../core/ui.dart';
import '../shell/home_shell.dart';

/// True once the individual-or-business question has been answered for the
/// signed-in account; null while that is being found out. The answer is kept
/// on the server too, so a second phone or a reinstall skips the question.
class OnboardedController extends Notifier<bool?> {
  @override
  bool? build() {
    ref.listen(authControllerProvider, (previous, next) {
      if (next.step != previous?.step) _load();
    });
    _load();
    return null; // not known yet
  }

  Future<void> _load() async {
    final db = ref.read(databaseProvider);
    if (await db.getSetting(onboardedSettingKey) == 'yes') {
      state = true;
      return;
    }
    if (ref.read(authControllerProvider).step != AuthStep.signedIn) {
      state = false;
      return;
    }
    state = null;
    try {
      final response = await ref.read(apiClientProvider).get('/api/v1/me/');
      if (response.ok && response.json['onboarded_at'] != null) {
        await db.setSetting(onboardedSettingKey, 'yes');
        state = true;
        return;
      }
    } on OfflineException {
      // Offline on a fresh install: ask; the answer reaches the server later
    }
    state = false;
  }

  /// [mode] is 'personal' or 'business'. Sync tells the server.
  Future<void> complete(String mode) async {
    state = true;
    final db = ref.read(databaseProvider);
    await db.setSetting(onboardedSettingKey, 'yes');
    await db.setSetting(onboardingUnsentKey, mode);
    ref.read(syncControllerProvider.notifier).schedule(immediately: true);
  }
}

final onboardedProvider = NotifierProvider<OnboardedController, bool?>(OnboardedController.new);

/// First question after sign-up. The answer only decides which workspace opens
/// first: one account can hold a personal space and any number of businesses.
class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  bool _busy = false;

  /// Kept across retries, so a business whose creation reply was lost is not made twice.
  final _businessId = newId();

  /// "For myself" works offline. A business is created on the server, so it needs a connection.
  Future<void> _finish(String mode, [Future<String?> Function()? create]) async {
    if (create != null) {
      setState(() => _busy = true);
      final id = await create();
      if (!mounted) return;
      setState(() => _busy = false);
      if (id == null) return context.showMessage(context.l10n.needsConnectionRetry);
    }
    await ref.read(onboardedProvider.notifier).complete(mode);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final actions = ref.read(workspaceActionsProvider);

    Widget choice(IconData icon, String title, String hint, VoidCallback onTap) => Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(radius: 24, child: Icon(icon)),
            title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(hint),
            trailing: const Icon(Icons.chevron_right),
            onTap: _busy ? null : onTap,
          ),
        );

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const BrandLogo(),
                  const SizedBox(height: 16),
                  Text(l10n.welcomeTitle, textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 32),
                  choice(Icons.person, l10n.forMyself, l10n.forMyselfHint, () => _finish('personal')),
                  choice(Icons.storefront, l10n.forMyBusiness, l10n.forMyBusinessHint, () async {
                    final name = await promptText(context, title: l10n.createBusiness, label: l10n.businessName);
                    if (name != null) await _finish('business', () => actions.createBusiness(name, id: _businessId));
                  }),
                  choice(Icons.science_outlined, l10n.tryDemo, l10n.tryDemoHint,
                      () => _finish('business', actions.createDemo)),
                  if (_busy) const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator())),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
