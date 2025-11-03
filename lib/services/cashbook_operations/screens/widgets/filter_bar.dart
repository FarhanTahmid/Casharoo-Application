// lib/services/homepage/ui/entries/widgets/filter_bar.dart
import 'package:flutter/material.dart';
import 'package:casharoo/services/cashbook_operations/models/filters.dart';
import 'package:casharoo/services/cashbook_operations/data/entry.dart';

class FilterBar extends StatelessWidget {
  final EntryFilters filters;
  final ValueChanged<EntryFilters> onChange;
  final VoidCallback onOpenCategories;
  final VoidCallback onOpenPaymentModes;

  const FilterBar({
    super.key,
    required this.filters,
    required this.onChange,
    required this.onOpenCategories,
    required this.onOpenPaymentModes,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          _segmentedType(context),
          const SizedBox(width: 8),
          _chipButton(context, 'Select Date', Icons.date_range_rounded, () async {
            final now = DateTime.now();
            final picked = await showDateRangePicker(
              context: context,
              firstDate: DateTime(now.year - 3),
              lastDate: DateTime(now.year + 3),
              initialDateRange: filters.dateRange,
            );
            if (picked != null) onChange(filters.copyWith(dateRange: picked));
          }),
          const SizedBox(width: 8),
          _chipButton(context, 'Entry Type', Icons.swap_vert_rounded, () {
            final newType = filters.type == null
                ? EntryType.cashIn
                : (filters.type == EntryType.cashIn ? EntryType.cashOut : null);
            onChange(filters.copyWith(type: newType));
          }),
          const SizedBox(width: 8),
          _chipButton(context, 'Categories', Icons.category_rounded, onOpenCategories),
          const SizedBox(width: 8),
          _chipButton(context, 'Payment', Icons.account_balance_wallet_rounded, onOpenPaymentModes),
        ],
      ),
    );
  }

  Widget _segmentedType(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(.3)),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Icon(Icons.tune_rounded, color: cs.primary),
          const SizedBox(width: 8),
          Text('Filters', style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }

  Widget _chipButton(BuildContext context, String label, IconData icon, VoidCallback onTap) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Icon(icon, size: 18),
              const SizedBox(width: 8),
              Text(label),
              const Icon(Icons.arrow_drop_down_rounded, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
