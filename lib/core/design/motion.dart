import 'dart:math' as math;
import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme.dart';
import 'tokens.dart';

/// Shrinks a little while a finger is on it, so a tap feels answered at once.
class Pressable extends StatefulWidget {
  const Pressable({super.key, required this.child, this.onTap, this.scale = 0.96});

  final Widget child;
  final VoidCallback? onTap;
  final double scale;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  void _set(bool down) {
    if (widget.onTap != null && down != _down) setState(() => _down = down);
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _set(true),
        onTapUp: (_) => _set(false),
        onTapCancel: () => _set(false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _down ? widget.scale : 1,
          duration: context.motion(AppMotion.fast),
          curve: AppMotion.ease,
          child: widget.child,
        ),
      );
}

/// Opens when a screen appears and closes shortly after. [Entrance] widgets
/// built inside the window rise in; ones built later (scrolled into view, or
/// rebuilt by new data) simply show, so a screen arrives once and then stays still.
class EntranceScope extends StatefulWidget {
  const EntranceScope({super.key, required this.child});

  final Widget child;

  @override
  State<EntranceScope> createState() => _EntranceScopeState();
}

class _EntranceScopeState extends State<EntranceScope> {
  final _opened = Stopwatch()..start();

  @override
  Widget build(BuildContext context) => _EntranceWindow(opened: _opened, child: widget.child);
}

class _EntranceWindow extends InheritedWidget {
  const _EntranceWindow({required this.opened, required super.child});

  final Stopwatch opened;

  @override
  bool updateShouldNotify(_EntranceWindow old) => false;
}

/// Fades and rises into place, each [index] a beat after the one before.
class Entrance extends StatefulWidget {
  const Entrance({super.key, required this.child, this.index = 0});

  final Widget child;
  final int index;

  @override
  State<Entrance> createState() => _EntranceState();
}

class _EntranceState extends State<Entrance> with SingleTickerProviderStateMixin {
  static const _step = 35;
  static const _rise = 300;

  AnimationController? _controller;
  bool _decided = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_decided) return;
    _decided = true;
    final window = context.getInheritedWidgetOfExactType<_EntranceWindow>();
    if (window == null || window.opened.elapsedMilliseconds > 500 || context.reduceMotion) return;
    final delay = math.min(widget.index, 5) * _step;
    _controller = AnimationController(vsync: this, duration: Duration(milliseconds: delay + _rise))..forward();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller == null) return widget.child;
    final delay = math.min(widget.index, 5) * _step;
    final curve = CurvedAnimation(
      parent: controller,
      curve: Interval(delay / (delay + _rise), 1, curve: AppMotion.ease),
    );
    return FadeTransition(
      opacity: curve,
      child: SlideTransition(
        position: Tween(begin: const Offset(0, 0.06), end: Offset.zero).animate(curve),
        child: widget.child,
      ),
    );
  }
}

/// Shakes its child sideways each time [trigger] changes: "that did not work".
class Shake extends StatefulWidget {
  const Shake({super.key, required this.trigger, required this.child});

  final int trigger;
  final Widget child;

  @override
  State<Shake> createState() => _ShakeState();
}

class _ShakeState extends State<Shake> with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 420));

  @override
  void didUpdateWidget(Shake old) {
    super.didUpdateWidget(old);
    if (old.trigger != widget.trigger && !context.reduceMotion) {
      HapticFeedback.mediumImpact();
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _controller,
        child: widget.child,
        builder: (context, child) {
          final t = _controller.value;
          return Transform.translate(
            offset: Offset(math.sin(t * math.pi * 5) * 9 * (1 - t), 0),
            child: child,
          );
        },
      );
}

/// Turns its child for as long as [active] is true, then lets the turn finish.
class SpinWhile extends StatefulWidget {
  const SpinWhile({super.key, required this.active, required this.child});

  final bool active;
  final Widget child;

  @override
  State<SpinWhile> createState() => _SpinWhileState();
}

