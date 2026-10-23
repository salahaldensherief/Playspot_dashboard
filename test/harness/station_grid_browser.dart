// Localhost-only browser harness for the production station overview widget.
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/features/bookings/domain/entities/booking.dart';
import 'package:play_spot_dashboard/features/bookings/domain/entities/station_operational_state.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/widgets/session_ticker.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/widgets/station_overview_grid.dart';
import 'package:play_spot_dashboard/features/requests/domain/entities/client_request_entity.dart';
import 'package:play_spot_dashboard/features/rooms/domain/entities/room_entity.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  final requested =
      int.tryParse(Uri.base.queryParameters['stations'] ?? '') ?? 6;
  final count = requested.clamp(1, 40);
  final language = Uri.base.queryParameters['lang'] == 'ar' ? 'ar' : 'en';
  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('ar'), Locale('en')],
      startLocale: Locale(language),
      fallbackLocale: const Locale('en'),
      saveLocale: false,
      path: 'assets/translations',
      child: ScreenUtilInit(
        designSize: const Size(1440, 900),
        builder: (context, child) => _Harness(
          stationCount: count,
          initiallyFresh: Uri.base.queryParameters['fresh'] != 'false',
          initiallyConflicted: Uri.base.queryParameters['conflict'] == 'true',
          initiallyPermitted: Uri.base.queryParameters['permitted'] != 'false',
          variedTypes: Uri.base.queryParameters['types'] == 'varied',
        ),
      ),
    ),
  );
}

class _Harness extends StatefulWidget {
  final int stationCount;
  final bool initiallyFresh;
  final bool initiallyConflicted;
  final bool initiallyPermitted;
  final bool variedTypes;

  const _Harness({
    required this.stationCount,
    required this.initiallyFresh,
    required this.initiallyConflicted,
    required this.initiallyPermitted,
    required this.variedTypes,
  });

  @override
  State<_Harness> createState() => _HarnessState();
}

class _HarnessState extends State<_Harness> {
  late bool _fresh;
  late bool _conflict;
  late bool _permitted;
  int _revision = 1;
  late final SessionTickerNotifier _ticker;
  late List<RoomEntity> _rooms;
  late List<Booking> _bookings;
  late List<ClientRequestEntity> _requests;

  @override
  void initState() {
    super.initState();
    _fresh = widget.initiallyFresh;
    _conflict = widget.initiallyConflicted;
    _permitted = widget.initiallyPermitted;
    _ticker = SessionTickerNotifier();
    _seed();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _seed() {
    final now = DateTime.now();
    _rooms = List.generate(widget.stationCount, (index) {
      final number = index + 1;
      final kind = widget.variedTypes ? index % 5 : index % 2;
      final namesEn = widget.variedTypes
          ? ['Room', 'PC', 'PlayStation', 'Billiards', 'Ping pong']
          : ['PC', 'PlayStation'];
      final namesAr = widget.variedTypes
          ? ['غرفة', 'كمبيوتر', 'بلايستيشن', 'بلياردو', 'بنج بونج']
          : ['كمبيوتر', 'بلايستيشن'];
      return RoomEntity(
        id: 'station-$number',
        loungeId: 'fixture-lounge',
        nameAr: '${namesAr[kind]} $number',
        nameEn: '${namesEn[kind]} $number',
        spaceType: widget.variedTypes && kind == 0
            ? 'standard_room'
            : 'open_area',
        activityNames: widget.variedTypes && kind == 3
            ? const ['Billiards']
            : widget.variedTypes && kind == 4
            ? const ['Table Tennis']
            : const [],
        isAvailable: index % 4 == 0,
        images: const [],
        featuresAr: const [],
        featuresEn: const [],
        resourceType: widget.variedTypes
            ? ['console', 'pc', 'console', 'table_sport', 'table_sport'][kind]
            : index.isEven
            ? 'pc'
            : 'playstation',
        status: index % 4 == 0
            ? RoomStatusEnum.available
            : RoomStatusEnum.occupied,
      );
    });
    _bookings = [
      for (var index = 0; index < widget.stationCount; index++)
        if (index % 4 != 0)
          Booking(
            id: 'booking-$index',
            userId: 'customer-$index',
            userName: 'Customer $index',
            loungeId: 'fixture-lounge',
            roomId: 'station-${index + 1}',
            roomName: 'Station ${index + 1}',
            date: now,
            startTime: '${now.hour.toString().padLeft(2, '0')}:00',
            endTime: index % 5 == 0
                ? '${(now.hour - 1).clamp(0, 23).toString().padLeft(2, '0')}:00'
                : '${(now.hour + 1).clamp(0, 23).toString().padLeft(2, '0')}:00',
            status: BookingStatus.inProgress,
            paymentStatus: index % 3 == 0
                ? PaymentStatus.partial
                : PaymentStatus.paid,
            totalPrice: 100,
            isOpenTime: index % 6 == 0,
            openTimeStartedAt: now.subtract(Duration(minutes: 30 + index)),
          ),
    ];
    _requests = [
      if (widget.stationCount > 2)
        ClientRequestEntity(
          id: 'request-1',
          loungeId: 'fixture-lounge',
          roomId: 'station-3',
          titleAr: 'مساعدة',
          titleEn: 'Help',
          bodyAr: 'طلب مساعدة',
          bodyEn: 'Assistance requested',
          type: ClientRequestType.callStaff,
          createdAt: now,
        ),
    ];
  }

  void _simulateRealtime() {
    setState(() {
      _fresh = !_fresh;
      _revision++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final states = StationOperationalState.build(
      rooms: _rooms,
      bookings: [
        ..._bookings,
        if (_conflict && _bookings.isNotEmpty)
          _bookings.first.copyWith(id: 'conflicting-session'),
      ],
      requests: _requests,
      roomDataFresh: _fresh,
    );
    return MaterialApp(
      locale: context.locale,
      supportedLocales: context.supportedLocales,
      localizationsDelegates: context.localizationDelegates,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: AppColors.scaffoldBackground,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: Text('Station browser verification · ${widget.stationCount}'),
          actions: [
            TextButton(
              key: const Key('toggle-locale'),
              onPressed: () => context.setLocale(
                context.locale.languageCode == 'ar'
                    ? const Locale('en')
                    : const Locale('ar'),
              ),
              child: Text(context.locale.languageCode.toUpperCase()),
            ),
          ],
        ),
        body: SessionTickerScope(
          ticker: _ticker,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton(
                    key: const Key('simulate-realtime'),
                    onPressed: _simulateRealtime,
                    child: Text('Realtime revision $_revision'),
                  ),
                  FilledButton(
                    key: const Key('toggle-conflict'),
                    onPressed: () => setState(() => _conflict = !_conflict),
                    child: Text('Conflict ${_conflict ? 'ON' : 'OFF'}'),
                  ),
                  FilledButton(
                    key: const Key('toggle-permission'),
                    onPressed: () => setState(() => _permitted = !_permitted),
                    child: Text('Permission ${_permitted ? 'ON' : 'OFF'}'),
                  ),
                  Text('Fresh: $_fresh · Alerts: ${_requests.length}'),
                ],
              ),
              const SizedBox(height: 16),
              StationOverviewGrid(
                stations: states,
                onManage: (booking) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        _permitted
                            ? 'Manage ${booking.id}'
                            : 'Permission denied',
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
