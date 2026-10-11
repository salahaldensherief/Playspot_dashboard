import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/di/di.dart';
import '../../../../core/router/router_keys.dart';

/// Physical opening and safe online cashier availability are separate states.
class OnlineBookingStatus extends StatefulWidget {
  final String loungeId;
  final Future<Map<String, dynamic>> Function(String)? loader;
  const OnlineBookingStatus({super.key, required this.loungeId, this.loader});
  @override
  State<OnlineBookingStatus> createState() => _OnlineBookingStatusState();
}

class _OnlineBookingStatusState extends State<OnlineBookingStatus> {
  Timer? _timer;
  Map<String, dynamic>? _status;
  bool _loading = false;
  @override
  void initState() {
    super.initState();
    _refresh();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _refresh());
  }

  @override
  void didUpdateWidget(OnlineBookingStatus oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.loungeId != widget.loungeId) {
      _status = null;
      _refresh();
    }
  }

  Future<void> _refresh() async {
    if (_loading || widget.loungeId.isEmpty) return;
    _loading = true;
    final loungeId = widget.loungeId;
    try {
      final data = widget.loader != null
          ? await widget.loader!(loungeId)
          : Map<String, dynamic>.from(await sl<SupabaseClient>().rpc(
              'get_lounge_operating_status', params: {'p_lounge_id': loungeId}));
      if (mounted && loungeId == widget.loungeId) setState(() => _status = data);
    } catch (_) {
      if (mounted && loungeId == widget.loungeId) setState(() => _status = null);
    } finally {
      _loading = false;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final available = _status?['can_book_online'] == true;
    final paused = _status?['status'] == 'technical_issue';
    final color = available ? Colors.greenAccent : Colors.amber;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(children: [
        Icon(available ? Icons.cloud_done : Icons.cloud_off, color: color, size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text(
          (_status == null ? 'online_booking_status_unknown' : available
              ? 'online_booking_status_ready' : paused
              ? 'online_booking_status_paused' : 'online_booking_status_closed').tr(),
          style: TextStyle(color: color, fontSize: 13),
        )),
        if (paused) TextButton(
          onPressed: () async {
            await context.push(RouterKeys.loungeAdminOffline);
            if (mounted) await _refresh();
          },
          child: Text('offline_workspace.resume'.tr()),
        ),
        IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh),
          tooltip: 'refresh'.tr()),
      ]),
    );
  }
}
