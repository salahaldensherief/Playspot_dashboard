import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/di/di.dart' as di;
import 'art_core/router/app_router.dart';
import 'art_core/theme/app_colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await di.setupInjection();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'PlaySpot Dashboard',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: AppColors.scaffoldBackground,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.neonBlue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        fontFamily: 'Orbitron'
      ),
      routerConfig: AppRouter.router,
    );
  }
}
