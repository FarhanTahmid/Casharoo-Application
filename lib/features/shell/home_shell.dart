import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_client.dart';
import '../../core/db/database.dart';
import '../../core/db/local_store.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../core/ui.dart';
import '../cashbook/cashbook_pages.dart';
import '../personal/budget_calendar_page.dart';
import '../personal/ledger_repository.dart';
import '../personal/personal_pages.dart';

/// Creating and deleting workspaces happens on the server, so these need a connection.
class WorkspaceActions {
  WorkspaceActions(this.ref);

  final Ref ref;

  /// Returns the new workspace id, or null when offline or refused. Pass the
  /// same [id] when retrying: the server then returns the business it already made.
  Future<String?> createBusiness(String name, {String? id}) => _create(
      () => ref.read(apiClientProvider).post('/api/v1/workspaces/', {'id': id ?? newId(), 'name': name}));

  Future<String?> createDemo() => _create(() => ref.read(apiClientProvider).post('/api/v1/workspaces/demo/'));

  Future<bool> delete(String workspaceId) async {
    try {
      final response = await ref.read(apiClientProvider).delete('/api/v1/workspaces/$workspaceId/');
      if (!response.ok) return false;
      await ref.read(currentWorkspaceIdProvider.notifier).select(null);
      await ref.read(syncControllerProvider.notifier).syncNow();
      return true;
    } on OfflineException {
      return false;
    }
  }

  Future<String?> _create(Future<ApiResponse> Function() request) async {
    try {
      final response = await request();
      if (!response.ok) return null;
      final id = response.json['id'] as String;
      await ref.read(syncControllerProvider.notifier).syncNow();
      await ref.read(currentWorkspaceIdProvider.notifier).select(id);
      return id;
    } on OfflineException {
      return null;
    }
  }
}

final workspaceActionsProvider = Provider<WorkspaceActions>(WorkspaceActions.new);

/// Signed-in home. The workspace switcher at the top decides which mode is
/// shown: the personal tracker or a business's cashbooks.
class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final workspace = ref.watch(currentWorkspaceProvider);
    if (workspace == null) {
      // First launch after login: the first sync has not finished yet
      final status = ref.watch(syncControllerProvider);
      return Scaffold(
        body: Center(
          child: status.offline || status.error != null
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(status.offline ? l10n.offlineError : l10n.syncError(status.error!)),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: ref.read(syncControllerProvider.notifier).syncNow,
                      child: Text(l10n.syncNow),
                    ),
                  ],
                )
              : const CircularProgressIndicator(),
        ),
      );
    }

    final personal = workspace.kind == 'personal';
    final pages = personal
        ? [
            OverviewPage(workspace: workspace),
            TransactionsPage(workspace: workspace),
            BudgetCalendarPage(workspace: workspace),
            AccountsPage(workspace: workspace),
          ]
        : [CashbooksPage(workspace: workspace)];
    final tab = _tab < pages.length ? _tab : 0;

    return Scaffold(
      appBar: AppBar(
        title: _WorkspaceSwitcher(current: workspace, onSwitched: () => setState(() => _tab = 0)),
        actions: [
          const _SyncIndicator(),
          IconButton(icon: const Icon(Icons.settings_outlined), onPressed: () => context.push('/settings')),
        ],
      ),
      body: pages[tab],
      floatingActionButton: !personal
          ? null // the cashbooks page brings its own
          : switch (tab) {
              2 => FloatingActionButton.extended(
                  onPressed: () => showBudgetForm(context, ref, workspace, month: ref.read(selectedMonthProvider)),
                  icon: const Icon(Icons.add),
                  label: Text(l10n.addBudget),
                ),
              3 => FloatingActionButton.extended(
                  onPressed: () => showAccountForm(context, workspace),
                  icon: const Icon(Icons.add),
                  label: Text(l10n.addAccount),
                ),
              _ => FloatingActionButton.extended(
                  onPressed: () => openTransactionForm(context, workspace),
                  icon: const Icon(Icons.add),
                  label: Text(l10n.addTransaction),
                ),
            },
      bottomNavigationBar: personal
          ? NavigationBar(
              selectedIndex: tab,
              onDestinationSelected: (index) => setState(() => _tab = index),
              destinations: [
                NavigationDestination(icon: const Icon(Icons.dashboard_outlined), label: l10n.overview),
                NavigationDestination(icon: const Icon(Icons.receipt_long_outlined), label: l10n.transactions),
                NavigationDestination(icon: const Icon(Icons.savings_outlined), label: l10n.budgets),
                NavigationDestination(icon: const Icon(Icons.account_balance_wallet_outlined), label: l10n.accounts),
              ],
            )
          : null,
    );
  }
}

