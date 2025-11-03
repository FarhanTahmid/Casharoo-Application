// lib/services/homepage/ui/popups/payment_mode_sheet.dart
import 'package:flutter/material.dart';
import 'package:casharoo/services/cashbook_operations/models/api_repository.dart';
import 'package:casharoo/services/cashbook_operations/data/payment_method.dart';

class PaymentModeSheet extends StatefulWidget {
  final String cashbookId;
  final EntryRepository repo;
  const PaymentModeSheet({super.key, required this.cashbookId, required this.repo});

  @override
  State<PaymentModeSheet> createState() => _PaymentModeSheetState();
}

class _PaymentModeSheetState extends State<PaymentModeSheet> {
  final _nameCtrl = TextEditingController();
  List<PaymentMethod> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    _items = await widget.repo.listPaymentMethods(widget.cashbookId);
    if (mounted) setState(() {});
  }

  Future<void> _create() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    await widget.repo.createPaymentMethod(widget.cashbookId, name);
    _nameCtrl.clear();
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16, right: 16,
          top: 12,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(children: [
              const Expanded(child: Text('Add New Payment Mode', style: TextStyle(fontWeight: FontWeight.w600))),
              IconButton(onPressed: ()=>Navigator.pop(context), icon: const Icon(Icons.close_rounded)),
            ]),
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Payment Mode'),
              onSubmitted: (_) => _create(),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(onPressed: _create, child: const Text('SAVE')),
            ),
            const SizedBox(height: 16),
            Align(alignment: Alignment.centerLeft, child: Text('Suggestions')),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: _items.map((p) => InputChip(label: Text(p.name), onPressed: () {
                Navigator.pop(context, p);
              })).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
