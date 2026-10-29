import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/features/auth/presentation/login/login_cubit.dart';
import 'package:play_spot_dashboard/features/auth/presentation/login/login_state.dart';
import 'package:play_spot_dashboard/features/bookings/domain/entities/booking.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/cubit/booking_cubit.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/cubit/booking_state.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/widgets/room_occupancy_card.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/widgets/session_clock_host.dart';
import 'package:play_spot_dashboard/features/requests/presentation/client_requests_cubit.dart';
import 'package:play_spot_dashboard/features/requests/presentation/client_requests_state.dart';
import 'package:play_spot_dashboard/features/rooms/domain/entities/room_entity.dart';
import 'package:play_spot_dashboard/features/rooms/presentation/cubit/room_cubit.dart';
import 'package:play_spot_dashboard/features/rooms/presentation/cubit/room_state.dart';

// Synthetic visual fixture only. No Supabase/Auth initialization or network RPCs.
class FixtureLogin extends Cubit<LoginState> implements LoginCubit {
  FixtureLogin() : super(const LoginState());
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FixtureRequests extends Cubit<ClientRequestsState>
    implements ClientRequestsCubit {
  FixtureRequests() : super(const ClientRequestsState());
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FixtureRooms extends Cubit<RoomState> implements RoomCubit {
  FixtureRooms() : super(const RoomState());
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FixtureBookings extends Cubit<BookingState> implements BookingCubit {
  int attempts = 0;
  FixtureBookings()
    : super(
        const BookingState(errorMessage: 'Fixture: operation not confirmed'),
      );
  @override
  Future<Map<String, dynamic>?> completeOpenTimeSession(String id) async {
    attempts++;
    return null;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

RoomEntity fixtureRoom(int i) {
  const types = [
    'console',
    'pc',
    'table_sport',
    'table_sport',
    'vr',
    'simulator',
    'mixed',
  ];
  return RoomEntity(
    id: 'r$i',
    loungeId: 'fixture',
    nameAr: i == 0
        ? 'غرفة كبار الزوار · شاشة كبيرة وجلسة جماعية'
        : 'محطة ${i + 1}',
    nameEn: i == 0 ? 'VIP room · friends and big screen' : 'Station ${i + 1}',
    resourceType: types[i % 7],
    activityNames: i % 7 == 2
        ? ['billiards']
        : i % 7 == 3
        ? ['table_tennis']
        : [],
    spaceType: i == 0 ? 'vip_room' : 'open_area',
    isAvailable: true,
    images: [],
    featuresAr: [],
    featuresEn: [],
    pricePerHourSingle: 70,
    pricePerHourMulti: 100,
    requiresScreen: ![2, 3].contains(i % 7),
    requiresControllers: ![1, 2, 3].contains(i % 7),
    status: i % 7 == 6 ? RoomStatusEnum.maintenance : RoomStatusEnum.available,
  );
}

final fixtureNow = DateTime.utc(2030, 1, 10, 15);
Booking fixtureBooking(int i) {
  final now = fixtureNow;
  return Booking(
    id: 'b$i',
    userId: 'fixture',
    loungeId: 'fixture',
    roomId: 'r$i',
    date: now,
    startTime: '14:00',
    endTime: '16:00',
    scheduledStartUtc: now.toUtc().subtract(const Duration(minutes: 43)),
    scheduledEndUtc: now.toUtc().add(const Duration(minutes: 17)),
    durationMinutes: 60,
    status: BookingStatus.inProgress,
    paymentStatus: PaymentStatus.partial,
    totalPrice: 12345.75,
    userName: 'عميل باسم عربي طويل لتجربة المساحة',
    isOpenTime: i % 2 == 0,
    openTimeStartedAt: now.toUtc().subtract(const Duration(minutes: 43)),
  );
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  final language = Uri.base.queryParameters['lang'] == 'en' ? 'en' : 'ar';
  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('ar'), Locale('en')],
      startLocale: Locale(language),
      saveLocale: false,
      path: 'assets/translations',
      child: const EquipmentPreview(),
    ),
  );
}

class EquipmentPreview extends StatelessWidget {
  final bool isStale;
  final bool isRefreshing;
  final int? stationCount;
  final double textScale;
  const EquipmentPreview({
    super.key,
    this.isStale = false,
    this.isRefreshing = false,
    this.stationCount,
    this.textScale = 1,
  });
  @override
  Widget build(BuildContext context) => MultiBlocProvider(
    providers: [
      BlocProvider<LoginCubit>(create: (_) => FixtureLogin()),
      BlocProvider<ClientRequestsCubit>(create: (_) => FixtureRequests()),
      BlocProvider<BookingCubit>(create: (_) => FixtureBookings()),
      BlocProvider<RoomCubit>(create: (_) => FixtureRooms()),
    ],
    child: ScreenUtilInit(
      designSize: const Size(1920, 1080),
      builder: (_, _) => MaterialApp(
        locale: context.locale,
        supportedLocales: context.supportedLocales,
        localizationsDelegates: context.localizationDelegates,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        theme: ThemeData.dark().copyWith(
          textTheme: ThemeData.dark().textTheme.apply(fontFamily: 'Tajawal'),
          scaffoldBackgroundColor: AppColors.scaffoldBackground,
        ),
        home: SessionClockHost(
          clock: () => fixtureNow,
          child: Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'PLAYSPOT  /  EQUIPMENT PREVIEW',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Synthetic fixture · no hosted connection · closing is not collection',
                    style: TextStyle(color: Colors.blueGrey),
                  ),
                  const SizedBox(height: 24),
                  LayoutBuilder(
                    builder: (context, c) {
                      final cols = (c.maxWidth / 320).floor().clamp(1, 6);
                      final width = (c.maxWidth - (cols - 1) * 16) / cols;
                      final count =
                          stationCount ??
                          int.tryParse(
                            Uri.base.queryParameters['stations'] ?? '7',
                          ) ??
                          7;
                      return Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: List.generate(
                          count.clamp(1, 40),
                          (i) => RoomOccupancyCard(
                            room: fixtureRoom(i),
                            loungeId: 'fixture',
                            width: width,
                            activeBooking: i % 7 < 2 ? fixtureBooking(i) : null,
                            isStale:
                                isStale ||
                                Uri.base.queryParameters['stale'] == 'true',
                            isRefreshing:
                                isRefreshing ||
                                Uri.base.queryParameters['loading'] == 'true',
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
