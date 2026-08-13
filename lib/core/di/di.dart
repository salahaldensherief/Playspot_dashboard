import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:play_spot_dashboard/core/audio/audio_service.dart';
import 'package:play_spot_dashboard/core/services/storage_service.dart';
import 'package:play_spot_dashboard/core/services/location_service.dart';

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

final sl = GetIt.instance;

Future<void> setupInjection() async {
  await Supabase.initialize(
    url: 'https://tgpdexoitemmpruepgyt.supabase.co',
    anonKey:
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRncGRleG9pdGVtbXBydWVwZ3l0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzg2NjYyNzYsImV4cCI6MjA5NDI0MjI3Nn0.i5ekdw4CkWh97-BGWzCRQZ4c9bIKWIo2vD-Ev58BVC4',
  );

  // Register Supabase Client
  sl.registerLazySingleton<SupabaseClient>(
        () => Supabase.instance.client,
  );

  // Core Services
  sl.registerLazySingleton<AudioService>(() => AudioServiceImpl());
  sl.registerLazySingleton<StorageService>(() => StorageServiceImpl(sl()));
  sl.registerLazySingleton<LocationService>(() => LocationServiceImpl());

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
}
