import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../core/ui.dart';
import '../shell/home_shell.dart';

const onboardedSettingKey = 'onboarded';

/// True once the individual-or-business question has been answered on this device.
class OnboardedController extends Notifier<bool?> {
  @override
  bool? build() {
    ref.read(databaseProvider).getSetting(onboardedSettingKey).then((value) => state = value == 'yes');
    return null; // not known yet
  }

  Future<void> complete() async {
    state = true;
    await ref.read(databaseProvider).setSetting(onboardedSettingKey, 'yes');
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

  Future<void> _finish([Future<String?> Function()? create]) async {
    if (create != null) {
      setState(() => _busy = true);
      final id = await create();
      if (!mounted) return;
      setState(() => _busy = false);
      if (id == null) return context.showMessage(context.l10n.needsConnection);
    }
    await ref.read(onboardedProvider.notifier).complete();
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
                  const Icon(Icons.account_balance_wallet_rounded, size: 56, color: AppTheme.primaryColor),
                  const SizedBox(height: 16),
                  Text(l10n.welcomeTitle, textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 32),
                  choice(Icons.person, l10n.forMyself, l10n.forMyselfHint, _finish),
                  choice(Icons.storefront, l10n.forMyBusiness, l10n.forMyBusinessHint, () async {
                    final name = await promptText(context, title: l10n.createBusiness, label: l10n.businessName);
                    if (name != null) await _finish(() => actions.createBusiness(name));
                  }),
                  choice(Icons.science_outlined, l10n.tryDemo, l10n.tryDemoHint, () => _finish(actions.createDemo)),
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
