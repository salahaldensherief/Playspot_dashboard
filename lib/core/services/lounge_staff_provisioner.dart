import 'dart:convert';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../art_core/exceptions/app_exceptions.dart';
import '../utils/serialized_task_queue.dart';
import 'play_spot_secure_storage.dart';

class LoungeStaffProvisioner {
  final SupabaseClient client;
  final FlutterSecureStorage storage;
  final String? Function() actorId;
  static final _queues = Expando<SerializedTaskQueue>();
  LoungeStaffProvisioner(
    this.client, {
    this.storage = PlaySpotSecureStorage.instance,
    String? Function()? actorId,
  }) : actorId = actorId ?? (() => client.auth.currentUser?.id);

  Future<void> create(Map<String, dynamic> body) =>
      (_queues[client] ??= SerializedTaskQueue()).run(() => _create(body));

  Future<void> _create(Map<String, dynamic> body) async {
    final actor = actorId();
    final scope =
        'staff_provisioning:${Uri.encodeComponent(client.rest.url)}:$actor';
    final key = jsonEncode([body['email'], body['lounge_id'], body['role']]);
    final fields = Map<String, dynamic>.from(body)..remove('password');
    final saved = actor == null ? null : await storage.read(key: scope);
    final pending = saved == null
        ? <String, dynamic>{}
        : Map<String, dynamic>.from(jsonDecode(saved) as Map);
    final recovery = pending[key];
    if (recovery is Map &&
        jsonEncode(recovery['fields']) != jsonEncode(fields)) {
      throw ServerException('staff_creation_retry_original_details'.tr());
    }
    final request = {
      ...body,
      if (recovery is Map) 'recovery_user_id': recovery['id'],
    };
    try {
      final response = await client.functions.invoke(
        'create-lounge-staff',
        body: request,
      );
      if (actorId() != actor) {
        throw ServerException('staff_creation_unconfirmed'.tr());
      }
      final result = response.data;
      if (response.status < 200 ||
          response.status >= 300 ||
          result is! Map ||
          result['success'] != true ||
          result['user_id'] is! String ||
          (result['user_id'] as String).isEmpty ||
          result['role'] != body['role'] ||
          (recovery is Map && result['user_id'] != recovery['id'])) {
        throw ServerException('staff_creation_unconfirmed'.tr());
      }
      if (actor != null && pending.remove(key) != null) {
        await storage.write(key: scope, value: jsonEncode(pending));
      }
    } on FunctionException catch (error) {
      final details = error.details;
      if (details is Map &&
          details['provisioning_confirmed'] == false &&
          details['recovery_user_id'] is String &&
          (details['recovery_user_id'] as String).isNotEmpty &&
          actor != null) {
        pending[key] = {'id': details['recovery_user_id'], 'fields': fields};
        final value = jsonEncode(pending);
        await storage.write(key: scope, value: value);
        if (await storage.read(key: scope) != value) {
          throw ServerException('staff_creation_unconfirmed'.tr());
        }
        throw ServerException('staff_creation_retry_original_details'.tr());
      }
      rethrow;
    }
  }
}
