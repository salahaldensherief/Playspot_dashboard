import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:play_spot_dashboard/features/onboarding/data/datasources/onboarding_remote_data_source_impl.dart';

void main() {
  final draft = <String, dynamic>{
    'lounge': {
      'id': 'lounge-1',
      'name': 'Venue',
      'city': 'Cairo',
      'address': 'Corrected street',
      'contact_phone': '01000000000',
      'opening_time': '10:00:00',
      'closing_time': '02:00:00',
      'image_url': 'https://example.invalid/venue.jpg',
      'instapay_account': 'synthetic@instapay',
      'location_point': {
        'type': 'Point',
        'coordinates': [31.2, 30.0],
      },
    },
    'rooms': [
      {
        'id': 'room-stable',
        'lounge_id': 'lounge-1',
        'name': 'Room',
        'hourly_rate_single': 60,
        'hourly_rate_multi': 90,
        'max_capacity': 4,
      },
    ],
    'extras': [
      {
        'id': 'extra-stable',
        'lounge_id': 'lounge-1',
        'name': 'Water',
        'price': 15,
      },
    ],
    'review_notes': 'Clarify address',
  };
  SupabaseClient clientFor(
    Object body, {
    void Function(http.Request)? inspect,
  }) {
    final client = SupabaseClient(
      'https://example.invalid',
      'fixture-key',
      httpClient: MockClient((request) async {
        inspect?.call(request);
        return http.Response(
          jsonEncode(body),
          200,
          headers: {'content-type': 'application/json'},
          request: request,
        );
      }),
    );
    addTearDown(client.dispose);
    return client;
  }

  test(
    'restores saved fields, coordinates, photos and stable resources through exact owner RPC',
    () async {
      final client = clientFor(
        draft,
        inspect: (request) {
          expect(request.url.path, '/rest/v1/rpc/get_my_onboarding_draft');
          expect(jsonDecode(request.body), {'p_lounge_id': 'lounge-1'});
        },
      );
      final saved = await OnboardingRemoteDataSourceImpl(
        client,
      ).getSavedDraft('lounge-1');
      expect(saved.fields.address, 'Corrected street');
      expect(saved.fields.contactPhone, '01000000000');
      expect(saved.fields.opensAt, '10:00');
      expect(saved.fields.closesAt, '02:00');
      expect(saved.fields.lat, 30);
      expect(saved.fields.lng, 31.2);
      expect(saved.fields.instapayAccount, 'synthetic@instapay');
      expect(saved.lounge.imageUrl, 'https://example.invalid/venue.jpg');
      expect(saved.rooms.single.id, 'room-stable');
      expect(saved.rooms.single.hourlyRateSingle, 60);
      expect(saved.extras.single.id, 'extra-stable');
      expect(saved.reviewNotes, 'Clarify address');
    },
  );
  test(
    'another lounge response is rejected before importing its data',
    () async {
      await expectLater(
        OnboardingRemoteDataSourceImpl(
          clientFor(draft),
        ).getSavedDraft('different-lounge'),
        throwsFormatException,
      );
    },
  );
  test('malformed draft cannot be reported as restored', () async {
    await expectLater(
      OnboardingRemoteDataSourceImpl(
        clientFor({
          'lounge': {'id': 'lounge-1'},
        }),
      ).getSavedDraft('lounge-1'),
      throwsFormatException,
    );
  });
}
