import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:play_spot_dashboard/core/services/local_cache_service_impl.dart';
import '../../support/mock_cache_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SharedPreferences prefs;
  late LocalCacheServiceImpl cache;
  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'cache_rooms_hall': '[1]',
      'cache_onboarding_lounge_draft_v1': '{"contactPhone":"synthetic"}',
      'audio_enabled': true,
      'language': 'ar',
      'sb-another-project-auth-token': 'synthetic-session',
      'cache_': 'unowned',
    });
    prefs = await SharedPreferences.getInstance();
    cache = LocalCacheServiceImpl(prefs);
  });

  test(
    'logout removes only application cache and retains other settings',
    () async {
      await cache.clearAll();
      expect(prefs.getKeys(), {
        'audio_enabled',
        'language',
        'sb-another-project-auth-token',
        'cache_',
      });
      expect(prefs.getBool('audio_enabled'), true);
      expect(
        prefs.getString('sb-another-project-auth-token'),
        'synthetic-session',
      );
    },
  );

  test(
    'owned key whitespace normalizes across write read and removal',
    () async {
      await cache.setJson(' cache_new ', {'value': 3});
      expect(cache.getJson(' cache_new '), {'value': 3});
      await cache.remove(' cache_new ');
      expect(cache.getJson('cache_new'), isNull);
    },
  );

  test('arbitrary keys cannot overwrite or remove settings and auth', () async {
    for (final key in [
      'audio_enabled',
      'sb-another-project-auth-token',
      '',
      'cache_',
    ]) {
      await cache.setJson(key, {'overwrite': true});
      await cache.remove(key);
      expect(cache.getJson(key), isNull);
    }
    expect(prefs.getBool('audio_enabled'), true);
    expect(
      prefs.getString('sb-another-project-auth-token'),
      'synthetic-session',
    );
    expect(prefs.getString('cache_'), 'unowned');
  });

  test(
    'malformed and nonstring cache return empty without destructive cleanup',
    () async {
      await prefs.setString('cache_invalid', 'invalid-json');
      await prefs.setBool('cache_type', false);
      expect(cache.getJson('cache_invalid'), isNull);
      expect(cache.getJson('cache_type'), isNull);
      expect(prefs.getString('cache_invalid'), 'invalid-json');
      await cache.setJson('cache_invalid', {'fresh': true});
      expect(cache.getJson('cache_invalid'), {'fresh': true});
    },
  );

  test('clear drains an already pending cache write', () async {
    final mock = MockCachePreferences();
    final saved = <String>{};
    final gate = Completer<bool>();
    when(() => mock.setString('cache_delayed', '[1]')).thenAnswer((_) async {
      final result = await gate.future;
      saved.add('cache_delayed');
      return result;
    });
    when(mock.getKeys).thenAnswer((_) => saved.toSet());
    when(() => mock.remove('cache_delayed')).thenAnswer((_) async {
      saved.remove('cache_delayed');
      return true;
    });
    final service = LocalCacheServiceImpl(mock);
    final writing = service.setJson('cache_delayed', [1]);
    final clearing = service.clearAll();
    await Future<void>.delayed(Duration.zero);
    verifyNever(() => mock.remove(any()));
    gate.complete(true);
    await Future.wait([writing, clearing]);
    expect(saved, isEmpty);
    verify(() => mock.remove('cache_delayed')).called(1);
  });

  test('failed removal is observable and does not poison the queue', () async {
    final mock = MockCachePreferences();
    when(mock.getKeys).thenReturn({'cache_owned'});
    when(() => mock.remove('cache_owned')).thenAnswer((_) async => false);
    final service = LocalCacheServiceImpl(mock);
    await expectLater(service.clearAll(), throwsStateError);
    when(() => mock.remove('cache_owned')).thenAnswer((_) async => true);
    await service.clearAll();
    verifyNever(mock.clear);
  });

  test(
    'platform cleanup exceptions are localized and optional remove stays safe',
    () async {
      final mock = MockCachePreferences();
      when(mock.getKeys).thenReturn({'cache_owned'});
      when(() => mock.remove('cache_owned')).thenThrow(Exception('synthetic'));
      final service = LocalCacheServiceImpl(mock);
      await expectLater(
        service.clearAll(),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'localization key',
            'cache.remove_failed',
          ),
        ),
      );
      await service.remove('cache_owned');
      verifyNever(mock.clear);
    },
  );
}
