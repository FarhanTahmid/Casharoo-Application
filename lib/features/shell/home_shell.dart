import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_client.dart';
import '../../core/db/database.dart';
import '../../core/db/local_store.dart';
import '../../core/entitlements/entitlements.dart';
import '../../core/entitlements/entitlements_controller.dart';
import '../../core/providers.dart';
import '../../core/ui.dart';
import '../cashbook/cashbook_pages.dart';
import '../personal/budget_calendar_page.dart';
import '../personal/personal_pages.dart';
import '../plan/offer_banner.dart';
import '../plan/plan_text.dart';
import '../plan/upgrade_sheet.dart';

/// Creating and deleting workspaces happens on the server, so these need a connection.
class WorkspaceActions {
  WorkspaceActions(this.ref);

  final Ref ref;

  /// Returns the new workspace id, or null when offline or refused. Pass the
  /// same [id] when retrying: the server then returns the business it already made.
  /// It starts in the currency of the workspace the user is in.
  /// Throws a PlanLimitException when the plan allows no more businesses.
  Future<String?> createBusiness(String name, {String? id}) async {
    await ref.read(planGuardProvider).roomFor(F.businessWorkspaces, '');
    return _create(() => ref.read(apiClientProvider).post(
          '/api/v1/workspaces/',
          {
            'id': id ?? newId(),
            'name': name,
            'default_currency': ?ref.read(currentWorkspaceProvider)?.defaultCurrency,
          },
        ));
  }

  /// The currency new accounts, cashbooks and budgets start in, and totals are
  /// shown in. What already exists keeps its own. False when offline or refused.
  Future<bool> setDefaultCurrency(String workspaceId, String currency) async {
    try {
      final response = await ref
          .read(apiClientProvider)
          .patch('/api/v1/workspaces/$workspaceId/', {'default_currency': currency});
      if (!response.ok) return false;
      await ref.read(syncControllerProvider.notifier).syncNow();
      return true;
    } on OfflineException {
      return false;
    }
  }

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
      // The server's own "not on your plan": the phone's copy of the plan was behind
      if (response.statusCode == 402 && response.body is Map) {
        ref.read(entitlementsProvider.notifier).refresh();
        throw PlanLimitException.fromJson(response.body as Map);
      }
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
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    // Back in the app: a plan may have been bought, ended or changed meanwhile
    _lifecycle = AppLifecycleListener(onResume: () => ref.read(entitlementsProvider.notifier).refresh());
    // Also for a plan that was already known when this screen opened
    ref.listenManual(entitlementsProvider, fireImmediately: true, (_, next) {
      final plan = next.value;
      if (plan != null) _promptToKeep(plan);
    });
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  /// A sync undid a change the plan does not allow: say why, once. The notice
  /// stays until the sheet is closed, so further refusals from the same sync
  /// do not stack more sheets on top.
  Future<void> _showRefusal(PlanLimitException refusal) async {
    await showUpgradeSheet(context, refusal: refusal);
    if (mounted) ref.read(planLimitNoticeProvider.notifier).clear();
  }

