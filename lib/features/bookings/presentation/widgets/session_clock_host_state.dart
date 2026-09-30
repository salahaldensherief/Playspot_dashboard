part of 'session_clock_host.dart';

class _SessionClockHostState extends State<SessionClockHost> {
  late final SessionTickerNotifier _ticker;
  @override
  void initState() {
    super.initState();
    _ticker = SessionTickerNotifier();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      SessionTickerScope(ticker: _ticker, child: widget.child);
}
