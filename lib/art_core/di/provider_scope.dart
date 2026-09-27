import 'package:flutter/widgets.dart';
import 'package:nested/nested.dart';

/// Shared helper widget that folds a list of providers into a nested tree.
///
/// Complies with AGENT_RULES Section 2:
/// "Instead of MultiBlocProvider or manual nesting, all ShellRoute-level
/// persistent Cubits MUST be composed via a single shared helper widget
/// (e.g. MultiBlocProviderScope in art_core/di/provider_scope.dart) that
/// internally folds a `List<BlocProvider>` into a nested tree."
class MultiBlocProviderScope extends StatelessWidget {
  final List<SingleChildWidget> providers;
  final Widget child;

  const MultiBlocProviderScope({
    super.key,
    required this.providers,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Nested(
      children: providers,
      child: child,
    );
  }
}
