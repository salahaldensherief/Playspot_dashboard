import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'core/di/di.dart' as di;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Removes the '#' from the URL to make it look like a standard website
  usePathUrlStrategy();

  // Ensures the screen size is initialized for Flutter Web to prevent "no size" errors
  await ScreenUtil.ensureScreenSize();

  await EasyLocalization.ensureInitialized();
  await di.setupInjection();

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('ar')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      child: const MyApp(),
    ),
  );
}
