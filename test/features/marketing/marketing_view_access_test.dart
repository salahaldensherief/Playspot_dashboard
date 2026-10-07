import 'package:bloc_test/bloc_test.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

class _Auth extends MockCubit<LoginState> implements LoginCubit {}
class _Marketing extends MockCubit<MarketingState> implements MarketingCubit {}
class _Permissions extends MockCubit<PermissionsState> implements PermissionsCubit {}
class _Rooms extends MockCubit<RoomState> implements RoomCubit {}

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
    whenListen(auth, const Stream<LoginState>.empty(), initialState: const LoginState(status: LoginStatus.authenticated, user: user));
    whenListen(marketing, const Stream<MarketingState>.empty(), initialState: const MarketingState(status: MarketingStatus.success, promotions: [globalOffer, localOffer]));
    whenListen(permissions, const Stream<PermissionsState>.empty(), initialState: PermissionsState.initial());
    whenListen(rooms, const Stream<RoomState>.empty(), initialState: const RoomState());
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
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
