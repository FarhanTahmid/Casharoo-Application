import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/database.dart';
import '../../core/providers.dart';
import '../../core/ui.dart';
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
                  _CategoryList(categories: categories.where((c) => c.kind == kind).toList()),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            icon: const Icon(Icons.add),
            label: Text(l10n.newCategory),
            onPressed: () async {
              final kind = DefaultTabController.of(context).index == 0 ? 'expense' : 'income';
              final name = await promptText(context, title: l10n.newCategory, label: l10n.categoryName);
              if (name != null) await ref.read(ledgerRepositoryProvider).addCategory(workspace.id, name, kind);
            },
          ),
        ),
      ),
    );
  }
}

class _CategoryList extends ConsumerWidget {
  const _CategoryList({required this.categories});

  final List<Category> categories;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final repo = ref.read(ledgerRepositoryProvider);
    if (categories.isEmpty) return EmptyState(icon: Icons.category_outlined, message: l10n.noCategories);
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 96),
      itemCount: categories.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final category = categories[index];
        return ListTile(
          title: Text(category.name),
          onTap: () async {
            final name = await promptText(context,
                title: l10n.renameCategory, label: l10n.categoryName, initial: category.name);
            if (name != null) await repo.renameCategory(category, name);
          },
          trailing: IconButton(
            tooltip: l10n.delete,
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              final count = await repo.transactionCount(category.id);
              if (!context.mounted) return;
              if (await confirm(context, l10n.deleteCategoryConfirm(category.name, count))) {
                await repo.deleteCategory(category);
              }
            },
          ),
        );
      },
    );
  }
}