class _SpinWhileState extends State<SpinWhile> with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));

  @override
  void initState() {
    super.initState();
    if (widget.active) _controller.repeat();
  }

  @override
  void didUpdateWidget(SpinWhile old) {
    super.didUpdateWidget(old);
    if (widget.active && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.active && _controller.isAnimating) {
      // Finish the current turn instead of snapping back
      _controller.forward().whenCompleteOrCancel(() {
        if (mounted && !widget.active) _controller.value = 0;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      context.reduceMotion ? widget.child : RotationTransition(turns: _controller, child: widget.child);
}

/// Grows from nothing with a small overshoot whenever its [child] is swapped
/// for one with a different key: a state changing in place (cloud to tick).
class PopSwitcher extends StatelessWidget {
  const PopSwitcher({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
        duration: context.motion(AppMotion.emphasised),
        switchInCurve: AppMotion.spring,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, animation) => ScaleTransition(
          scale: animation,
          child: FadeTransition(opacity: animation, child: child),
        ),
        child: child,
      );
}

/// What just happened, for [showEventBurst].
enum AppEvent { saved, moneyIn, moneyOut, transfer, deleted }

/// Plays a short confirmation in the middle of the screen: a disc lands, its
/// sign draws itself, and it leaves. Each event has its own sign and colour,
/// so money coming in never looks like money going out. Does not block touches,
/// and survives the form that triggered it being closed.
void showEventBurst(BuildContext context, AppEvent event, {String? label}) {
  HapticFeedback.lightImpact();
  if (context.reduceMotion) return;
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return;
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _EventBurst(
      event: event,
      label: label,
      onDone: () => entry
        ..remove()
        ..dispose(),
    ),
  );
  overlay.insert(entry);
}

class _EventBurst extends StatefulWidget {
  const _EventBurst({required this.event, required this.onDone, this.label});

  final AppEvent event;
  final String? label;
  final VoidCallback onDone;

  @override
  State<_EventBurst> createState() => _EventBurstState();
}

class _EventBurstState extends State<_EventBurst> with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1150))
    ..addStatusListener((status) {
      if (status == AnimationStatus.completed) widget.onDone();
    })
    ..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final color = switch (widget.event) {
      AppEvent.saved || AppEvent.moneyIn => AppTheme.successColor,
      AppEvent.moneyOut => AppTheme.errorColor,
      AppEvent.transfer => colors.header,
      AppEvent.deleted => const Color(0xFF5B6B84),
    };
    final leave = CurvedAnimation(parent: _controller, curve: const Interval(0.82, 1, curve: Curves.easeIn));
    final labelIn = CurvedAnimation(parent: _controller, curve: const Interval(0.28, 0.5, curve: AppMotion.ease));
    return IgnorePointer(
      child: ExcludeSemantics(
        child: Align(
          alignment: const Alignment(0, -0.12),
          child: FadeTransition(
            opacity: ReverseAnimation(leave),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 220,
                  height: 220,
                  child: CustomPaint(
                    painter: _BurstPainter(
                      progress: _controller,
                      event: widget.event,
                      color: color,
                      spark: widget.event == AppEvent.transfer ? colors.gold : color,
                    ),
                  ),
                ),
                if (widget.label != null)
                  FadeTransition(
                    opacity: labelIn,
                    child: SlideTransition(
                      position: Tween(begin: const Offset(0, 0.5), end: Offset.zero).animate(labelIn),
                      child: Transform.translate(
                        offset: const Offset(0, -44),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: colors.sheet,
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                            boxShadow: [BoxShadow(color: colors.shadow, blurRadius: 20, offset: const Offset(0, 6))],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                            child: Text(
                              widget.label!,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontFeatures: tabularFigures,
                                    decoration: TextDecoration.none,
                                  ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BurstPainter extends CustomPainter {
  _BurstPainter({required this.progress, required this.event, required this.color, required this.spark})
      : super(repaint: progress);

  final Animation<double> progress;
  final AppEvent event;
  final Color color;
  final Color spark;

  static double _part(double t, double from, double to, [Curve curve = Curves.linear]) =>
      curve.transform(((t - from) / (to - from)).clamp(0.0, 1.0));

  /// The sign, in a box from -1 to 1.
  Path _glyph() {
    final path = Path();
    switch (event) {
      case AppEvent.saved:
        path
          ..moveTo(-0.85, 0.05)
          ..lineTo(-0.3, 0.6)
          ..lineTo(0.9, -0.6);
      case AppEvent.moneyIn:
        path
          ..moveTo(0.7, -0.7)
          ..lineTo(-0.6, 0.6)
          ..moveTo(-0.6, -0.25)
          ..lineTo(-0.6, 0.6)
          ..lineTo(0.25, 0.6);
      case AppEvent.moneyOut:
        path
          ..moveTo(-0.7, 0.7)
          ..lineTo(0.6, -0.6)
          ..moveTo(-0.25, -0.6)
          ..lineTo(0.6, -0.6)
          ..lineTo(0.6, 0.25);
      case AppEvent.transfer:
        path
          ..moveTo(-0.8, -0.4)
          ..lineTo(0.8, -0.4)
          ..moveTo(0.45, -0.75)
          ..lineTo(0.8, -0.4)
          ..lineTo(0.45, -0.05)
          ..moveTo(0.8, 0.4)
          ..lineTo(-0.8, 0.4)
          ..moveTo(-0.45, 0.05)
          ..lineTo(-0.8, 0.4)
          ..lineTo(-0.45, 0.75);
      case AppEvent.deleted:
        path
          ..moveTo(-0.6, -0.6)
          ..lineTo(0.6, 0.6)
          ..moveTo(0.6, -0.6)
          ..lineTo(-0.6, 0.6);
    }
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final t = progress.value;
    final centre = size.center(Offset.zero);
    const radius = 44.0;

    // A ring runs ahead of the disc and fades
    final ring = _part(t, 0.06, 0.55, Curves.easeOutCubic);
    if (ring > 0 && ring < 1) {
      canvas.drawCircle(
        centre,
        radius * (0.7 + ring * 1.25),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3 * (1 - ring)
          ..color = color.withValues(alpha: 0.5 * (1 - ring)),
      );
    }

    // Sparks fly out for good news; a delete just lands quietly
    if (event != AppEvent.deleted && event != AppEvent.moneyOut) {
      final fly = _part(t, 0.16, 0.62, Curves.easeOutCubic);
      if (fly > 0 && fly < 1) {
        final paint = Paint()
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 3.5
          ..color = spark.withValues(alpha: 1 - fly);
        for (var i = 0; i < 8; i++) {
          final angle = i * math.pi / 4 + math.pi / 8;
          final direction = Offset(math.cos(angle), math.sin(angle));
          final from = radius * (1.15 + fly * 0.85);
          canvas.drawLine(centre + direction * from, centre + direction * (from + 9 * (1 - fly)), paint);
        }
      }
    }

    // The disc lands with a small overshoot, or drifts off the way the money went
    final land = _part(t, 0, 0.3, Curves.easeOutBack);
    final drift = event == AppEvent.moneyOut ? _part(t, 0.7, 1, Curves.easeIn) * 26 : 0.0;
    final discCentre = centre + Offset(drift, -drift);
    canvas.drawCircle(
      discCentre.translate(0, 8),
      radius * land,
      Paint()
        ..color = color.withValues(alpha: 0.28)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
    );
    canvas.drawCircle(discCentre, radius * land, Paint()..color = color);

    // The sign draws itself
    final draw = _part(t, 0.24, 0.56, Curves.easeOutCubic);
    if (draw > 0) {
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = 6
        ..color = Colors.white;
      final glyph = _glyph().transform((Matrix4.identity()
            ..translate(discCentre.dx, discCentre.dy)
            ..scale(radius * 0.44, radius * 0.44))
          .storage);
      final metrics = glyph.computeMetrics().toList();
      final total = metrics.fold<double>(0, (sum, PathMetric m) => sum + m.length);
      var left = total * draw;
      for (final metric in metrics) {
        if (left <= 0) break;
        canvas.drawPath(metric.extractPath(0, math.min(left, metric.length)), paint);
        left -= metric.length;
      }
    }
  }

  @override
  bool shouldRepaint(_BurstPainter old) => old.event != event || old.color != color;
}
