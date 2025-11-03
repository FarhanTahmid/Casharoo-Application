import 'package:flutter/material.dart';
import 'package:casharoo/services/cashbook_operations/models/api_repository.dart';
import 'package:casharoo/services/cashbook_operations/data/entry.dart';
import 'package:casharoo/services/cashbook_operations/data/category.dart';
import 'package:casharoo/services/cashbook_operations/data/payment_method.dart';

class EntryFormPage extends StatefulWidget {
  final String cashbookId;
  final EntryType initialType;
  final EntryRepository repo;

  const EntryFormPage({
    super.key,
    required this.cashbookId,
    required this.initialType,
    required this.repo,
  });

  @override
  State<EntryFormPage> createState() => _EntryFormPageState();
}

class _EntryFormPageState extends State<EntryFormPage> {
  late EntryType _type;
  DateTime _when = DateTime.now();
  final _amountCtrl = TextEditingController();
  double? _calcPreview;
  final _remarkCtrl = TextEditingController();
  Category? _category;
  PaymentMethod? _payment;
  // ignore: unused_field
  String? _contact;

  @override
  void initState() {
    super.initState();
    _type = widget.initialType;
    _amountCtrl.addListener(_recalc);
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _remarkCtrl.dispose();
    super.dispose();
  }

  void _recalc() {
    final s = _amountCtrl.text.trim();
    _calcPreview = _evaluateMath(s);
    setState(() {});
  }

  double? _evaluateMath(String s) {
    if (s.isEmpty) return null;
    // very small expression evaluator: supports + - * / % and decimals
    // if parsing fails -> null
    try {
      // sanitize
      final ok = RegExp(r'^[0-9\.\+\-\*\/\%\(\)\s]+$');
      if (!ok.hasMatch(s)) return double.tryParse(s);
      // precedence * / % > + -
      List<String> tokens = _tokenize(s);
      double evalMulDiv(List<String> toks) {
        final out = <String>[];
        double? acc;
        String? op;
        for (final tk in toks) {
          if (tk == '*' || tk == '/' || tk == '%') {
            op = tk;
          } else if (tk == '+' || tk == '-') {
            if (acc != null) out.add(acc.toString());
            out.add(tk);
            acc = null; op = null;
          } else {
            final v = double.parse(tk);
            if (acc == null) {
              acc = v;
            } else {
              if (op == '*') acc *= v;
              if (op == '/') acc /= v;
              if (op == '%') acc %= v;
            }
          }
        }
        if (acc != null) out.add(acc.toString());
        return _evalAddSub(out);
      }
      return evalMulDiv(tokens);
    } catch (_) {
      return double.tryParse(s);
    }
  }

  List<String> _tokenize(String s) {
    final r = RegExp(r'(\d+\.?\d*|\+|\-|\*|\/|%)');
    return r.allMatches(s.replaceAll(' ', '')).map((m) => m.group(0)!).toList();
  }

