import 'package:flutter/material.dart';

class TopActionsOverflow extends StatelessWidget {
  final ValueChanged<String> onNavigate;
  const TopActionsOverflow({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: onNavigate,
      itemBuilder: (_) => const [
        PopupMenuItem(value: 'settings', child: _Item(Icons.bookmark_rounded, 'Book Settings')),
        PopupMenuItem(value: 'activity', child: _Item(Icons.history_rounded, 'Book Activity')),
        PopupMenuItem(value: 'delete_all', child: _Item(Icons.delete_forever_rounded, 'Delete All Entries')),
        PopupMenuItem(value: 'excel', child: _Item(Icons.table_chart_rounded, 'Excel Report')),
      ],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}

class _Item extends StatelessWidget {
  final IconData icon; final String text;
  const _Item(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return ListTile(leading: Icon(icon), title: Text(text), dense: true);
  }
}
