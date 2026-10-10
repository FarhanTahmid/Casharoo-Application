import 'package:flutter/material.dart';

import '../money.dart';
import '../ui.dart';

/// Search box: a pill with a magnifier, and a cross to clear it once it has text.
class AppSearchField extends StatefulWidget {
  const AppSearchField({super.key, required this.onChanged, this.hint, this.autofocus = false});

  final ValueChanged<String> onChanged;
  final String? hint;
  final bool autofocus;

  @override
  State<AppSearchField> createState() => _AppSearchFieldState();
}

class _AppSearchFieldState extends State<AppSearchField> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    FieldBorder border(Color color, {bool active = false}) => FieldBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          borderSide: BorderSide(color: color, width: active ? 1.5 : 1),
          glow: color.withValues(alpha: active ? 0.14 : 0),
        );
    return TextField(
      controller: _controller,
      autofocus: widget.autofocus,
      textInputAction: TextInputAction.search,
      onChanged: (value) {
        setState(() {});
        widget.onChanged(value);
      },
      decoration: InputDecoration(
        isDense: true,
        hintText: widget.hint ?? context.l10n.search,
        prefixIcon: const Icon(Icons.search_rounded),
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        border: border(context.colors.hairline),
        enabledBorder: border(context.colors.hairline),
        focusedBorder: border(primary, active: true),
        suffixIcon: AnimatedSwitcher(
          duration: context.motion(AppMotion.fast),
          transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
          child: _controller.text.isEmpty
              ? const SizedBox.shrink()
              : IconButton(
                  tooltip: MaterialLocalizations.of(context).deleteButtonTooltip,
                  icon: const Icon(Icons.cancel_rounded),
                  onPressed: () {
                    _controller.clear();
                    setState(() {});
                    widget.onChanged('');
                  },
                ),
        ),
      ),
    );
  }
}

/// One thing a [SelectField] can be set to.
class SelectOption<T> {
  const SelectOption(this.value, this.label, {this.icon, this.detail, this.color});

  final T value;
  final String label;
  final IconData? icon;

  /// Shown as a dot before the label: the colour of a category.
  final Color? color;

  /// A quieter second line.
  final String? detail;
}

/// The currencies a picker offers, searchable by code or name. [include]
/// keeps a code that is not on the list but is already in use.
List<SelectOption<String>> currencyOptions({String? include}) => [
      for (final code in {...Money.currencies.keys, if (include != null) include})
        SelectOption(
          code,
          Money.currencies.containsKey(code) ? '$code · ${Money.currencies[code]}' : code,
          detail: Money.symbol(code).trim() == code ? null : Money.symbol(code),
        ),
    ];

class _Picked<T> {
  const _Picked(this.value);

  final T? value;
}

/// A form field that opens a list to pick from, in place of a dropdown menu.
/// Long lists can be searched; with [onCreate], a name that is not in the list
/// can be added on the spot.
class SelectField<T> extends StatelessWidget {
  const SelectField({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    this.noneLabel,
    this.onCreate,
    this.createLabel,
    this.icon,
  });

  final String label;
  final T? value;
  final List<SelectOption<T>> options;

  /// Null locks the field: it shows its value and cannot be opened.
  final ValueChanged<T?>? onChanged;

  /// When set, the list starts with this "nothing chosen" row.
  final String? noneLabel;

  /// Makes a new option from a typed name and returns its value, or null
  /// when it could not be made; the list then stays open.
  final Future<T?> Function(String name)? onCreate;
  final String? createLabel;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    // A value that is gone (deleted elsewhere) shows as nothing chosen
    final chosen = options.where((o) => o.value == value).firstOrNull;
    return PickerField(
      label: label,
      text: chosen?.label ?? noneLabel,
      icon: chosen?.icon ?? icon,
      onOpen: onChanged == null
          ? null
          : () async {
              final picked = await showSelectSheet<T>(
                context,
                title: label,
                value: chosen?.value,
                options: options,
                noneLabel: noneLabel,
                onCreate: onCreate,
                createLabel: createLabel,
              );
              if (picked != null) onChanged!(picked.value);
            },
    );
  }
}

