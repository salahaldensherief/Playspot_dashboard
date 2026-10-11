import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:play_spot_dashboard/features/users/data/datasources/admin_management_remote_data_source.dart';
import 'package:play_spot_dashboard/features/users/data/repositories/admin_management_repository_impl.dart';
import 'package:play_spot_dashboard/features/users/domain/usecases/create_lounge_admin_usecase.dart';
import 'package:play_spot_dashboard/features/users/domain/usecases/delete_admin_usecase.dart';
import 'package:play_spot_dashboard/features/users/domain/usecases/get_admins_usecase.dart';
import 'package:play_spot_dashboard/features/users/domain/usecases/update_admin_usecase.dart';
import 'package:play_spot_dashboard/features/users/presentation/cubit/admin_management_cubit.dart';
import 'package:play_spot_dashboard/features/users/presentation/cubit/admin_management_state.dart';

void main() {
  late SupabaseClient client;
  late AdminManagementRemoteDataSourceImpl source;
  late AdminManagementCubit cubit;
  Object? response;
  int status = 200;
  int requests = 0;
  final urls = <Uri>[];
  setUp(() {
    response = [];
    status = 200;
    requests = 0;
    urls.clear();
    client = SupabaseClient(
      'https://fixture.invalid',
      'synthetic-public-key',
      httpClient: MockClient((request) async {
        requests++;
        urls.add(request.url);
        return http.Response(
          jsonEncode(response),
          status,
          request: request,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
    source = AdminManagementRemoteDataSourceImpl(client);
    final repository = AdminManagementRepositoryImpl(source);
    cubit = AdminManagementCubit(
      createLoungeAdminUseCase: CreateLoungeAdminUseCase(repository),
      getAdminsUseCase: GetAdminsUseCase(repository),
      deleteAdminUseCase: DeleteAdminUseCase(repository),
      updateAdminUseCase: UpdateAdminUseCase(repository),
    );
  });
  tearDown(() async {
    await cubit.close();
    await client.dispose();
  });
  for (final code in [403, 503]) {
    test('$code is a failure without a broader second query', () async {
      status = code;
      response = {'message': 'synthetic failure', 'code': '42501'};
      await expectLater(source.getAdmins(), throwsA(isA<PostgrestException>()));
      expect(requests, code == 403 ? 1 : greaterThan(0));
      expect(urls.map((url) => url.toString()).toSet(), hasLength(1));
    });
  }
  test('malformed success propagates parsing failure', () async {
    response = {'unexpected': true};
    await expectLater(source.getAdmins(), throwsA(isA<TypeError>()));
    expect(requests, 1);
  });
  test('legitimate empty list remains successful', () async {
    await cubit.fetchAdmins();
    expect(cubit.state.status, AdminManagementStatus.success);
    expect(cubit.state.admins, isEmpty);
    expect(urls.single.path, '/rest/v1/profiles');
    expect(urls.single.queryParameters['role'], 'neq.inactive');
    expect(urls.single.queryParameters['order'], 'full_name.desc.nullslast');
    expect(urls.single.queryParameters['select'], isNot(contains('*')));
  });
  test('failure reaches Cubit and retry restores actual users', () async {
    status = 403;
    response = {'message': 'synthetic denial', 'code': '42501'};
    await cubit.fetchAdmins();
    expect(cubit.state.status, AdminManagementStatus.failure);
    expect(cubit.state.errorMessage, isNotNull);
    status = 200;
    response = [
      {'id': 'synthetic-user', 'full_name': 'Fixture', 'role': 'owner'},
      {'id': 'disabled-user', 'role': 'owner', 'is_active': false},
    ];
    await cubit.fetchAdmins();
    expect(cubit.state.status, AdminManagementStatus.success);
    expect(cubit.state.admins.single.id, 'synthetic-user');
    expect(cubit.state.errorMessage, isNull);
    expect(requests, 2);
  });
}
