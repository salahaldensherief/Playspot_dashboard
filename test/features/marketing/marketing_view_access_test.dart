import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/features/auth/domain/entities/user_entity.dart';
import 'package:play_spot_dashboard/features/auth/presentation/login/login_cubit.dart';
import 'package:play_spot_dashboard/features/auth/presentation/login/login_state.dart';
import 'package:play_spot_dashboard/features/marketing/domain/entities/promo_entity.dart';
import 'package:play_spot_dashboard/features/marketing/presentation/cubit/marketing_cubit.dart';
import 'package:play_spot_dashboard/features/marketing/presentation/cubit/marketing_state.dart';
import 'package:play_spot_dashboard/features/marketing/presentation/widgets/marketing_view.dart';
import 'package:play_spot_dashboard/features/permissions/presentation/cubit/permissions_cubit.dart';
import 'package:play_spot_dashboard/features/permissions/presentation/cubit/permissions_state.dart';
import 'package:play_spot_dashboard/features/rooms/presentation/cubit/room_cubit.dart';
import 'package:play_spot_dashboard/features/rooms/presentation/cubit/room_state.dart';
import '../../support/local_translations_loader.dart';

class _Auth extends Mock implements LoginCubit {}
class _Marketing extends Mock implements MarketingCubit {}
class _Permissions extends Mock implements PermissionsCubit {}
class _Rooms extends Mock implements RoomCubit {}

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  testWidgets('owner sees global offers without mutation controls or selector assertions', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final auth = _Auth();
    final marketing = _Marketing();
    final permissions = _Permissions();
    final rooms = _Rooms();
    const user = UserEntity(id: 'owner', email: '', name: '', role: UserRole.owner, loungeId: 'venue');
    const globalOffer = PromoEntity(id: 'global', titleAr: 'عرض عام', titleEn: 'Platform offer', tagAr: '', tagEn: '', hexColors: ['#000000', '#ffffff'], iconKey: 'Flash');
    const localOffer = PromoEntity(id: 'local', titleAr: 'عرض الصالة', titleEn: 'Venue offer', tagAr: '', tagEn: '', hexColors: ['#000000', '#ffffff'], iconKey: 'Flash', loungeId: 'venue');
    final expiredGlobal = PromoEntity(id: 'expired-global', titleAr: 'عام منتهي', titleEn: 'Expired platform offer', tagAr: '', tagEn: '', hexColors: const ['#000000', '#ffffff'], iconKey: 'Flash', expiresAt: DateTime(2020));
    final expiredLocal = PromoEntity(id: 'expired-local', titleAr: 'عرض منتهي', titleEn: 'Expired venue offer', tagAr: '', tagEn: '', hexColors: const ['#000000', '#ffffff'], iconKey: 'Flash', loungeId: 'venue', expiresAt: DateTime(2020));
    when(() => auth.state).thenReturn(const LoginState(status: LoginStatus.authenticated, user: user));
    when(() => auth.stream).thenAnswer((_) => const Stream<LoginState>.empty());
    when(() => marketing.state).thenReturn(MarketingState(status: MarketingStatus.success, promotions: [globalOffer, localOffer, expiredGlobal, expiredLocal]));
    when(() => marketing.stream).thenAnswer((_) => const Stream<MarketingState>.empty());
    when(() => permissions.state).thenReturn(PermissionsState.initial());
    when(() => permissions.stream).thenAnswer((_) => const Stream<PermissionsState>.empty());
    when(() => rooms.state).thenReturn(const RoomState());
    when(() => rooms.stream).thenAnswer((_) => const Stream<RoomState>.empty());
    when(() => permissions.hasPermission('marketing_manage', userRole: 'owner', userId: 'owner')).thenReturn(true);
    when(() => marketing.loadPromotions(loungeId: 'venue')).thenAnswer((_) async {});
    await tester.pumpWidget(EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('ar')], startLocale: const Locale('en'), saveLocale: false,
      path: 'assets/translations', assetLoader: const LocalTranslationsLoader(),
      child: ScreenUtilInit(designSize: const Size(1440, 900), builder: (context, _) => MaterialApp(
        locale: context.locale, supportedLocales: context.supportedLocales, localizationsDelegates: context.localizationDelegates,
        home: MultiBlocProvider(providers: [
          BlocProvider<LoginCubit>.value(value: auth), BlocProvider<MarketingCubit>.value(value: marketing),
          BlocProvider<PermissionsCubit>.value(value: permissions), BlocProvider<RoomCubit>.value(value: rooms),
        ], child: const Scaffold(body: MarketingView())),
      )),
    ));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Platform offer'), findsOneWidget);
    expect(find.text('Venue offer'), findsOneWidget);
    expect(find.byIcon(Icons.archive_outlined), findsOneWidget);
    expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
    expect(find.byIcon(Icons.repeat_rounded), findsOneWidget);
    expect(find.text('Expired platform offer'), findsNothing);
    expect(find.text('Expired venue offer'), findsNothing);
    await tester.tap(find.text(AppStrings.timeExpired));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Expired platform offer'), findsOneWidget);
    expect(find.text('Expired venue offer'), findsOneWidget);
    expect(find.byIcon(Icons.archive_outlined), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
