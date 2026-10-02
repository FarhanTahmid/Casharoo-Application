import 'package:flutter/material.dart';
import 'package:casharoo/services/homepage/utils/utils.dart';
import 'package:casharoo/services/homepage/models/cashbook.dart';
import 'package:casharoo/api_exception.dart';

class CashbookCard extends StatelessWidget {
  // Data
  final Cashbook cashbook;

  // Single-item actions (handled by the page after API completes here)
  final Future<void> Function()? onDelete; // page can silently reload & toast
  final Future<void> Function()? onRename; // page can silently reload & toast
  final VoidCallback? onMove;              // optional hook for future

  // Selection support (controlled by the page)
  final bool selectionMode;      // true when bulk-select mode is ON
  final bool selected;           // true when this card is selected
  final VoidCallback? onCardTap; // in selection: toggle; otherwise: navigate
  final VoidCallback? onCardLongPress;

  // Local helper that matches your app style (AuthService, BackendConfig, etc.)
  final CashbookUtils _utils = CashbookUtils();

  CashbookCard({
    super.key,
    required this.cashbook,
    this.onDelete,
    this.onRename,
    this.onMove,
    this.selectionMode = false,
    this.selected = false,
    this.onCardTap,
    this.onCardLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t  = Theme.of(context).textTheme;
    final balColor = cashbook.netBalance >= 0 ? cs.secondary : cs.error;

    final borderColor = selected
        ? cs.primary
        : Theme.of(context).dividerColor.withOpacity(.35);

    final content = Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: selected ? 1.4 : 1),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Stack(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _leadingIcon(cs),
              const SizedBox(width: 12),

              // Title + subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _oneLine(cashbook.name, style: t.titleLarge),
                    const SizedBox(height: 4),
                    _oneLine(cashbook.friendlyUpdated, style: t.bodyMedium),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Balance
              Text(
                _formatMoney(cashbook.netBalance),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: t.titleLarge!.copyWith(
                  color: balColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 4),

              // Three-dots menu: disabled while in selection mode
              IgnorePointer(
                ignoring: selectionMode,
                child: PopupMenuButton<String>(
                  onSelected: (v) async {
                    switch (v) {
                      case 'rename':
                        await _handleRename(context);
                        break;
                      case 'move':
                        onMove?.call();
                        break;
                      case 'delete':
                        await _handleDelete(context);
                        break;
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: 'rename',
                      child: ListTile(
                        leading: Icon(Icons.edit_rounded),
                        title: Text('Rename'),
                        dense: true,
                      ),
                    ),
                    PopupMenuItem(
                      value: 'move',
                      child: ListTile(
                        leading: Icon(Icons.drive_file_move_rounded),
                        title: Text('Move book'),
                        dense: true,
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: ListTile(
                        leading: Icon(Icons.delete_rounded),
                        title: Text('Delete Book'),
                        dense: true,
                      ),
                    ),
                  ],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),

          // Selection tick (top-left)
          if (selectionMode)
            Positioned(
              top: 2,
              left: 2,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: selected ? cs.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected ? cs.primary : borderColor,
                    width: selected ? 0 : 1.2,
                  ),
                ),
                child: selected
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : null,
              ),
            ),
        ],
      ),
    );

    // IMPORTANT: single InkWell wrapping the whole visual card
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onCardTap,              // page decides: toggle or navigate
        onLongPress: onCardLongPress,  // page decides: start selection/toggle
        child: content,
      ),
    );
  }

  // ---------------- Actions ----------------

  Future<void> _handleRename(BuildContext context) async {
    final ctrl = TextEditingController(text: cashbook.name);

    final newName = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename cashbook'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(
            labelText: 'Cashbook name',
          ),
          onSubmitted: (_) => Navigator.of(ctx).pop(ctrl.text.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(ctrl.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (newName == null) return;
    final trimmed = newName.trim();
    if (trimmed.isEmpty || trimmed == cashbook.name) return;

    try {
      // Call your API here (per your request)
      await _utils.updateCashbook(cashbook, trimmed, null);
      // Let the page decide UI feedback + reload
      await onRename?.call();
    } on ApiException catch (e) {
      _toast(context, e.message, error: true);
    } catch (e) {
      _toast(context, 'Failed to rename cashbook.', error: true);
    }
  }

  Future<void> _handleDelete(BuildContext context) async {
    final ok = await _confirmDelete(context, cashbook.name);
    if (ok != true) return;

    try {
      await _utils.deleteCashbook(cashbook.id);
      await onDelete?.call(); // page: toast + silent reload
    } on ApiException catch (e) {
      _toast(context, e.message, error: true);
    } catch (e) {
      _toast(context, 'Failed to delete cashbook.', error: true);
    }
  }

  // ---------------- UI helpers ----------------

  Widget _leadingIcon(ColorScheme cs) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: cs.primary.withOpacity(.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(Icons.bookmark_rounded, color: cs.primary),
    );
  }

  Widget _oneLine(String text, {TextStyle? style}) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: style,
    );
  }

  Future<bool?> _confirmDelete(BuildContext context, String name) {
    final cs = Theme.of(context).colorScheme;
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Cashbook?'),
        content: Text('Are you sure you want to delete "$name"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('No'),
          ),
          FilledButton.icon(
            icon: const Icon(Icons.check_rounded),
            style: FilledButton.styleFrom(
              backgroundColor: cs.error,
              foregroundColor: cs.onError,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            label: const Text('Yes'),
          ),
        ],
      ),
    );
  }

  void _toast(BuildContext context, String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? Theme.of(context).colorScheme.error : null,
      ),
    );
  }

  // ---------------- Formatting ----------------

  String _formatMoney(double v) {
    final sign = v < 0 ? '-' : '';
    final n = v.abs().toStringAsFixed(0);
    return '$sign${_comma(n)}';
  }

  String _comma(String s) {
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final pos = s.length - i;
      buf.write(s[i]);
      if (pos > 1 && pos % 3 == 1) buf.write(',');
    }
    return buf.toString();
  }
}
