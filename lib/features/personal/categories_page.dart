import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/database.dart';
import '../../core/entitlements/entitlements.dart';
import '../../core/entitlements/entitlements_controller.dart';
import '../../core/providers.dart';
import '../../core/ui.dart';
import '../plan/plan_repository.dart';
import '../plan/plan_text.dart';
import '../plan/upgrade_sheet.dart';
import 'ledger_repository.dart';

/// Expense and income categories of the personal workspace: add, rename, delete.
class CategoriesPage extends ConsumerWidget {
  const CategoriesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final workspace = ref.watch(currentWorkspaceProvider);
    if (workspace == null) return Scaffold(appBar: AppBar(title: Text(l10n.categories)));

    return DefaultTabController(
      length: 2,
      child: Builder(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text(l10n.categories),
            bottom: TabBar(tabs: [Tab(text: l10n.expense), Tab(text: l10n.income)]),
          ),
          body: AsyncView(
            value: ref.watch(categoriesProvider(workspace.id)),
            builder: (categories) => TabBarView(
              children: [
                for (final kind in const ['expense', 'income'])
                  _CategoryList(
                    categories: categories.where((c) => c.kind == kind).toList(),
                    kind: kind,
                    workspace: workspace,
                  ),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            icon: const Icon(Icons.add_rounded),
            label: Text(l10n.newCategory),
            onPressed: () async {
              final kind = DefaultTabController.of(context).index == 0 ? 'expense' : 'income';
              final name = await promptText(context, title: l10n.newCategory, label: l10n.categoryName);
              if (name == null || !context.mounted) return;
              final added = await guarded(
                context,
                () => ref.read(ledgerRepositoryProvider).addCategory(workspace.id, name, kind),
              );
              if (added && context.mounted) showEventBurst(context, AppEvent.saved);
            },
          ),
        ),
      ),
    );
  }
}

class _CategoryList extends ConsumerWidget {
  const _CategoryList({required this.categories, required this.kind, required this.workspace});

  final List<Category> categories;
  final String kind;
  final Workspace workspace;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final repo = ref.read(ledgerRepositoryProvider);
    if (categories.isEmpty) return EmptyState(icon: Icons.sell_outlined, message: l10n.noCategories);
    final tint = context.amountColor(kind == 'income');
    final text = Theme.of(context).textTheme;
    final plan = ref.watch(entitlementsProvider).value;
    // Shown only where the plan limits them, and only to the person whose plan it is
    final own = workspace.role == 'owner'
        ? ref.watch(limitUseProvider((F.customCategories, workspace.id))).value
        : null;
    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpace.page, AppSpace.lg, AppSpace.page, 96),
      children: [
        if (own != null && own.limited)
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, AppSpace.sm),
            child: Text(l10n.customCount(own.count, own.limit!), style: text.bodySmall),
          ),
        Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (final (index, category) in categories.indexed) ...[
                if (index > 0) const Divider(indent: 68),
                ListTile(
                  leading: IconBadge(Icons.sell_outlined, color: tint, size: 36),
                  title: Text(category.name),
                  // The ones every account starts with are free; a quiet tag tells them apart
                  subtitle: category.isDefault
                      ? Text(l10n.defaultTag, style: text.labelSmall?.copyWith(color: context.colors.muted))
                      : (plan?.isLocked(category.id) ?? false)
                          ? const Align(alignment: Alignment.centerLeft, child: LockedTag())
                          : null,
                  onTap: () async {
                    final name = await promptText(context,
                        title: l10n.renameCategory, label: l10n.categoryName, initial: category.name);
                    if (name != null && context.mounted) {
                      await guarded(context, () => repo.renameCategory(category, name));
                    }
                  },
                  trailing: IconButton(
                    tooltip: l10n.delete,
                    icon: const Icon(Icons.delete_outline_rounded),
                    onPressed: () async {
                      final count = await repo.transactionCount(category.id);
                      if (!context.mounted) return;
                      if (await confirm(context, l10n.deleteCategoryConfirm(category.name, count))) {
                        await repo.deleteCategory(category);
                        if (context.mounted) showEventBurst(context, AppEvent.deleted);
                      }
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
