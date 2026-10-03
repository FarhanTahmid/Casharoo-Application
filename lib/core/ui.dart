import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import 'money.dart';
import 'theme.dart';

extension ContextX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);

  String get languageCode => Localizations.localeOf(this).languageCode;

  /// Amount for display in the current language.
  String money(int amountMinor, String currency) => Money.format(amountMinor, currency, locale: languageCode);

  void showMessage(String message) {
    ScaffoldMessenger.of(this)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

/// Turns the 'offline' marker from the auth controller into a sentence.
String authErrorText(BuildContext context, String error) => error == 'offline' ? context.l10n.offlineError : error;

Future<bool> confirm(BuildContext context, String message, {String? action}) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(context.l10n.cancel)),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(action ?? context.l10n.delete)),
        ],
      ),
    ) ??
    false;

/// Asks for one line of text. Returns null when cancelled or left empty.
Future<String?> promptText(BuildContext context, {required String title, String? label, String initial = ''}) {
  final controller = TextEditingController(text: initial);
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        autofocus: true,
        decoration: InputDecoration(labelText: label),
        onSubmitted: (value) => Navigator.pop(context, value.trim()),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(context.l10n.cancel)),
        FilledButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: Text(context.l10n.save)),
      ],
    ),
  ).then((value) => value == null || value.isEmpty ? null : value);
}

/// The Spendroo logo from assets/brand. [full] adds the wordmark (white on
/// dark backgrounds); otherwise only the wallet mark.
class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.height = 64, this.full = false});

  final double height;
  final bool full;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final asset = !full
        ? 'assets/brand/spendroo-mark-512w.png'
        : dark
            ? 'assets/brand/spendroo-logo-stacked-reverse-800w.png'
            : 'assets/brand/spendroo-logo-stacked-800w.png';
    return Image.asset(asset, height: height, semanticLabel: context.l10n.appName);
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 56, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3)),
              const SizedBox(height: 16),
              Text(message, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge),
            ],
          ),
        ),
      );
}

/// Renders a stream-backed provider: spinner while loading, the error if it fails.
class AsyncView<T> extends StatelessWidget {
  const AsyncView({super.key, required this.value, required this.builder});

  final AsyncValue<T> value;
  final Widget Function(T data) builder;

  @override
  Widget build(BuildContext context) => value.when(
        data: builder,
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
      );
}

/// Green for money in, red for money out.
Color amountColor(bool isIn) => isIn ? AppTheme.successColor : AppTheme.errorColor;

/// Field for typing an amount in major units ("1250.50").
class AmountField extends StatelessWidget {
  const AmountField({super.key, required this.controller, required this.currency, this.label, this.allowZero = false});

  final TextEditingController controller;
  final String currency;
  final String? label;
  final bool allowZero;

  @override
  Widget build(BuildContext context) => TextFormField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(labelText: label ?? context.l10n.amount, prefixText: Money.symbol(currency)),
        validator: (value) {
          final amount = Money.parse(value ?? '', currency);
          return amount == null || (amount == 0 && !allowZero) ? context.l10n.amountInvalid : null;
        },
      );
}

/// Tappable field that opens a date picker. Dates are ISO strings (yyyy-MM-dd).
class DateField extends StatelessWidget {
  const DateField({super.key, required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: DateTime.parse(value),
            firstDate: DateTime(2000),
            lastDate: DateTime.now().add(const Duration(days: 365)),
          );
          if (picked != null) onChanged(picked.toIso8601String().substring(0, 10));
        },
        child: InputDecorator(
          decoration: InputDecoration(labelText: context.l10n.date, suffixIcon: const Icon(Icons.calendar_today)),
          child: Text(formatDate(context, value)),
        ),
      );
}

/// "‹ October 2026 ›": steps a month back or forward. [month] is any day in the month.
class MonthSwitcher extends StatelessWidget {
  const MonthSwitcher({super.key, required this.month, required this.onChanged});

  final DateTime month;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            tooltip: context.l10n.previousMonth,
            icon: const Icon(Icons.chevron_left),
            onPressed: () => onChanged(DateTime(month.year, month.month - 1)),
          ),
          SizedBox(
            width: 180,
            child: Text(
              MaterialLocalizations.of(context).formatMonthYear(month),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          IconButton(
            tooltip: context.l10n.nextMonth,
            icon: const Icon(Icons.chevron_right),
            onPressed: () => onChanged(DateTime(month.year, month.month + 1)),
          ),
        ],
      );
}

/// "1 Oct 2026", with Bengali month names and digits in Bangla.
String formatDate(BuildContext context, String isoDate) =>
    MaterialLocalizations.of(context).formatMediumDate(DateTime.parse(isoDate));

String todayIso() => DateTime.now().toIso8601String().substring(0, 10);
