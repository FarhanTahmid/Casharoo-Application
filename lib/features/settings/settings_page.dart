import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../core/ui.dart';
import '../shell/home_shell.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final status = ref.watch(syncControllerProvider);
    final pending = ref.watch(pendingChangesProvider).value ?? 0;
    final failures = ref.watch(syncFailuresProvider).value ?? const [];
    final workspace = ref.watch(currentWorkspaceProvider);
    final db = ref.read(databaseProvider);

    final syncText = status.syncing
        ? l10n.syncing
        : status.offline
            ? l10n.offlineStatus
            : status.error != null
                ? l10n.syncError(status.error!)
                : pending > 0
                    ? l10n.pendingChanges(pending)
                    : l10n.allSynced;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(l10n.language),
            trailing: SegmentedButton<String>(
              segments: [
                ButtonSegment(value: 'en', label: Text(l10n.english)),
                ButtonSegment(value: 'bn', label: Text(l10n.bangla)),
              ],
              selected: {ref.watch(localeProvider).languageCode},
              onSelectionChanged: (selection) => ref.read(localeProvider.notifier).set(Locale(selection.first)),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.brightness_6_outlined),
            title: Text(l10n.theme),
            trailing: DropdownButton<ThemeMode>(
              value: ref.watch(themeModeProvider),
              underline: const SizedBox.shrink(),
              items: [
                DropdownMenuItem(value: ThemeMode.system, child: Text(l10n.themeSystem)),
                DropdownMenuItem(value: ThemeMode.light, child: Text(l10n.themeLight)),
                DropdownMenuItem(value: ThemeMode.dark, child: Text(l10n.themeDark)),
              ],
              onChanged: (mode) => ref.read(themeModeProvider.notifier).set(mode!),
            ),
          ),
          if (workspace != null && workspace.kind == 'personal')
            ListTile(
              leading: const Icon(Icons.category_outlined),
              title: Text(l10n.categories),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/categories'),
            ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.sync),
            title: Text(l10n.sync),
            subtitle: Text(syncText),
            trailing: TextButton(
              onPressed: status.syncing ? null : ref.read(syncControllerProvider.notifier).syncNow,
              child: Text(l10n.syncNow),
            ),
          ),
          if (failures.isNotEmpty) ...[
            ListTile(
              leading: const Icon(Icons.error_outline, color: AppTheme.errorColor),
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
                contentPadding: const EdgeInsets.only(left: 72, right: 16),
                title: Text('${failure.tableName_}: ${failure.code}'),
                subtitle: Text(failure.detail),
              ),
          ],
          const Divider(),
          if (workspace != null && workspace.kind == 'business' && workspace.role == 'owner')
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: Text(l10n.deleteWorkspace),
              subtitle: Text(workspaceLabel(context, workspace)),
              onTap: () async {
                if (!await confirm(context, l10n.deleteWorkspaceConfirm)) return;
                final deleted = await ref.read(workspaceActionsProvider).delete(workspace.id);
                if (!context.mounted) return;
                deleted ? context.pop() : context.showMessage(l10n.needsConnection);
              },
            ),
          if (AppConfig.feedbackEmail.isNotEmpty)
            ListTile(
              leading: const Icon(Icons.feedback_outlined),
              title: Text(l10n.sendFeedback),
              subtitle: Text('${l10n.sendFeedbackHint}\n${AppConfig.feedbackEmail}'),
              isThreeLine: true,
              trailing: const Icon(Icons.copy),
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
            leading: const Icon(Icons.logout),
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
  final choice = await showDialog<(String?,)>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.server),
      content: Form(
        key: formKey,
        child: TextFormField(
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
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, (null,)), child: Text(l10n.resetToDefault)),
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
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
      ],
    ),
  );
  if (choice == null || !context.mounted) return;
  final (url,) = choice;
  if ((url ?? AppConfig.apiUrl) == ref.read(serverUrlProvider)) return;
  if (!await confirm(context, l10n.serverChangeConfirm, action: l10n.save)) return;
  await ref.read(authControllerProvider.notifier).sessionExpired();
  await ref.read(serverUrlProvider.notifier).set(url);
}