String workspaceLabel(BuildContext context, Workspace workspace) =>
    workspace.kind == 'personal' ? context.l10n.personal : workspace.name;

class _WorkspaceSwitcher extends ConsumerWidget {
  const _WorkspaceSwitcher({required this.current, required this.onSwitched});

  final Workspace current;
  final VoidCallback onSwitched;

  @override
  Widget build(BuildContext context, WidgetRef ref) => InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => showModalBottomSheet<void>(
          context: context,
          builder: (_) => _WorkspaceSheet(current: current, onSwitched: onSwitched),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(current.kind == 'personal' ? Icons.person : Icons.storefront, size: 20),
              const SizedBox(width: 8),
              Flexible(child: Text(workspaceLabel(context, current), overflow: TextOverflow.ellipsis)),
              const Icon(Icons.arrow_drop_down),
            ],
          ),
        ),
      );
}

class _WorkspaceSheet extends ConsumerWidget {
  const _WorkspaceSheet({required this.current, required this.onSwitched});

  final Workspace current;
  final VoidCallback onSwitched;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final workspaces = ref.watch(workspacesProvider).value ?? const <Workspace>[];
    final actions = ref.read(workspaceActionsProvider);

    Future<void> create(Future<String?> Function() action) async {
      Navigator.pop(context);
      final messenger = ScaffoldMessenger.of(context);
      final failed = l10n.needsConnection;
      if (await action() == null) {
        messenger.showSnackBar(SnackBar(content: Text(failed)));
      } else {
        onSwitched();
      }
    }

    return SafeArea(
      child: ListView(
        shrinkWrap: true,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(l10n.switchWorkspace, style: Theme.of(context).textTheme.titleMedium),
          ),
          for (final workspace in workspaces)
            ListTile(
              leading: Icon(workspace.kind == 'personal' ? Icons.person : Icons.storefront),
              title: Text(workspaceLabel(context, workspace)),
              subtitle: Text(workspace.isDemo
                  ? l10n.demo
                  : (workspace.kind == 'personal' ? l10n.personal : l10n.business)),
              trailing: workspace.id == current.id ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary) : null,
              onTap: () {
                ref.read(currentWorkspaceIdProvider.notifier).select(workspace.id);
                onSwitched();
                Navigator.pop(context);
              },
            ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.add_business_outlined),
            title: Text(l10n.newBusiness),
            onTap: () async {
              final name = await promptText(context, title: l10n.newBusiness, label: l10n.businessName);
              if (name != null && context.mounted) await create(() => actions.createBusiness(name));
            },
          ),
          if (!workspaces.any((w) => w.isDemo))
            ListTile(
              leading: const Icon(Icons.science_outlined),
              title: Text(l10n.tryDemo),
              subtitle: Text(l10n.tryDemoHint),
              onTap: () => create(actions.createDemo),
            ),
        ],
      ),
    );
  }
}

/// Cloud icon that always tells the truth about whether work is saved online.
class _SyncIndicator extends ConsumerWidget {
  const _SyncIndicator();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(syncControllerProvider);
    final pending = ref.watch(pendingChangesProvider).value ?? 0;
    final failures = ref.watch(syncFailuresProvider).value?.length ?? 0;
    final l10n = context.l10n;

    final (IconData icon, Color? color, String tooltip) = switch ((status, pending, failures)) {
      (_, _, > 0) => (Icons.error_outline, AppTheme.errorColor, l10n.notSynced),
      (SyncStatus(syncing: true), _, _) => (Icons.cloud_sync_outlined, null, l10n.syncing),
      (SyncStatus(offline: true), _, _) => (Icons.cloud_off_outlined, AppTheme.warningColor, l10n.offlineStatus),
      (SyncStatus(error: final String message), _, _) => (
          Icons.cloud_off_outlined,
          AppTheme.errorColor,
          l10n.syncError(message),
        ),
      (_, > 0, _) => (Icons.cloud_upload_outlined, AppTheme.warningColor, l10n.pendingChanges(pending)),
      _ => (Icons.cloud_done_outlined, AppTheme.successColor, l10n.allSynced),
    };
    return IconButton(
      tooltip: tooltip,
      icon: Badge(isLabelVisible: pending > 0, label: Text('$pending'), child: Icon(icon, color: color)),
      onPressed: () {
        ref.read(syncControllerProvider.notifier).syncNow();
        context.showMessage(tooltip);
      },
    );
  }
}
