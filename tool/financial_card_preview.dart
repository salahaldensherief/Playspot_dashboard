import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/features/bookings/domain/entities/booking.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/widgets/booking_financials_card.dart';

/// Local visual fixture only. Does not initialize Auth, DI, or Supabase.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  final language = Uri.base.queryParameters['lang'] == 'ar' ? 'ar' : 'en';
  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('ar')],
      startLocale: Locale(language),
      saveLocale: false,
      path: 'assets/translations',
      child: const _Preview(),
    ),
  );
}

class _Preview extends StatelessWidget {
  const _Preview();

  @override
  Widget build(BuildContext context) => ScreenUtilInit(
    designSize: const Size(1920, 1080),
    builder: (_, _) => MaterialApp(
      theme: ThemeData.dark(),
      locale: context.locale,
      supportedLocales: context.supportedLocales,
      localizationsDelegates: context.localizationDelegates,
      home: Scaffold(
        body: SingleChildScrollView(
          child: Center(
            child: SizedBox(
              width: 360,
              child: MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(1.6)),
                child: BookingFinancialsCard(
                  booking: Booking(
                    id: 'synthetic-preview',
                    userId: 'customer',
                    loungeId: 'branch',
                    roomId: 'room',
                    date: DateTime(2030, 1, 10),
                    startTime: '14:00',
                    endTime: '15:00',
                    status: BookingStatus.cancelled,
                    paymentStatus: PaymentStatus.refunded,
                    paymentMethod: 'cash',
                    totalPrice: 100,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