  /// A downgrade left the user over a limit: open the choice by itself the
  /// first time. After that it waits on the Plan screen.
  Future<void> _promptToKeep(Entitlements plan) async {
    final pending = [
      for (final lock in plan.locks)
        if (lock.pending) '${lock.feature}|${lock.scope}|${lock.limit}',
    ].join(',');
    if (pending.isEmpty) return;
    final db = ref.read(databaseProvider);
    if (await db.getSetting(keepPromptedSettingKey) == pending) return;
    await db.setSetting(keepPromptedSettingKey, pending);
    if (mounted) context.push('/plan/keep');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final workspace = ref.watch(currentWorkspaceProvider);
    ref.listen(planLimitNoticeProvider, (_, refusal) {
      if (refusal != null) _showRefusal(refusal);
    });
    if (workspace == null) {
      // First launch after login: the first sync has not finished yet
      final status = ref.watch(syncControllerProvider);
      final failed = status.offline || status.error != null;
      return Scaffold(
        backgroundColor: colors.header,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const BrandLogo(layout: BrandLayout.stacked, onDark: true, height: 190),
                const SizedBox(height: 28),
                if (failed) ...[
                  Text(
                    status.offline ? l10n.offlineError : l10n.syncError(status.error!),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: colors.onHeader),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: colors.gold, foregroundColor: colors.onGold),
                    onPressed: ref.read(syncControllerProvider.notifier).syncNow,
                    child: Text(l10n.syncNow),
                  ),
                ] else
                  AppLoader(color: colors.mint),
              ],
            ),
          ),
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
      appBar: headerAppBar(
        context,
        title: _WorkspaceSwitcher(current: workspace, onSwitched: () => setState(() => _tab = 0)),
        actions: [
          const _SyncIndicator(),
          IconButton(
            tooltip: l10n.settings,
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          const OfferBanner(),
          Expanded(
            // One page leaves as the next arrives: fade through, with a slight rise
            child: AnimatedSwitcher(
              duration: context.motion(AppMotion.emphasised),
              switchInCurve: AppMotion.ease,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: ScaleTransition(scale: Tween(begin: 0.97, end: 1.0).animate(animation), child: child),
              ),
              child: KeyedSubtree(key: ValueKey('${workspace.id}-$tab'), child: pages[tab]),
            ),
          ),
        ],
      ),
      bottomNavigationBar: personal
          ? _BottomBar(
              selected: tab,
              onSelected: (index) => setState(() => _tab = index),
              onAdd: () => openTransactionForm(context, workspace),
              destinations: [
                (Icons.home_outlined, Icons.home_rounded, l10n.overview),
                (Icons.receipt_long_outlined, Icons.receipt_long_rounded, l10n.transactions),
                (Icons.savings_outlined, Icons.savings_rounded, l10n.budgets),
                (Icons.account_balance_wallet_outlined, Icons.account_balance_wallet_rounded, l10n.accounts),
              ],
            )
          : null,
    );
  }
}

