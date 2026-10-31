import 'package:flutter/material.dart';
import 'session_ticker.dart';
part 'session_clock_host_state.dart';

class SessionClockHost extends StatefulWidget {
  final Widget child;
  final DateTime Function()? clock;
  const SessionClockHost({super.key, required this.child, this.clock});
  @override
  State<SessionClockHost> createState() => _SessionClockHostState();
}
