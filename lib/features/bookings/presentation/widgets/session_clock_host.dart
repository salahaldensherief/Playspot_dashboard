import 'package:flutter/material.dart';
import 'session_ticker.dart';
part 'session_clock_host_state.dart';

class SessionClockHost extends StatefulWidget {
  final Widget child;
  const SessionClockHost({super.key, required this.child});
  @override
  State<SessionClockHost> createState() => _SessionClockHostState();
}
