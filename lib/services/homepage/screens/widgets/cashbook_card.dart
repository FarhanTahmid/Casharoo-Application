import 'package:flutter/material.dart';
import 'package:casharoo/services/homepage/models/cashbook.dart';

class CashbookCard extends StatelessWidget {
  final Cashbook cashbook;
  final VoidCallback? onRename;
  final VoidCallback? onMove;
  final Future<void> Function()? onDelete;

  const CashbookCard({
    super.key,
    required this.cashbook,
    this.onRename,
    this.onMove,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final balColor = cashbook.netBalance >= 0 ? cs.secondary : cs.error;

    return Material(
      color: cs.surface,
      borderRadius: BorderRadius.circular(12),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {/* TODO: open details */},
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                  color: cs.primary.withOpacity(.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.bookmark_rounded, color: cs.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(cashbook.name, style: t.titleLarge),
                    const SizedBox(height: 4),
                    Text(cashbook.friendlyUpdated, style: t.bodyMedium),
                  ],
                ),
              ),
              Text(
                _formatMoney(cashbook.netBalance),
                style: t.titleLarge!.copyWith(color: balColor, fontWeight: FontWeight.w700),
              ),
              const SizedBox(width: 8),
              PopupMenuButton<String>(
                onSelected: (v) async {
                  switch (v) {
                    case 'rename': onRename?.call(); break;
                    case 'move': onMove?.call(); break;
                    case 'delete': await onDelete?.call(); break;
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'rename', child: ListTile(
                    leading: Icon(Icons.edit_rounded), title: Text('Rename'), dense: true)),
                  PopupMenuItem(value: 'move', child: ListTile(
                    leading: Icon(Icons.drive_file_move_rounded), title: Text('Move book'), dense: true)),
                  PopupMenuItem(value: 'delete', child: ListTile(
                    leading: Icon(Icons.delete_rounded), title: Text('Delete Book'), dense: true)),
                ],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatMoney(double v) {
    // Very simple format for demo (1,04,247 etc can be localized later)
    final sign = v < 0 ? '-' : '';
    final n = v.abs().toStringAsFixed(0);
    return '$sign${_comma(n)}';
  }

  String _comma(String s) {
    // 35,000 style
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final pos = s.length - i;
      buf.write(s[i]);
      if (pos > 1 && pos % 3 == 1) buf.write(',');
    }
    return buf.toString();
  }
}
