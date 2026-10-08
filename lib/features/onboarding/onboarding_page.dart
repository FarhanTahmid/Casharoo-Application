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

  /// The card that was tapped; it shows the loader while its workspace is made.
  int? _chosen;

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
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    final actions = ref.read(workspaceActionsProvider);

    Widget choice(int index, IconData icon, String title, String hint, VoidCallback onTap) {
      final chosen = _chosen == index;
      return Entrance(
        index: index,
        child: AnimatedOpacity(
          // The other cards step back while the chosen one works
          opacity: _busy && !chosen ? 0.45 : 1,
          duration: context.motion(AppMotion.standard),
          child: Padding(
            padding: const EdgeInsets.only(bottom: AppSpace.md),
            child: Pressable(
              onTap: _busy
                  ? null
                  : () {
                      setState(() => _chosen = index);
                      onTap();
                    },
              child: AnimatedContainer(
                duration: context.motion(AppMotion.standard),
                padding: const EdgeInsets.all(AppSpace.lg),
                decoration: BoxDecoration(
                  color: colors.sheet,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  border: Border.all(
                    color: chosen ? Theme.of(context).colorScheme.primary : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    IconBadge(icon, size: 52),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: text.titleMedium),
                          const SizedBox(height: 2),
                          Text(hint, style: text.bodyMedium?.copyWith(color: colors.muted)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    PopSwitcher(
                      child: _busy && chosen
                          ? const AppLoader(key: ValueKey('busy'), size: 7)
                          : Icon(Icons.chevron_right_rounded, key: const ValueKey('go'), color: colors.muted),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: colors.header,
        body: SafeArea(
          bottom: false,
          child: PassbookBody(
            header: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                const BrandLogo(height: 60),
                const SizedBox(height: 18),
                Text(l10n.welcomeTitle, style: text.headlineSmall?.copyWith(color: colors.onHeader)),
                const SizedBox(height: 10),
              ],
            ),
            child: Align(
              alignment: Alignment.topCenter,
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(AppSpace.page, 20, AppSpace.page, 24 + MediaQuery.paddingOf(context).bottom),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      choice(0, Icons.person_rounded, l10n.forMyself, l10n.forMyselfHint, () => _finish('personal')),
                      choice(1, Icons.storefront_rounded, l10n.forMyBusiness, l10n.forMyBusinessHint, () async {
                        final name = await promptText(context, title: l10n.createBusiness, label: l10n.businessName);
                        if (name != null) {
                          await _finish('business', () => actions.createBusiness(name, id: _businessId));
                        } else if (mounted) {
                          setState(() => _chosen = null);
                        }
                      }),
                      choice(2, Icons.science_outlined, l10n.tryDemo, l10n.tryDemoHint,
                          () => _finish('business', actions.createDemo)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
