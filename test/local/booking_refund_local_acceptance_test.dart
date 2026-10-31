// Opt-in real loopback Supabase acceptance, never hosted or browser UI evidence.
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:play_spot_dashboard/features/bookings/data/repositories/booking_refund_repository_impl.dart';
import 'package:play_spot_dashboard/features/bookings/domain/repositories/booking_refund_repository.dart';

class _LoseAcknowledgement extends http.BaseClient {
  final http.Client inner = http.Client();
  bool loseNext = false;
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    if (request.url.origin != 'http://127.0.0.1:56821') {
      throw StateError('Non-loopback request forbidden');
    }
    final response = await inner.send(request);
    if (loseNext &&
        request.url.path.endsWith('execute_booking_refund') &&
        response.statusCode == 200) {
      loseNext = false;
      await response.stream.drain<void>();
      throw http.ClientException('Synthetic lost acknowledgement');
    }
    return response;
  }

  @override
  void close() {
    inner.close();
    super.close();
  }
}

void main() {
  final directory = Platform.environment['PLAYSPOT_LOCAL_TEST_DIR'];
  final report = Platform.environment['PLAYSPOT_LOCAL_TEST_REPORT'];
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'actual Dashboard repository: partial/full return, denial, lost ACK and reconciliation summary',
    () async {
      SharedPreferences.setMockInitialValues({});
      HttpOverrides.global = null;
      Future<dynamic> load(String name) async =>
          jsonDecode(await File('$directory/$name').readAsString());
      final status = await load('status.json') as Map<String, dynamic>;
      expect(status['API_URL'], 'http://127.0.0.1:56821');
      final db = Uri.parse(status['DB_URL']);
      expect(db.host, '127.0.0.1');
      expect(db.port, 56822);
      final accounts = await load('accounts.json') as List;
      final fixture =
          await load('business-fixture.json') as Map<String, dynamic>;
      final storage = await load('storage-state.json') as Map<String, dynamic>;
      final input =
          await load(
                Platform.environment['PLAYSPOT_LOCAL_TEST_INPUT'] ??
                    'refund-client-input.json',
              )
              as Map<String, dynamic>;
      final transport = _LoseAcknowledgement();
      final clients = <String, SupabaseClient>{};
      addTearDown(() async {
        for (final client in clients.values) {
          await client.dispose();
        }
        transport.close();
      });
      for (final name in ['owner', 'cashier', 'customer']) {
        final account =
            accounts.singleWhere((a) => a['persona'] == name) as Map;
        expect(
          (account['email'] as String).endsWith('@example.invalid'),
          isTrue,
        );
        final client = SupabaseClient(
          status['API_URL'],
          status['ANON_KEY'],
          authOptions: const AuthClientOptions(autoRefreshToken: false),
          httpClient: name == 'cashier' ? transport : _LoseAcknowledgement(),
        );
        clients[name] = client;
        try {
          await client.auth.signInWithPassword(
            email: account['email'],
            password: account['password'],
          );
        } catch (e) {
          fail(
            'Synthetic local Auth failed for $name: ${e.runtimeType}, HTTP ${e is AuthException ? e.statusCode : 'transport'} (credentials suppressed)',
          );
        }
        expect(client.auth.currentUser?.id, account['id']);
      }
      final owner = clients['owner']!,
          cashier = clients['cashier']!,
          customer = clients['customer']!;
      // Preserve prior bookings/holds. Choose a synthetic station never used by
      // this customer, rather than erasing a prior reserved capacity period.
      final priorBookings = await customer
          .from('bookings')
          .select('room_id')
          .eq('lounge_id', fixture['lounge'])
          .eq('user_id', fixture['customer'])
          .limit(1000);
      final used = priorBookings.map((r) => r['room_id']).toSet();
      final rooms = List<String>.from(fixture['rooms']);
      final room = rooms
          .take(rooms.length - 1)
          .where((id) => !used.contains(id))
          .first;
      final hold = await customer.rpc(
        'acquire_booking_hold',
        params: {
          'p_room_ids': [room],
          'p_start_at': input['start'],
          'p_end_at': input['end'],
          'p_hold_minutes': 10,
        },
      );
      final created = await customer.rpc(
        'create_my_booking_checkout',
        params: {
          'p_hold_token': hold['hold_token'],
          'p_room_requests': [
            {'room_id': room, 'play_mode': 'single', 'extra_controllers': 0},
          ],
          'p_extra_items': [],
          'p_voucher_code': null,
          'p_payment_method': 'cash',
          'p_sender_wallet_phone': null,
          'p_receipt_url': null,
        },
      );
      final booking = created['primary_booking_id'] as String,
          lounge = fixture['lounge'] as String,
          shift = storage['shift']['id'] as String;
      await cashier.rpc(
        'start_booking_session',
        params: {'p_booking_id': booking},
      );
      await cashier.rpc(
        'complete_booking_session',
        params: {'p_booking_id': booking, 'p_action_by': fixture['cashier']},
      );
      final cash = await cashier.rpc(
        'checkout_booking_cash_atomic',
        params: {
          'p_booking_id': booking,
          'p_shift_id': shift,
          'p_amount_minor': null,
          'p_operation_id': input['collectionOperation'],
        },
      );
      final ownerRepo = BookingRefundRepositoryImpl(owner, writesEnabled: true),
          cashierRepo = BookingRefundRepositoryImpl(
            cashier,
            writesEnabled: true,
          );
      var summary = await ownerRepo.summary(booking, lounge);
      final gross = summary.grossMinor;
      expect(gross, greaterThan(1));
      expect(summary.refundedMinor, 0);
      final collection = summary.movements.single.id;
      expect(collection, cash['movement_id']);
      final partial = gross ~/ 3;
      final requested = await ownerRepo.initiate(
        summary: summary,
        collectionId: collection,
        amountMinor: partial,
        reason: 'LOCAL SYNTHETIC client acceptance; no external funds',
        policyOverride: true,
      );
      expect(requested.moneyReturned, isFalse);
      summary = await cashierRepo.summary(booking, lounge);
      expect(summary.netMinor, gross);
      expect(summary.pendingMinor, partial);
      final request = summary.requests.single;
      // A customer may read their own summary, but cannot execute a cashier return.
      final customerRepo = BookingRefundRepositoryImpl(
        customer,
        writesEnabled: true,
      );
      await expectLater(
        customerRepo.execute(
          summary: summary,
          request: request,
          shiftId: shift,
          evidence: 'LOCAL-SYNTHETIC-DENIED',
        ),
        throwsA(isA<RefundFailure>()),
      );
      Future<void> grant(bool enabled) async {
        await owner.rpc(
          'set_staff_permission',
          params: {
            'p_lounge_id': lounge,
            'p_target_user_id': fixture['cashier'],
            'p_permission_key': 'billing_checkout',
            'p_is_enabled': enabled,
          },
        );
      }

      try {
        await grant(false);
        await expectLater(
          cashierRepo.execute(
            summary: summary,
            request: request,
            shiftId: shift,
            evidence: 'LOCAL-SYNTHETIC-REVOKED',
          ),
          throwsA(isA<RefundFailure>()),
        );
        expect((await ownerRepo.summary(booking, lounge)).refundedMinor, 0);
      } finally {
        await grant(true);
      }
      transport.loseNext = true;
      const evidence = 'LOCAL-SYNTHETIC-CASH-RETURN-NO-EXTERNAL-MONEY';
      await expectLater(
        cashierRepo.execute(
          summary: summary,
          request: request,
          shiftId: shift,
          evidence: evidence,
        ),
        throwsA(
          isA<RefundFailure>().having(
            (f) => f.kind,
            'kind',
            RefundFailureKind.uncertain,
          ),
        ),
      );
      final replay =
          await BookingRefundRepositoryImpl(
            cashier,
            writesEnabled: true,
          ).execute(
            summary: summary,
            request: request,
            shiftId: shift,
            evidence: evidence,
          );
      expect(replay.moneyReturned, isTrue);
      expect(replay.amountMinor, partial);
      summary = await ownerRepo.summary(booking, lounge);
      expect(summary.refundedMinor, partial);
      expect(summary.netMinor, gross - partial);
      // Same operation from concurrent identical tabs uses deterministic IDs and one request.
      final remaining = summary.remainingMinor;
      final concurrent = await Future.wait([
        ownerRepo
            .initiate(
              summary: summary,
              collectionId: collection,
              amountMinor: remaining,
              reason: 'LOCAL SYNTHETIC final return',
              policyOverride: true,
            )
            .then<Object>((v) => v)
            .catchError((Object e) => e),
        BookingRefundRepositoryImpl(owner, writesEnabled: true)
            .initiate(
              summary: summary,
              collectionId: collection,
              amountMinor: remaining,
              reason: 'LOCAL SYNTHETIC final return',
              policyOverride: true,
            )
            .then<Object>((v) => v)
            .catchError((Object e) => e),
      ]);
      expect(concurrent.whereType<RefundReceipt>(), hasLength(1));
      expect(
        concurrent.whereType<RefundFailure>().single.kind,
        RefundFailureKind.pending,
      );
      summary = await cashierRepo.summary(booking, lounge);
      final finalRequest = summary.requests.singleWhere(
        (r) => r.status == 'approved_pending_return',
      );
      final finalReceipt = await cashierRepo.execute(
        summary: summary,
        request: finalRequest,
        shiftId: shift,
        evidence: 'LOCAL-SYNTHETIC-FINAL-RETURN-NO-EXTERNAL-MONEY',
      );
      expect(finalReceipt.moneyReturned, true);
      final finalSummary = await cashierRepo.summary(booking, lounge);
      expect(finalSummary.grossMinor, gross);
      expect(finalSummary.refundedMinor, gross);
      expect(finalSummary.netMinor, 0);
      expect(finalSummary.pendingMinor, 0);
      expect(
        finalSummary.movements.where((m) => m.type == 'refund'),
        hasLength(2),
      );
      expect(finalSummary.requests, hasLength(2));
      if (report != null) {
        await File(report).writeAsString(
          jsonEncode({
            'environment': status['API_URL'],
            'booking': booking,
            'shift': shift,
            'grossMinor': gross,
            'refundedMinor': finalSummary.refundedMinor,
            'netMinor': finalSummary.netMinor,
            'refundMovements': 2,
            'actualDashboardRepository': true,
            'lostAckReplay': true,
            'customerDenied': true,
            'revokedCashierDenied': true,
            'concurrentIntentBlocked': true,
            'externalMoney': false,
            'evidence':
                'Real GoTrue/PostgREST through Dashboard repository; not browser UI or hosted acceptance',
          }),
        );
      }
    },
    skip: directory == null
        ? 'Set PLAYSPOT_LOCAL_TEST_DIR for the isolated loopback stack only'
        : false,
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