/// Four places to go, and in the middle the gold button that adds a
/// transaction: the thing people open the app to do, under the thumb on every tab.
class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.selected, required this.onSelected, required this.onAdd, required this.destinations});

  final int selected;
  final ValueChanged<int> onSelected;
  final VoidCallback onAdd;

  /// Icon, icon when selected, label.
  final List<(IconData, IconData, String)> destinations;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final scheme = Theme.of(context).colorScheme;

    Widget item(int index) {
      final (icon, activeIcon, label) = destinations[index];
      final active = index == selected;
      return Expanded(
        child: Semantics(
          button: true,
          selected: active,
          child: InkResponse(
            radius: 40,
            onTap: () {
              if (!active) HapticFeedback.selectionClick();
              onSelected(index);
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedContainer(
                  duration: context.motion(AppMotion.emphasised),
                  curve: AppMotion.spring,
                  width: active ? 56 : 36,
                  height: 30,
                  decoration: BoxDecoration(
                    color: active ? scheme.primaryContainer : scheme.primaryContainer.withValues(alpha: 0),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: PopSwitcher(
                    child: Icon(
                      active ? activeIcon : icon,
                      key: ValueKey(active),
                      size: 22,
                      color: active ? scheme.primary : colors.muted,
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: AnimatedDefaultTextStyle(
                      duration: context.motion(AppMotion.standard),
                      style: Theme.of(context).textTheme.labelSmall!.copyWith(
                            color: active ? scheme.primary : colors.muted,
                            fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                          ),
                      child: Text(label, maxLines: 1),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.sheet,
        boxShadow: [BoxShadow(color: colors.shadow, blurRadius: 24, offset: const Offset(0, -6))],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 72,
            child: Row(
              children: [
                item(0),
                item(1),
                SizedBox(
                  width: 80,
                  child: Center(child: AddButton(onPressed: onAdd, tooltip: context.l10n.addTransaction)),
                ),
                item(2),
                item(3),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String workspaceLabel(BuildContext context, Workspace workspace) =>
    workspace.kind == 'personal' ? context.l10n.personal : workspace.name;

IconData _workspaceIcon(Workspace workspace) =>
    workspace.kind == 'personal' ? Icons.person_rounded : Icons.storefront_rounded;

class _WorkspaceSwitcher extends ConsumerWidget {
  const _WorkspaceSwitcher({required this.current, required this.onSwitched});

  final Workspace current;
  final VoidCallback onSwitched;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    return Pressable(
      onTap: () => showAppSheet<void>(
        context,
        title: context.l10n.switchWorkspace,
        builder: (_) => _WorkspaceSheet(current: current, onSwitched: onSwitched),
      ),
      child: Semantics(
        button: true,
        hint: context.l10n.switchWorkspace,
        child: Container(
          padding: const EdgeInsets.fromLTRB(6, 6, 8, 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: colors.onHeader,
                child: Icon(_workspaceIcon(current), size: 18, color: colors.header),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  workspaceLabel(context, current),
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(color: colors.onHeader),
                ),
              ),
              Icon(Icons.expand_more_rounded, color: colors.onHeaderMuted),
            ],
          ),
        ),
      ),
    );
  }
}

class _WorkspaceSheet extends ConsumerWidget {
  const _WorkspaceSheet({required this.current, required this.onSwitched});

  final Workspace current;
  final VoidCallback onSwitched;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final workspaces = ref.watch(workspacesProvider).value ?? const <Workspace>[];
    final actions = ref.read(workspaceActionsProvider);
    final plan = ref.watch(entitlementsProvider).value;

    Future<void> create(Future<String?> Function() action) async {
      // The screen under this sheet, which is still there once the sheet has closed
      final host = Navigator.of(context).context;
      Navigator.pop(context);
      final messenger = ScaffoldMessenger.of(context);
      final failed = l10n.needsConnection;
      try {
        if (await action() == null) {
          messenger.showSnackBar(SnackBar(content: Text(failed)));
        } else {
          onSwitched();
        }
      } on PlanLimitException catch (refusal) {
        if (host.mounted) await showUpgradeSheet(host, refusal: refusal);
      }
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final workspace in workspaces)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: IconBadge(_workspaceIcon(workspace)),
            title: Text(workspaceLabel(context, workspace)),
            subtitle: Text(workspace.isDemo ? l10n.demo : (workspace.kind == 'personal' ? l10n.personal : l10n.business)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (plan?.isLocked(workspace.id) ?? false) const LockedTag(),
                if (workspace.id == current.id) ...[
                  const SizedBox(width: 8),
                  Icon(Icons.check_circle_rounded, color: scheme.primary),
                ],
              ],
            ),
            onTap: () {
              ref.read(currentWorkspaceIdProvider.notifier).select(workspace.id);
              onSwitched();
              Navigator.pop(context);
            },
          ),
        const Divider(height: 24),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: IconBadge(Icons.add_business_outlined, color: context.colors.muted),
          title: Text(l10n.newBusiness),
          onTap: () async {
            final name = await promptText(context, title: l10n.newBusiness, label: l10n.businessName);
            if (name != null && context.mounted) await create(() => actions.createBusiness(name));
          },
        ),
        if (!workspaces.any((w) => w.isDemo))
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: IconBadge(Icons.science_outlined, color: context.colors.muted),
            title: Text(l10n.tryDemo),
            subtitle: Text(l10n.tryDemoHint),
            onTap: () => create(actions.createDemo),
          ),
      ],
    );
  }
}

/// Cloud icon that always tells the truth about whether work is saved online.
/// It turns while syncing and pops when the state changes.
class _SyncIndicator extends ConsumerWidget {
  const _SyncIndicator();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(syncControllerProvider);
    final pending = ref.watch(pendingChangesProvider).value ?? 0;
    final failures = ref.watch(syncFailuresProvider).value?.length ?? 0;
    final l10n = context.l10n;
    final colors = context.colors;
    // Light enough to read on the navy header
    const problem = Color(0xFFFF9AA2);

    final (IconData icon, Color color, String tooltip) = switch ((status, pending, failures)) {
      (_, _, > 0) => (Icons.error_outline_rounded, problem, l10n.notSynced),
      (SyncStatus(syncing: true), _, _) => (Icons.sync_rounded, colors.onHeader, l10n.syncing),
      (SyncStatus(offline: true), _, _) => (Icons.cloud_off_outlined, colors.gold, l10n.offlineStatus),
      (SyncStatus(error: final String message), _, _) => (Icons.cloud_off_outlined, problem, l10n.syncError(message)),
      (_, > 0, _) => (Icons.cloud_upload_outlined, colors.gold, l10n.pendingChanges(pending)),
      _ => (Icons.cloud_done_outlined, colors.mint, l10n.allSynced),
    };
    return IconButton(
      tooltip: tooltip,
      icon: Badge(
        isLabelVisible: pending > 0,
        backgroundColor: colors.gold,
        textColor: colors.onGold,
        label: Text('$pending'),
        child: SpinWhile(
          active: status.syncing,
          child: PopSwitcher(child: Icon(icon, key: ValueKey(icon), color: color)),
        ),
      ),
      onPressed: () {
        ref.read(syncControllerProvider.notifier).syncNow();
        context.showMessage(tooltip);
      },
    );
  }
}