/// The list behind a [SelectField]. Returns null when closed without a choice.
Future<({T? value})?> showSelectSheet<T>(
  BuildContext context, {
  required String title,
  required List<SelectOption<T>> options,
  T? value,
  String? noneLabel,
  Future<T?> Function(String name)? onCreate,
  String? createLabel,
}) async {
  final picked = await showAppSheet<_Picked<T>>(
    context,
    title: title,
    scrolls: false,
    builder: (_) => _SelectSheet<T>(
      options: options,
      value: value,
      noneLabel: noneLabel,
      onCreate: onCreate,
      createLabel: createLabel,
    ),
  );
  return picked == null ? null : (value: picked.value);
}

class _SelectSheet<T> extends StatefulWidget {
  const _SelectSheet({required this.options, this.value, this.noneLabel, this.onCreate, this.createLabel});

  final List<SelectOption<T>> options;
  final T? value;
  final String? noneLabel;
  final Future<T?> Function(String name)? onCreate;
  final String? createLabel;

  @override
  State<_SelectSheet<T>> createState() => _SelectSheetState<T>();
}

class _SelectSheetState<T> extends State<_SelectSheet<T>> {
  String _query = '';
  bool _creating = false;

  Future<void> _create(String name) async {
    setState(() => _creating = true);
    final created = await widget.onCreate!(name);
    if (!mounted) return;
    if (created == null) return setState(() => _creating = false);
    Navigator.pop(context, _Picked<T>(created));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final query = _query.trim().toLowerCase();
    final matches = widget.options.where((o) => o.label.toLowerCase().contains(query)).toList();
    final canCreate = widget.onCreate != null;
    final exact = widget.options.any((o) => o.label.toLowerCase() == query);
    final searchable = widget.options.length > 6 || canCreate;

    Widget row({
      required String label,
      required VoidCallback onTap,
      IconData? icon,
      Color? color,
      String? detail,
      bool selected = false,
      bool action = false,
    }) =>
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20),
          minTileHeight: 56,
          leading: color != null
              ? SizedBox(width: 36, height: 36, child: Center(child: ColorDot(color, size: 16)))
              : icon == null
              ? null
              : CircleAvatar(
                  radius: 18,
                  backgroundColor: (action ? scheme.primary : context.colors.muted).withValues(alpha: 0.12),
                  child: Icon(icon, size: 20, color: action ? scheme.primary : context.colors.muted),
                ),
          title: Text(
            label,
            style: TextStyle(
              fontWeight: selected || action ? FontWeight.w600 : FontWeight.w400,
              color: action ? scheme.primary : null,
            ),
          ),
          subtitle: detail == null ? null : Text(detail),
          trailing: PopSwitcher(
            child: selected
                ? Icon(Icons.check_circle_rounded, key: const ValueKey(true), color: scheme.primary)
                : const SizedBox(key: ValueKey(false), width: 24),
          ),
          onTap: onTap,
        );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (searchable)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: AppSearchField(
              hint: canCreate ? l10n.searchOrCreate : l10n.search,
              onChanged: (value) => setState(() => _query = value),
            ),
          ),
        if (_creating)
          const Padding(padding: EdgeInsets.all(32), child: AppLoader())
        else
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.only(bottom: 12),
              children: [
                if (widget.noneLabel != null && query.isEmpty)
                  row(
                    label: widget.noneLabel!,
                    selected: widget.value == null,
                    onTap: () => Navigator.pop(context, _Picked<T>(null)),
                  ),
                for (final option in matches)
                  row(
                    label: option.label,
                    icon: option.icon,
                    color: option.color,
                    detail: option.detail,
                    selected: option.value == widget.value,
                    onTap: () => Navigator.pop(context, _Picked<T>(option.value)),
                  ),
                if (matches.isEmpty && !canCreate)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(l10n.noMatches, textAlign: TextAlign.center),
                  ),
                if (canCreate && query.isNotEmpty && !exact)
                  row(
                    label: l10n.createNamed(_query.trim()),
                    icon: Icons.add_rounded,
                    action: true,
                    onTap: () => _create(_query.trim()),
                  )
                else if (canCreate && query.isEmpty)
                  row(
                    label: widget.createLabel ?? l10n.newCategory,
                    icon: Icons.add_rounded,
                    action: true,
                    onTap: () async {
                      final name = await promptText(context, title: widget.createLabel ?? l10n.newCategory);
                      if (name != null && mounted) await _create(name);
                    },
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
