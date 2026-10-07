import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
import 'package:play_spot_dashboard/features/categories/domain/entities/activity_type_entity.dart';
import 'package:play_spot_dashboard/features/categories/presentation/categories/widgets/activity_type_dialog.dart';
import '../../support/local_translations_loader.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });
  testWidgets('failed activity save keeps the form and prevents duplicate pending writes', (tester) async {
    tester.view.physicalSize = const Size(1440, 1024);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final pending = Completer<ActivityTypeEntity?>();
    var calls = 0;
    const activity = ActivityTypeEntity(id:'activity',name:'table_tennis',label:'Table Tennis',
      category:'table_sport',iconName:'sports_tennis',requiresScreen:false,requiresControllers:false);
    await tester.pumpWidget(EasyLocalization(
      supportedLocales:const [Locale('en'),Locale('ar')],path:'assets/translations',
      startLocale:const Locale('en'),assetLoader:const LocalTranslationsLoader(),
      child:Builder(builder:(context)=>ScreenUtilInit(designSize:const Size(1440,1024),
        builder:(_,__)=>MaterialApp(locale:context.locale,supportedLocales:context.supportedLocales,
          localizationsDelegates:context.localizationDelegates,
          home:Scaffold(body:ActivityTypeDialog(activity:activity,onSave:(value) {
            calls++; expect(value.name,activity.name); expect(value.pricingModel,'per_room_hour');
            expect(value.requiresScreen,isFalse); return pending.future;
          })))))));
    await tester.pumpAndSettle();
    final save = find.byWidgetPredicate((widget) => widget is AppButton && widget.text == AppStrings.save);
    await tester.tap(save); await tester.pump();
    expect(calls,1);
    expect(tester.widget<AppButton>(save).onPressed,isNull);
    pending.complete(null); await tester.pumpAndSettle();
    expect(find.byType(ActivityTypeDialog),findsOneWidget);
    expect(find.text('Table Tennis'),findsOneWidget);
    expect(find.text(AppStrings.actionFailed),findsOneWidget);
    expect(tester.takeException(),isNull);
  });
}
