import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Strategy class to execute sequential storage bucket upload attempts with fallback support.
class BucketUploadStrategy {
  final SupabaseClient _supabase;

  BucketUploadStrategy(this._supabase);

  Future<String> uploadWithFallback({
    required List<String> buckets,
    required String path,
    required Uint8List fileBytes,
    required String userErrorMessage,
    FileOptions fileOptions = const FileOptions(cacheControl: '3600', upsert: false),
  }) async {
    for (int i = 0; i < buckets.length; i++) {
      final bucket = buckets[i];
      try {
        await _supabase.storage.from(bucket).uploadBinary(
          path,
          fileBytes,
          fileOptions: fileOptions,
        );
        return _supabase.storage.from(bucket).getPublicUrl(path);
      } catch (e) {
        final errStr = e.toString().toLowerCase();
        if (errStr.contains('network') || errStr.contains('socket') || errStr.contains('connection')) {
          throw Exception('تعذر الاتصال بالخادم. يرجى التحقق من الاتصال بالإنترنت وإعادة المحاولة.');
        } else if (errStr.contains('401') || errStr.contains('jwt') || errStr.contains('unauthorized')) {
          throw Exception('انتهت صلاحية الجلسة. يرجى إعادة تسجيل الدخول والتجربة مرة أخرى.');
        }
        debugPrint('⚠️ [BUCKET_STRATEGY] Upload to bucket "$bucket" failed ($e). ${i < buckets.length - 1 ? "Attempting fallback bucket..." : "All bucket attempts failed."}');
      }
    }
    throw Exception(userErrorMessage);
  }
}
