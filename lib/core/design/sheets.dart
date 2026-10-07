import 'package:flutter/material.dart';

import '../ui.dart';

/// The frame every bottom sheet shares: a title, content that scrolls when it
/// is tall, and room for the keyboard and the home bar.
class SheetFrame extends StatelessWidget {
  const SheetFrame({super.key, required this.child, this.title, this.trailing, this.scrolls = true});

  final String? title;

  /// Sits at the end of the title row.
  final Widget? trailing;
  final Widget child;

  /// False when [child] brings its own scrolling list.
  final bool scrolls;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: media.size.height * 0.86),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (title != null || trailing != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 12, 12),
                child: Row(
                  children: [
                    Expanded(child: Text(title ?? '', style: Theme.of(context).textTheme.titleLarge)),
                    if (trailing != null) trailing!,
                  ],
                ),
              ),
            Flexible(
              child: scrolls
                  ? SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + media.padding.bottom),
                      child: child,
                    )
                  : Padding(padding: EdgeInsets.only(bottom: media.padding.bottom), child: child),
            ),
          ],
        ),
      ),
    );
  }
}

/// Opens [builder] in the app's bottom sheet. Forms, choices and questions all
/// arrive this way, so their buttons land where a thumb already is.
Future<T?> showAppSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  String? title,
  Widget? trailing,
  bool scrolls = true,
}) =>
    showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => SheetFrame(title: title, trailing: trailing, scrolls: scrolls, child: builder(context)),
    );

/// Asks before something that cannot be undone. Without [action] the question
/// is about deleting, and the button says so in red.
Future<bool> confirm(BuildContext context, String message, {String? action}) async {
  final destructive = action == null;
  return await showAppSheet<bool>(
        context,
        builder: (context) {
          final scheme = Theme.of(context).colorScheme;
          final tint = destructive ? scheme.error : scheme.primary;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.4, end: 1),
                  duration: context.motion(AppMotion.emphasised),
                  curve: AppMotion.spring,
                  builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
                  child: CircleAvatar(
                    radius: 24,
                    backgroundColor: tint.withValues(alpha: 0.12),
                    child: Icon(destructive ? Icons.delete_outline_rounded : Icons.help_outline_rounded, color: tint),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(message, style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(context.l10n.cancel),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      style: destructive
                          ? FilledButton.styleFrom(backgroundColor: scheme.error, foregroundColor: scheme.onError)
                          : null,
                      onPressed: () => Navigator.pop(context, true),
                      child: Text(action ?? context.l10n.delete),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ) ??
      false;
}

/// Asks for one line of text. Returns null when cancelled or left empty.
Future<String?> promptText(BuildContext context, {required String title, String? label, String initial = ''}) {
  final controller = TextEditingController(text: initial);
  return showAppSheet<String>(
    context,
    title: title,
    builder: (context) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(labelText: label),
          onSubmitted: (value) => Navigator.pop(context, value.trim()),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: () => Navigator.pop(context, controller.text.trim()),
          child: Text(context.l10n.save),
        ),
      ],
    ),
  ).then((value) => value == null || value.isEmpty ? null : value);
}
