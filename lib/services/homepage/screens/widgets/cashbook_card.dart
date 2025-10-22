import 'package:flutter/material.dart';
import 'package:casharoo/services/homepage/utils/utils.dart';
import 'package:casharoo/services/homepage/models/cashbook.dart';

class CashbookCard extends StatelessWidget {
  // Data
  final Cashbook cashbook;

  // Single-item actions (provided by the page)
  // onRename/onDelete are optional hooks to let the page silently reload after API success
  final VoidCallback? onRename;
  final VoidCallback? onMove;
  final Future<void> Function()? onDelete;

  // Selection support (controlled by the page)
  final bool selectionMode;          // true when bulk-select mode is ON
  final bool selected;               // true when this card is selected
  final VoidCallback? onCardTap;     // tap behavior (toggle selection in selection mode)
  final VoidCallback? onCardLongPress;

  // Local helper (API utils)
  final CashbookUtils cashbookUtils = CashbookUtils();

  CashbookCard({
    super.key,
    required this.cashbook,
    this.onRename,
    this.onMove,
    this.onDelete,
    this.selectionMode = false,
    this.selected = false,
    this.onCardTap,
    this.onCardLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final balColor = cashbook.netBalance >= 0 ? cs.secondary : cs.error;

    return Material(
      color: _cardBg(cs),
      borderRadius: BorderRadius.circular(12),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onCardTap ?? () {/* TODO: open details */},
        onLongPress: onCardLongPress,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? cs.primary : _dividerColor(context),
              width: selected ? 1.4 : 1,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Stack(
            children: [
              // Main row content
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
                        _singleLineText(
                          cashbook.name,
                          style: t.titleLarge,
                        ),
                        const SizedBox(height: 4),
                        _singleLineText(
                          cashbook.friendlyUpdated,
                          style: t.bodyMedium,
                        ),
                      ],
                    ),
                  ),

                  // Balance
                  Text(
                    _formatMoney(cashbook.netBalance),
                    style: t.titleLarge!.copyWith(
                      color: balColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Menu (disabled during selection mode)
                  PopupMenuButton<String>(
                    enabled: !selectionMode,
                    onSelected: (v) async {
                      switch (v) {
                        case 'rename':
                          await _renameFlow(context);
                          break;
                        case 'move':
                          onMove?.call();
                          break;
                        case 'delete':
                          final confirmed =
                              await _confirmDelete(context, cashbook.name);
                          if (confirmed == true) {
                            try {
                              await cashbookUtils.deleteCashbook(cashbook.id); // API call
                              await onDelete?.call(); // page-level silent refresh
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Delete failed: $e')),
                                );
                              }
                            }
                          }
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
                ],
              ),

              // Selection badge (top-left)
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
                        color: selected ? cs.primary : _dividerColor(context),
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
        ),
      ),
    );
  }

  // ---------- Rename Flow ----------

  Future<void> _renameFlow(BuildContext context) async {
    final newName = await _showRenameDialog(context, initial: cashbook.name);
    if (newName == null) return; // user cancelled

    try {
      // Call API to rename
      await cashbookUtils.updateCashbook(cashbook, newName.trim());
      // Let the page refresh silently if it wants
      onRename?.call();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Rename failed: $e')),
        );
      }
    }
  }

  Future<String?> _showRenameDialog(BuildContext context, {required String initial}) {
    final t = Theme.of(context).textTheme;
    final formKey = GlobalKey<FormState>();
    final controller = TextEditingController(text: initial);
    bool submitting = false;

    return showDialog<String?>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return AlertDialog(
              title: const Text('Rename Cashbook'),
              content: Form(
                key: formKey,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: TextFormField(
                    controller: controller,
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: 'Cashbook name',
                      hintText: 'Enter new name',
                    ),
                    style: t.titleMedium,
                    validator: (v) {
                      final val = v?.trim() ?? '';
                      if (val.isEmpty) return 'Name is required';
                      if (val.length < 2) return 'Too short';
                      return null;
                    },
                    onFieldSubmitted: (_) async {
                      if (!formKey.currentState!.validate()) return;
                      setState(() => submitting = true);
                      // We don’t call API here; we return the text and let _renameFlow do it.
                      Navigator.of(ctx).pop(controller.text);
                    },
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: submitting ? null : () => Navigator.of(ctx).pop(null),
                  child: const Text('Cancel'),
                ),
                FilledButton.icon(
                  icon: const Icon(Icons.save_rounded),
                  onPressed: submitting
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;
                          setState(() => submitting = true);
                          Navigator.of(ctx).pop(controller.text);
                        },
                  label: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ---------- UI helpers ----------

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

  Widget _singleLineText(String text, {TextStyle? style}) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: style,
    );
  }

  Color _cardBg(ColorScheme cs) {
    // Slight tint when selected to align visuals
    if (selected) {
      return cs.surface.withOpacity(
        ThemeData.estimateBrightnessForColor(cs.surface) == Brightness.dark
            ? 0.9
            : 1.0,
      );
    }
    return cs.surface;
  }

  Color _dividerColor(BuildContext context) {
    return Theme.of(context).dividerColor.withOpacity(.35);
  }

  // ---------- Delete Dialog ----------

  Future<bool?> _confirmDelete(BuildContext context, String name) {
    final cs = Theme.of(context).colorScheme;
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Cashbook?'),
        content: Text(
          'Are you sure you want to delete "$name"? This action cannot be undone.',
        ),
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

  // ---------- Formatting ----------

  String _formatMoney(double v) {
    final sign = v < 0 ? '-' : '';
    final n = v.abs().toStringAsFixed(0);
    return '$sign${_comma(n)}';
  }

  // Simple 1,234,567 style
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
