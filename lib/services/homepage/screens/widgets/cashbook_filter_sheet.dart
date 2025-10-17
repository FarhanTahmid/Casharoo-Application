import 'package:flutter/material.dart';
import 'package:casharoo/services/homepage/models/cashbook.dart';

class CashbookFilterSheet extends StatelessWidget {
  final CashbookSort selected;
  const CashbookFilterSheet({super.key, required this.selected});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Sort Books By', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            ...CashbookSort.values.map((s) => _tile(context, s)).toList(),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _tile(BuildContext ctx, CashbookSort s) {
    String label = switch (s) {
      CashbookSort.lastUpdated => 'Last Updated',
      CashbookSort.nameAZ => 'Name (A to Z)',
      CashbookSort.netHighToLow => 'Net Balance (High to Low)',
      CashbookSort.netLowToHigh => 'Net Balance (Low to High)',
      CashbookSort.lastCreated => 'Last Created',
    };
    return RadioListTile<CashbookSort>(
      value: s,
      groupValue: selected,
      onChanged: (v) => Navigator.of(ctx).pop(v),
      title: Text(label),
    );
  }
}
