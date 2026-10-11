part of 'session_clock_host.dart';

class _SessionClockHostState extends State<SessionClockHost>
    with WidgetsBindingObserver {
  late final SessionTickerNotifier _ticker;
  bool _resumed = true;
  bool _visible = false;
  bool _hasParentClock = false;
  @override
  void initState() {
    super.initState();
    _ticker = SessionTickerNotifier(clock: widget.clock, enabled: false);
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    _resumed = lifecycle == null || lifecycle == AppLifecycleState.resumed;
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _visible = TickerMode.of(context);
    _hasParentClock =
        widget.clock == null &&
        context.getInheritedWidgetOfExactType<SessionTickerScope>() != null;
    _ticker.setEnabled(_visible && _resumed && !_hasParentClock);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _resumed = state == AppLifecycleState.resumed;
    _ticker.setEnabled(_visible && _resumed && !_hasParentClock);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _hasParentClock
      ? widget.child
      : SessionTickerScope(ticker: _ticker, child: widget.child);
}
