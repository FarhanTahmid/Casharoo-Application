import 'package:flutter/material.dart';
import 'package:casharoo/services/cashbook_operations/models/api_repository.dart';
import 'package:casharoo/services/cashbook_operations/models/filters.dart';

class ReportsPage extends StatefulWidget {
  final String cashbookId;
  final EntryRepository repo;
  const ReportsPage({super.key, required this.cashbookId, required this.repo});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  EntryFilters filters = EntryFilters();
  int _reportType = 0; // 0: All entries, 1: day-wise, 2: contact, 3: category

  Future<void> _pickDateFilter() async {
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 3),
      lastDate: DateTime(now.year + 3),
      initialDateRange: filters.dateRange,
    );
    if (range != null) setState(() => filters = filters.copyWith(dateRange: range));
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Generate Report'),
        actions: [
          IconButton(onPressed: () {/* settings */}, icon: const Icon(Icons.settings_rounded)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          _banner(context),

          const SizedBox(height: 8),
          Text('Report will be generated for', style: t.titleMedium),
          const SizedBox(height: 12),
          _grid(context),

          const SizedBox(height: 18),
          Text('Select Report Type', style: t.titleMedium),
          const SizedBox(height: 8),
          _radio('All Entries Report', 0),
          _radio('Day-wise summary', 1, subtitle: 'Day-wise total in, out & balance'),
          _radio('Contact-wise summary', 2, subtitle: 'Contact-wise totals'),
          _radio('Category-wise summary', 3, subtitle: 'Income & expenses by category'),

          const SizedBox(height: 18),
          OutlinedButton.icon(
            onPressed: () {/* TODO: excel generate */},
            icon: const Icon(Icons.grid_on_rounded),
            label: const Text('GENERATE EXCEL'),
          ),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: () {/* TODO: pdf generate */},
            icon: const Icon(Icons.picture_as_pdf_rounded),
            label: const Text('GENERATE PDF'),
          ),
        ],
      ),
    );
  }

  Widget _banner(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.group_rounded, color: cs.primary),
          const SizedBox(width: 12),
          const Expanded(child: Text('Share books with multiple members\nTap here to know more')),
          IconButton(onPressed: () {/* close? */}, icon: const Icon(Icons.close_rounded)),
        ],
      ),
    );
  }

  Widget _grid(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Wrap(
      spacing: 12, runSpacing: 12,
      children: [
        _kv('Duration', filters.dateRange == null ? 'All Time' : 'Custom',
            trailing: TextButton(onPressed: _pickDateFilter, child: const Text('Change'))),
        _kv('Entry Type', 'All'),
        _kv('Category', 'All'),
        _kv('Payment Mode', 'All'),
        _kv('Search Term', (filters.search?.isEmpty ?? true) ? 'None' : filters.search!),
      ],
    );
  }

  Widget _kv(String k, String v, {Widget? trailing}) {
    return Container(
      width: 260,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(.2)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(k, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 4),
            Text(v, style: Theme.of(context).textTheme.titleMedium),
          ])),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _radio(String label, int value, {String? subtitle}) {
    return RadioListTile<int>(
      value: value, groupValue: _reportType,
      title: Text(label),
      subtitle: subtitle == null ? null : Text(subtitle),
      onChanged: (v) => setState(() => _reportType = v!),
    );
  }
}
