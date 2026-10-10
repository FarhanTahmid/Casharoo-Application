import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config.dart';
import '../../core/entitlements/entitlements_controller.dart';
import '../../core/providers.dart';
import '../../core/ui.dart';
import '../profile/profile_page.dart';
import '../profile/profile_repository.dart';
import '../shell/home_shell.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final status = ref.watch(syncControllerProvider);
    final pending = ref.watch(pendingChangesProvider).value ?? 0;
    final failures = ref.watch(syncFailuresProvider).value ?? const [];
    final workspace = ref.watch(currentWorkspaceProvider);
    final db = ref.read(databaseProvider);
    final profile = ref.watch(profileProvider).value;
    final plan = ref.watch(entitlementsProvider).value;
    final locked = plan?.locks.fold<int>(0, (sum, lock) => sum + lock.locked.length) ?? 0;

    final syncText = status.syncing
        ? l10n.syncing
        : status.offline
            ? l10n.offlineStatus
            : status.error != null
                ? l10n.syncError(status.error!)
                : pending > 0
                    ? l10n.pendingChanges(pending)
                    : l10n.allSynced;

    /// A group of rows on one card.
    Widget group(List<Widget> rows) => Card(
          margin: const EdgeInsets.only(bottom: AppSpace.md),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (final (index, row) in rows.indexed) ...[
                if (index > 0) const Divider(indent: 56),
                row,
              ],
            ],
          ),
        );

    /// A setting whose choices sit under its name.
    Widget choiceRow(IconData icon, String title, Widget control) => Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(children: [
                Icon(icon, color: context.colors.muted),
                const SizedBox(width: 16),
                Text(title, style: text.bodyLarge?.copyWith(fontWeight: FontWeight.w500)),
              ]),
              const SizedBox(height: 12),
              control,
            ],
          ),
        );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpace.page, AppSpace.sm, AppSpace.page, AppSpace.xl),
        children: [
          group([
            ListTile(
              contentPadding: const EdgeInsets.fromLTRB(16, 8, 12, 8),
              leading: const UserAvatar(size: 44),
              title: Text(profile?.displayName ?? l10n.profile),
              subtitle: Text(profile == null ? l10n.profileHint : '@${profile.username}'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => context.push('/profile'),
            ),
            ListTile(
              leading: const Icon(Icons.workspace_premium_outlined),
              title: Text(l10n.plan),
              subtitle: Text([
                if (plan != null) plan.plan.nameIn(context.languageCode),
                if (locked > 0) l10n.keepLockedCount(locked),
              ].join(' · ')),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => context.push('/plan'),
            ),
          ]),
          group([
            choiceRow(
              Icons.language_rounded,
              l10n.language,
              SlidingSegmented<String>(
                segments: {'en': l10n.english, 'bn': l10n.bangla},
                value: ref.watch(localeProvider).languageCode,
                onChanged: (code) => ref.read(localeProvider.notifier).set(Locale(code)),
              ),
            ),
            choiceRow(
              Icons.brightness_6_outlined,
              l10n.theme,
              SlidingSegmented<ThemeMode>(
                segments: {
                  ThemeMode.system: l10n.themeSystem,
                  ThemeMode.light: l10n.themeLight,
                  ThemeMode.dark: l10n.themeDark,
                },
                value: ref.watch(themeModeProvider),
                onChanged: (mode) => ref.read(themeModeProvider.notifier).set(mode),
              ),
            ),
            // The server lets only the owner or an admin change it
            if (workspace != null && (workspace.role == 'owner' || workspace.role == 'admin'))
              ListTile(
                leading: const Icon(Icons.payments_outlined),
                title: Text(l10n.defaultCurrency),
                subtitle: Text(l10n.defaultCurrencyHint),
                trailing: Text(
                  workspace.defaultCurrency,
                  style: text.titleMedium?.copyWith(color: scheme.primary),
                ),
                onTap: () async {
                  final picked = await showSelectSheet<String>(
                    context,
                    title: l10n.defaultCurrency,
                    value: workspace.defaultCurrency,
                    options: currencyOptions(include: workspace.defaultCurrency),
                  );
                  final code = picked?.value;
                  if (code == null || code == workspace.defaultCurrency) return;
                  final changed = await ref.read(workspaceActionsProvider).setDefaultCurrency(workspace.id, code);
                  if (context.mounted && !changed) context.showMessage(l10n.needsConnection);
                },
              ),
            if (workspace != null && workspace.kind == 'personal')
              ListTile(
                leading: const Icon(Icons.sell_outlined),
                title: Text(l10n.categories),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => context.push('/categories'),
              ),
          ]),
          group([
            ListTile(
              leading: SpinWhile(active: status.syncing, child: const Icon(Icons.sync_rounded)),
              title: Text(l10n.sync),
              subtitle: Text(syncText),
              trailing: TextButton(
                onPressed: status.syncing ? null : ref.read(syncControllerProvider.notifier).syncNow,
                child: Text(l10n.syncNow),
              ),
            ),
            if (failures.isNotEmpty) ...[
              ListTile(
                leading: Icon(Icons.error_outline_rounded, color: scheme.error),
                title: Text('${l10n.notSynced} (${failures.length})'),
                subtitle: Text(l10n.notSyncedHint),
                trailing: TextButton(
                  onPressed: () => db.delete(db.syncFailures).go(),
                  child: Text(l10n.dismiss),
                ),
              ),
              for (final failure in failures.take(20))
                ListTile(
                  dense: true,
                  contentPadding: const EdgeInsets.only(left: 56, right: 16),
                  title: Text('${failure.tableName_}: ${failure.code}'),
                  subtitle: Text(failure.detail),
                ),
            ],
          ]),
          group([
            if (AppConfig.feedbackEmail.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.feedback_outlined),
                title: Text(l10n.sendFeedback),
                subtitle: Text('${l10n.sendFeedbackHint}\n${AppConfig.feedbackEmail}'),
                isThreeLine: true,
                trailing: const Icon(Icons.copy_rounded),
                onTap: () async {
                  await Clipboard.setData(const ClipboardData(text: AppConfig.feedbackEmail));
                  if (context.mounted) context.showMessage(AppConfig.feedbackEmail);
                },
              ),
            if (AppConfig.allowsServerOverride)
              ListTile(
                leading: const Icon(Icons.dns_outlined),
                title: Text(l10n.server),
                subtitle: Text('${ref.watch(serverUrlProvider)} · ${AppConfig.flavor}'),
                onTap: () => _changeServer(context, ref),
              ),
            ListTile(
              leading: const Icon(Icons.logout_rounded),
              title: Text(l10n.logOut),
              subtitle: ref.watch(authControllerProvider).email == null
                  ? null
                  : Text(ref.watch(authControllerProvider).email!),
              onTap: () async {
                final warning = pending > 0 ? '\n\n${l10n.logOutUnsynced(pending)}' : '';
                if (await confirm(context, '${l10n.logOutConfirm}$warning', action: l10n.logOut)) {
                  await ref.read(authControllerProvider.notifier).logOut();
                }
              },
            ),
          ]),
          // Apart from the rest, and red: it cannot be undone
          if (workspace != null && workspace.kind == 'business' && workspace.role == 'owner')
            group([
              ListTile(
                leading: Icon(Icons.delete_outline_rounded, color: scheme.error),
                title: Text(l10n.deleteWorkspace, style: TextStyle(color: scheme.error)),
                subtitle: Text(workspaceLabel(context, workspace)),
                onTap: () async {
                  if (!await confirm(context, l10n.deleteWorkspaceConfirm)) return;
                  final deleted = await ref.read(workspaceActionsProvider).delete(workspace.id);
                  if (!context.mounted) return;
                  deleted ? context.pop() : context.showMessage(l10n.needsConnection);
                },
              ),
            ]),
        ],
      ),
    );
  }
}

