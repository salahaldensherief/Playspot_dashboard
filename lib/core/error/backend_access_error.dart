import 'package:supabase_flutter/supabase_flutter.dart';

/// Authorization errors must never trigger a compatibility table lookup.
bool isBackendAccessDenied(Object error) {
  if (error is! PostgrestException) return false;
  if (const {
    '42501',
    '28000',
    '28P01',
    'PGRST301',
    'PGRST302',
    'PGRST303',
  }.contains(error.code)) {
    return true;
  }
  final message = error.message.toLowerCase();
  return message.contains('not authorized') ||
      message.contains('unauthorized') ||
      message.contains('permission denied') ||
      message.contains('access denied');
}
