import 'package:flutter/material.dart';
import 'package:casharoo/services/cashbook_operations/data/entry.dart';

class EntryListItem extends StatelessWidget {
  final Entry entry;
  final bool selected;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const EntryListItem({
    super.key,
    required this.entry,
    this.selected = false,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final amtColor = entry.type == EntryType.cashIn ? cs.secondary : cs.error;

    return Material(
      color: cs.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        onLongPress: onLongPress,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? cs.primary : Theme.of(context).dividerColor.withOpacity(.2),
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8, runSpacing: 6,
                children: [
                  _chip(entry.categoryName),
                  _chip(entry.paymentModeName),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(entry.remark ?? '—', style: t.titleMedium),
                  ),
                  Text(_money(entry.amount),
                      style: t.titleLarge?.copyWith(color: amtColor, fontWeight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text('Entry by ${entry.createdBy ?? 'You'}',
                      style: t.bodySmall?.copyWith(color: t.bodySmall?.color?.withOpacity(.9))),
                  const Spacer(),
                  Text('Balance: ${_money(entry.runningBalance)}', style: t.bodySmall),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white24),
        ),
        child: Text(text),
      );

  String _money(double v) {
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