/// Points a test build at another API. The data on the phone belongs to the old
/// server, so switching signs out and clears it.
Future<void> _changeServer(BuildContext context, WidgetRef ref) async {
  final l10n = context.l10n;
  final controller = TextEditingController(text: ref.read(serverUrlProvider));
  final formKey = GlobalKey<FormState>();
  final choice = await showAppSheet<(String?,)>(
    context,
    title: l10n.server,
    builder: (context) => Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: controller,
            autofocus: true,
            keyboardType: TextInputType.url,
            decoration: InputDecoration(helperText: l10n.serverHint, helperMaxLines: 2),
            validator: (value) {
              final uri = Uri.tryParse((value ?? '').trim());
              return uri != null && (uri.scheme == 'http' || uri.scheme == 'https') && uri.host.isNotEmpty
                  ? null
                  : l10n.serverInvalid;
            },
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              var url = controller.text.trim();
              while (url.endsWith('/')) {
                url = url.substring(0, url.length - 1);
              }
              Navigator.pop(context, (url,));
            },
            child: Text(l10n.save),
          ),
          const SizedBox(height: 4),
          TextButton(onPressed: () => Navigator.pop(context, (null,)), child: Text(l10n.resetToDefault)),
        ],
      ),
    ),
  );
  if (choice == null || !context.mounted) return;
  final (url,) = choice;
  if ((url ?? AppConfig.apiUrl) == ref.read(serverUrlProvider)) return;
  if (!await confirm(context, l10n.serverChangeConfirm, action: l10n.save)) return;
  await ref.read(authControllerProvider.notifier).sessionExpired();
  await ref.read(serverUrlProvider.notifier).set(url);
}
