import 'package:casharoo/services/homepage/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:casharoo/services/homepage/models/cashbook.dart';

class AddCashbookDialog extends StatefulWidget {
  const AddCashbookDialog({super.key});

  @override
  State<AddCashbookDialog> createState() => _AddCashbookDialogState();
}

class _AddCashbookDialogState extends State<AddCashbookDialog> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _desc = TextEditingController();
  final cashbookUtils = CashbookUtils();
  bool _submitting = false;

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Cashbook'),
      content: Form(
        key: _formKey,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(
                  labelText: 'Name of the new Book',
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _desc,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                ),
                minLines: 2,
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: _submitting ? null : _submit,
          icon: const Icon(Icons.save_rounded),
          label: const Text('Create'),
        ),
      ],
    );
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    final newCashbook = await cashbookUtils.createCashbook(
      _name.text.trim(),
      _desc.text.trim(),
    );

    // Return to caller; caller will hit API
    if (mounted) {
      Navigator.pop(context, newCashbook);
    }
  }
}
