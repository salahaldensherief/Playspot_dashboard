/// Overridable at build time via --dart-define=SUPABASE_URL=...
const String supabaseUrl = String.fromEnvironment(
  'SUPABASE_URL',
  defaultValue: 'https://tgpdexoitemmpruepgyt.supabase.co',
);

/// Overridable at build time via --dart-define=SUPABASE_ANON_KEY=...
const String supabaseAnonKey = String.fromEnvironment(
  'SUPABASE_ANON_KEY',
  defaultValue:
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRncGRleG9pdGVtbXBydWVwZ3l0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzg2NjYyNzYsImV4cCI6MjA5NDI0MjI3Nn0.i5ekdw4CkWh97-BGWzCRQZ4c9bIKWIo2vD-Ev58BVC4',
);

class AppConstants {
  // Log Messages
  static const String bookingFetchAlert =
      'Booking Fetch Alert: RPC skipped or failed, using safe select. Error: ';
  static const String geocodingFailed =
      'Geocoding setLocaleIdentifier failed: ';
  static const String locationCaptureSuccess =
      'Successfully captured and updated lounge location and city: ';
  static const String locationCaptureError = 'Error capturing location: ';
  static const String currentPositionError = 'Error getting current position: ';
  static const String cityFromPositionError =
      'Error getting city from position: ';
  static const String criticalFallbackError =
      'Critical: Fallback select also failed: ';
}
