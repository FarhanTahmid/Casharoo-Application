import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/entitlements/entitlements_controller.dart';
import '../../core/ui.dart';
import 'plan_repository.dart';
import 'plan_text.dart';
import 'upgrade_sheet.dart';

/// After a downgrade the user holds more than the plan allows. Nothing is
/// deleted: here they choose which ones stay editable, and the rest become
/// read-only. The server keeps the choice and checks it; this screen needs a
/// connection.
class KeepPage extends ConsumerWidget {
  const KeepPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final choices = ref.watch(keepChoicesProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.keepTitle)),
      body: switch (choices) {
        AsyncData(value: final List<KeepChoice> found) when found.isEmpty =>
          EmptyState(icon: Icons.lock_open_rounded, message: l10n.keepNothing),
        AsyncData(value: final List<KeepChoice> found) => ListView(
            padding: const EdgeInsets.fromLTRB(AppSpace.page, AppSpace.sm, AppSpace.page, AppSpace.xl),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 4, 4, AppSpace.lg),
                child: Text(l10n.keepIntro, style: Theme.of(context).textTheme.bodyMedium),
              ),
              for (final choice in found)
                _KeepSection(
                  // A saved choice comes back as a new answer: start from it
                  key: ValueKey('${choice.lock.feature}|${choice.lock.scope}|${choice.lock.kept.join(',')}'),
                  choice: choice,
                ),
            ],
          ),
        AsyncData() || AsyncError() => EmptyState(icon: Icons.cloud_off_outlined, message: l10n.keepOffline),
        _ => const Center(child: AppLoader()),
      },
    );
  }
}

class _KeepSection extends ConsumerStatefulWidget {
  const _KeepSection({super.key, required this.choice});

  final KeepChoice choice;

  @override
  ConsumerState<_KeepSection> createState() => _KeepSectionState();
}

class _KeepSectionState extends ConsumerState<_KeepSection> {
  late final Set<String> _chosen = {
    for (final item in widget.choice.items)
      if (item.kept) item.id,
  };
  bool _saving = false;

  Future<void> _save() async {
    final lock = widget.choice.lock;
    setState(() => _saving = true);
    final error = await ref.read(entitlementsProvider.notifier).keep(lock.feature, lock.scope, _chosen.toList());
    if (!mounted) return;
    setState(() => _saving = false);
    if (error == null) showEventBurst(context, AppEvent.saved);
    context.showMessage(error == null ? context.l10n.keepSaved : planErrorText(context.l10n, error));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    final choice = widget.choice;
    final lock = choice.lock;
    final canChange = lock.pending || lock.canChange(DateTime.now());
    final full = _chosen.length >= lock.limit;
    final feature = featureLabel(l10n, lock.feature);

    return SectionCard(
      title: choice.workspaceName.isEmpty ? feature : l10n.keepIn(feature, choice.workspaceName),
      trailing: Text(
        l10n.keepChosen(_chosen.length, lock.limit),
        style: text.bodySmall?.copyWith(fontFeatures: tabularFigures),
      ),
      padding: const EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.lg, AppSpace.lg, AppSpace.md),
      children: [
        for (final item in choice.items)
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            controlAffinity: ListTileControlAffinity.leading,
            title: Text(item.label, style: text.bodyLarge),
            value: _chosen.contains(item.id),
            // At the limit, one has to be let go before another is taken
            onChanged: !canChange || (full && !_chosen.contains(item.id))
                ? null
                : (ticked) => setState(() => ticked! ? _chosen.add(item.id) : _chosen.remove(item.id)),
          ),
        const SizedBox(height: AppSpace.sm),
        Text(
          canChange
              ? (lock.pending ? '${l10n.keepPendingNote} ${l10n.keepOnceNote}' : l10n.keepOnceNote)
              : l10n.keepChangeFrom(planDate(context, lock.canChangeAt!)),
          style: text.bodySmall,
        ),
        if (canChange) ...[
          const SizedBox(height: AppSpace.md),
          SizedBox(
            width: double.infinity,
            child: BusyButton(label: l10n.keepSave, busy: _saving, onPressed: _chosen.isEmpty ? null : _save),
          ),
        ],
      ],
    );
  }
}
