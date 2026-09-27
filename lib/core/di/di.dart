import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:play_spot_dashboard/core/audio/audio_service.dart';
import 'package:play_spot_dashboard/core/constants/app_constants.dart';
import 'package:play_spot_dashboard/core/services/storage_service.dart';
import 'package:play_spot_dashboard/core/services/location_service.dart';
import 'package:play_spot_dashboard/core/services/local_cache_service.dart';
import 'package:play_spot_dashboard/core/services/hardware_bridge_service.dart';

import 'package:play_spot_dashboard/features/auth/auth_di.dart';
import 'package:play_spot_dashboard/features/bookings/bookings_di.dart';
import 'package:play_spot_dashboard/features/lounges/lounges_di.dart';
import 'package:play_spot_dashboard/features/rooms/rooms_di.dart';
import 'package:play_spot_dashboard/features/onboarding/onboarding_di.dart';
import 'package:play_spot_dashboard/features/users/users_di.dart';
import 'package:play_spot_dashboard/features/categories/categories_di.dart';
import 'package:play_spot_dashboard/features/analytics/analytics_di.dart';
import 'package:play_spot_dashboard/features/marketing/marketing_di.dart';
import 'package:play_spot_dashboard/features/payouts/payouts_di.dart';
import 'package:play_spot_dashboard/features/kyc/kyc_di.dart';
import 'package:play_spot_dashboard/features/loyalty/loyalty_di.dart';
import 'package:play_spot_dashboard/features/shifts/shifts_di.dart';
import 'package:play_spot_dashboard/features/staff/staff_di.dart';
import 'package:play_spot_dashboard/features/permissions/permissions_di.dart';
import 'package:play_spot_dashboard/features/requests/requests_di.dart';
import 'package:play_spot_dashboard/features/reviews/reviews_di.dart';
import 'package:play_spot_dashboard/features/tournaments/tournaments_di.dart';
import 'package:play_spot_dashboard/features/support/support_di.dart';
import 'package:play_spot_dashboard/features/system/system_di.dart';

final sl = GetIt.instance;

Future<void> setupInjection() async {
  if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
    throw StateError(
      'Missing SUPABASE_URL or SUPABASE_ANON_KEY. '
      'Pass them with --dart-define at build/run time.',
    );
  }

  await Supabase.initialize(url: supabaseUrl, publishableKey: supabaseAnonKey);

  // Register Supabase Client
  sl.registerLazySingleton<SupabaseClient>(() => Supabase.instance.client);

  // Core Services
  final prefs = await SharedPreferences.getInstance();
  sl.registerSingleton<SharedPreferences>(prefs);
  sl.registerLazySingleton<LocalCacheService>(
    () => LocalCacheServiceImpl(sl()),
  );

  sl.registerLazySingleton<AudioService>(() => AudioServiceImpl());
  sl.registerLazySingleton<StorageService>(() => StorageServiceImpl(sl()));
  sl.registerLazySingleton<LocationService>(() => LocationServiceImpl());
  sl.registerLazySingleton<HardwareBridgeService>(
    () => HardwareBridgeService(),
  );

  // Initialize Feature DI Modules
  initAuthDI(sl);
  initLoungesDI(sl);
  initRoomsDI(sl);
  initBookingsDI(sl);
  initOnboardingDI(sl);
  initUsersDI(sl);
  initCategoriesDI(sl);
  initAnalyticsDI(sl);
  initMarketingDI(sl);
  initPayoutsDI(sl);
  initKycDI(sl);
  initLoyaltyDI(sl);
  initShiftsDI(sl);
  initStaffDI(sl);
  initPermissionsDI(sl);
  initRequestsDI(sl);
  initReviewsDI(sl);
  initTournamentsDI(sl);
  initSupportDI(sl);
  initSystemDI(sl);
}
