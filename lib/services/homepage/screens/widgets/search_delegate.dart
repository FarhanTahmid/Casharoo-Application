import 'package:flutter/material.dart';
import 'package:casharoo/services/homepage/models/cashbook.dart';

class CashbookSearchDelegate extends SearchDelegate<Cashbook?> {
  final List<Cashbook> data;
  CashbookSearchDelegate({required this.data});

  @override
  String? get searchFieldLabel => 'Search by book name or description';

  @override
  List<Widget>? buildActions(BuildContext context) => [
        IconButton(onPressed: () => query = '', icon: const Icon(Icons.clear_rounded))
      ];

  @override
  Widget? buildLeading(BuildContext context) => IconButton(
        icon: const Icon(Icons.arrow_back_rounded),
        onPressed: () => close(context, null),
      );

  @override
  Widget buildResults(BuildContext context) => _buildList(context);
  @override
  Widget buildSuggestions(BuildContext context) => _buildList(context);

  Widget _buildList(BuildContext context) {
    final q = query.trim().toLowerCase();
    final filtered = q.isEmpty
        ? data
        : data.where((c) {
            return c.name.toLowerCase().contains(q) ||
                   c.description.toLowerCase().contains(q);
          }).toList();

    if (filtered.isEmpty) {
      return const Center(child: Text('No results'));
    }

    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: filtered.length,
      separatorBuilder: (_, __) => const Divider(height: 0),
      itemBuilder: (_, i) {
        final c = filtered[i];
        return ListTile(
          leading: const Icon(Icons.bookmark_rounded),
          title: Text(c.name),
          subtitle: Text(c.friendlyUpdated),
          trailing: Text(
            c.netBalance.toStringAsFixed(0),
            style: TextStyle(
              color: c.netBalance >= 0
                  ? Theme.of(context).colorScheme.secondary
                  : Theme.of(context).colorScheme.error),
          ),
          onTap: () => close(context, c),
        );
      },
    );
  }
}
