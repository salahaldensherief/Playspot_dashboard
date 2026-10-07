import 'package:flutter/material.dart';

import 'session_time_builder.dart';

/// Keeps the rendered subtree stable until its selected clock value changes.
class SessionTimeSelector<T> extends StatefulWidget {
  final T Function(DateTime) select;
  final Widget Function(BuildContext, T) builder;

  const SessionTimeSelector({
    super.key,
    required this.select,
    required this.builder,
  });

  @override
  State<SessionTimeSelector<T>> createState() => _SessionTimeSelectorState<T>();
}

class _SessionTimeSelectorState<T> extends State<SessionTimeSelector<T>> {
  T? _selected;
  Widget? _child;

  @override
  void didUpdateWidget(covariant SessionTimeSelector<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Parent changes (for example an extended booking) must also render.
    _child = null;
  }

  @override
  Widget build(BuildContext context) {
    return SessionTimeBuilder(builder: (context, now) {
      final selected = widget.select(now);
      if (_child == null || selected != _selected) {
        _selected = selected;
        _child = widget.builder(context, selected);
      }
      return _child!;
    });
  }
}