  double _evalAddSub(List<String> tokens) {
    double result = double.parse(tokens.first);
    for (int i = 1; i < tokens.length; i += 2) {
      final op = tokens[i];
      final v = double.parse(tokens[i + 1]);
      if (op == '+') result += v;
      if (op == '-') result -= v;
    }
    return result;
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _when,
      firstDate: DateTime(DateTime.now().year - 2),
      lastDate: DateTime(DateTime.now().year + 2),
    );
    if (d != null) {
      final t = TimeOfDay.fromDateTime(_when);
      setState(() => _when = DateTime(d.year, d.month, d.day, t.hour, t.minute));
    }
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_when));
    if (t != null) {
      setState(() => _when = DateTime(_when.year, _when.month, _when.day, t.hour, t.minute));
    }
  }

  Future<void> _save({bool popAndStay = false}) async {
    // Prefer live calculator preview; otherwise parse the text (strip commas/spaces).
    final amount = _calcPreview ?? double.tryParse(_amountCtrl.text.replaceAll(',', '').trim());

    if (amount == null || amount <= 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter a valid amount')),
        );
      }
      return;
    }

    // The moment the user picked in the UI (date+time)
    final when = _when; // DateTime

    final entry = Entry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      cashbookId: widget.cashbookId,
      date: DateTime(when.year, when.month, when.day), // date-only for filters
      timestamp: when,                                  // exact creation time
      updatedAt: DateTime.now(),
      type: _type,
      amount: amount,
      title: _type == EntryType.cashIn ? 'Cash In' : 'Cash Out', // optional label
      remark: _remarkCtrl.text.trim().isEmpty ? null : _remarkCtrl.text.trim(),
      categoryName: _category?.name ?? 'Miscellaneous',
      paymentModeName: _payment?.name ?? 'Cash',
      runningBalance: 0,          // server can return real value later
      createdBy: 'You',
    );

    await widget.repo.createEntry(entry);

    if (!mounted) return;

    if (popAndStay) {
      _amountCtrl.clear();
      _remarkCtrl.clear();
      setState(() {
        _calcPreview = null;
        // Keep date/time & selected type/modes as-is for fast repeat entry.
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved')));
    } else {
      Navigator.pop(context, true); // signal caller to refresh silently
    }
}


  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final isIn = _type == EntryType.cashIn;

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: Text(isIn ? 'Add Cash In Entry' : 'Add Cash Out Entry',
            style: t.titleLarge?.copyWith(color: isIn ? cs.secondary : cs.error)),
        actions: [
          IconButton(icon: const Icon(Icons.settings_rounded), onPressed: () {/* page settings later */}),
        ],
      ),
      bottomNavigationBar: _KeypadBar(
        onSaveAddNew: () => _save(popAndStay: true),
        onSave: _save,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 180),
        children: [
          Row(
            children: [
              ChoiceChip(
                selected: isIn, label: const Text('Cash In'),
                onSelected: (_) => setState(() => _type = EntryType.cashIn),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                selected: !isIn, label: const Text('Cash Out'),
                onSelected: (_) => setState(() => _type = EntryType.cashOut),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _OutlinedTile(
                  label: 'Date',
                  value: '${_when.day}/${_when.month}/${_when.year}',
                  icon: Icons.event_rounded,
                  onTap: _pickDate,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _OutlinedTile(
                  label: 'Time',
                  value: TimeOfDay.fromDateTime(_when).format(context),
                  icon: Icons.access_time_rounded,
                  onTap: _pickTime,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Amount (+ live calc line)
          TextFormField(
            controller: _amountCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: false),
            decoration: const InputDecoration(labelText: 'Amount *'),
          ),
          if (_calcPreview != null)
            Padding(
              padding: const EdgeInsets.only(top: 6, bottom: 10),
              child: Text('= ${_calcPreview!.toStringAsFixed(2)}',
                  style: t.bodySmall?.copyWith(color: cs.primary)),
            ),

          // Contact
          TextFormField(
            decoration: const InputDecoration(hintText: 'Contact (Customer/Supplier)'),
            onChanged: (v) => _contact = v,
          ),
          const SizedBox(height: 12),

          // Remark
          TextFormField(
            controller: _remarkCtrl,
            decoration: const InputDecoration(hintText: 'Remark'),
          ),
          const SizedBox(height: 12),

          // Attachment button (UI only)
          OutlinedButton.icon(
            onPressed: () {/* open picker later */},
            icon: const Icon(Icons.attachment_rounded),
            label: const Text('Attach Image or PDF'),
          ),
          const SizedBox(height: 12),

          // Category & Payment
          DropdownButtonFormField<Category>(
            decoration: const InputDecoration(labelText: 'Category'),
            value: _category,
            items: const [],
            onChanged: (_) {},
            onTap: () async {
              // open sheet to create/select
              // actual picker in bottom-sheets already; this dropdown just for visual parity
            },
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<PaymentMethod>(
            decoration: const InputDecoration(labelText: 'Payment Mode'),
            value: _payment,
            items: const [],
            onChanged: (_) {},
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {/* open "Show more" advanced fields later */},
              child: const Text('Show More'),
            ),
          ),
        ],
      ),
    );
  }
}

class _OutlinedTile extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final VoidCallback onTap;
  const _OutlinedTile({required this.label, required this.value, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).dividerColor.withOpacity(.35)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(icon, size: 18),
              const SizedBox(width: 8),
              Text(label, style: t.bodySmall),
              const Spacer(),
              Text(value, style: t.titleMedium),
            ],
          ),
        ),
      ),
    );
  }
}

class _KeypadBar extends StatelessWidget {
  final VoidCallback onSaveAddNew;
  final VoidCallback onSave;
  const _KeypadBar({required this.onSaveAddNew, required this.onSave});
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: onSaveAddNew,
                child: const Text('SAVE & ADD NEW'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: onSave,
                child: const Text('SAVE'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
