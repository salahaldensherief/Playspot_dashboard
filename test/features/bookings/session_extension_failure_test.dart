import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
import 'package:play_spot_dashboard/features/analytics/presentation/dashboard_cubit.dart';
import 'package:play_spot_dashboard/features/analytics/presentation/dashboard_state.dart';
import 'package:play_spot_dashboard/features/bookings/domain/entities/booking.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/cubit/booking_cubit.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/cubit/booking_state.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/widgets/extend_session_dialog.dart';
import '../../support/local_translations_loader.dart';

class _Dashboard extends Mock implements DashboardCubit {}
class _Bookings extends Mock implements BookingCubit {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });
  testWidgets('failed extension keeps dialog open without fallback or success', (tester) async {
    tester.view.physicalSize = const Size(1000,1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final dashboard=_Dashboard(),bookings=_Bookings();
    when(()=>dashboard.state).thenReturn(const DashboardState());
    when(()=>dashboard.stream).thenAnswer((_)=>const Stream.empty());
    when(()=>bookings.state).thenReturn(const BookingState());
    when(()=>bookings.stream).thenAnswer((_)=>const Stream.empty());
    when(()=>dashboard.extendSession('booking',30)).thenAnswer((_) async=>false);
    final booking=Booking(id:'booking',userId:'user',loungeId:'lounge',roomId:'room',
      date:DateTime(2026),startTime:'18:00',endTime:'19:00',status:BookingStatus.inProgress,totalPrice:80);
    await tester.pumpWidget(EasyLocalization(
      supportedLocales:const [Locale('en'),Locale('ar')],startLocale:const Locale('en'),
      saveLocale:false,path:'assets/translations',assetLoader:const LocalTranslationsLoader(),
      child:ScreenUtilInit(designSize:const Size(1440,900),builder:(context,child)=>MaterialApp(
        locale:context.locale,supportedLocales:context.supportedLocales,
        localizationsDelegates:context.localizationDelegates,
        home:MultiBlocProvider(providers:[BlocProvider<DashboardCubit>.value(value:dashboard),
          BlocProvider<BookingCubit>.value(value:bookings)],
          child:Scaffold(body:ExtendSessionDialog(booking:booking))),
      )),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(AppButton).last);
    await tester.pumpAndSettle();
    expect(find.byType(ExtendSessionDialog),findsOneWidget);
    expect(find.text('Could not extend the session. Refresh the booking and try again.'),findsOneWidget);
    verify(()=>dashboard.extendSession('booking',30)).called(1);
    verifyNever(()=>bookings.extendBookingDuration(any(),any()));
    verifyNever(()=>bookings.startWatchingBookings(loungeId:any(named:'loungeId'),forceRefresh:true));
  });
}
