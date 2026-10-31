import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../domain/repositories/booking_refund_repository.dart';

/// Canonical refund RPC boundary. No legacy payment or direct ledger writes.
class BookingRefundRepositoryImpl implements BookingRefundRepository {
  final SupabaseClient client;
  @override
  final bool writesEnabled;
  BookingRefundRepositoryImpl(this.client, {this.writesEnabled = false});
  static final Set<String> _busy = {};

  String get _actor {
    final id = client.auth.currentUser?.id;
    if (id == null) throw const RefundFailure(RefundFailureKind.denied);
    return id;
  }

  String _key(String booking, String phase) =>
      'booking_refund_v1_${sha256.convert(utf8.encode('$_actor|$booking|$phase'))}';
  Future<Map<String, dynamic>?> _pending(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    final value = prefs.getString(key);
    return value == null ? null : _map(jsonDecode(value));
  }

  @override
  Future<BookingRefundSummary> summary(
    String bookingId,
    String loungeId,
  ) async {
    try {
      final actor = _actor;
      final raw = await client.rpc(
        'get_booking_refund_summary',
        params: {'p_booking_id': bookingId},
      );
      if (_actor != actor) throw const RefundFailure(RefundFailureKind.denied);
      final result = parseSummary(raw, bookingId, loungeId);
      // A canonical read can resolve a lost acknowledgement after app restart.
      // Absence does not prove failure, so unmatched journals are never discarded.
      for (final phase in ['initiate', 'execute']) {
        final key = _key(bookingId, phase);
        final pending = await _pending(key);
        if (pending == null) continue;
        final op = pending['operation'];
        final confirmed = phase == 'initiate'
            ? result.requests.any((r) => r.operationId == op)
            : result.movements.any(
                (m) => m.operationId == op && m.type == 'refund',
              );
        if (confirmed) {
          final prefs = await SharedPreferences.getInstance();
          if (!await prefs.remove(key)) throw const FormatException();
        }
      }
      if (_actor != actor) {
        throw const RefundFailure(RefundFailureKind.denied);
      }
      return result;
    } on RefundFailure {
      rethrow;
    } on PostgrestException catch (e) {
      throw _failure(e);
    } catch (_) {
      throw const RefundFailure(RefundFailureKind.unavailable);
    }
  }

  @override
  Future<RefundReceipt> initiate({
    required BookingRefundSummary summary,
    required String collectionId,
    required int amountMinor,
    required String reason,
    required bool policyOverride,
  }) {
    final collection = summary.movements
        .where((m) => m.id == collectionId)
        .firstOrNull;
    if (collection == null ||
        !collection.supportsCashReturn ||
        amountMinor <= 0 ||
        amountMinor > summary.availableFor(collection) ||
        reason.trim().isEmpty ||
        reason.trim().length > 500) {
      throw const RefundFailure(RefundFailureKind.invalid);
    }
    final revision = summary.requests.map((r) => '${r.id}:${r.status}').toList()
      ..sort();
    return _mutate(
      summary,
      'initiate',
      'initiate_booking_refund',
      {
        'p_booking_id': summary.bookingId,
        'p_collection_movement_id': collectionId,
        'p_refund_amount_minor': amountMinor,
        'p_reason': reason.trim(),
        'p_policy_override': policyOverride,
      },
      jsonEncode(revision),
      (r, op) {
        _same(r, 'collection_movement_id', collectionId);
        _same(r, 'requested_amount_minor', amountMinor);
        _same(r, 'policy_override', policyOverride);
        _same(r, 'funds_holder', 'lounge');
        _same(r, 'status', 'approved_pending_return');
        return RefundReceipt(op, _id(r, 'refund_request_id'), amountMinor);
      },
    );
  }

  @override
  Future<RefundReceipt> execute({
    required BookingRefundSummary summary,
    required BookingRefundRequest request,
    required String shiftId,
    required String evidence,
  }) {
    final collection = summary.movements
        .where((m) => m.id == request.collectionId)
        .firstOrNull;
    if (collection == null ||
        !collection.supportsCashReturn ||
        request.status != 'approved_pending_return' ||
        request.holder != 'lounge' ||
        shiftId.isEmpty ||
        evidence.trim().isEmpty ||
        evidence.trim().length > 500) {
      throw const RefundFailure(RefundFailureKind.invalid);
    }
    return _mutate(
      summary,
      'execute',
      'execute_booking_refund',
      {
        'p_refund_request_id': request.id,
        'p_return_payment_method': 'cash',
        'p_evidence_reference': evidence.trim(),
        'p_shift_id': shiftId,
      },
      request.id,
      (r, op) {
        _same(r, 'refund_request_id', request.id);
        _same(r, 'reversal_of', collection.id);
        _same(r, 'refunded_amount_minor', request.amountMinor);
        _same(r, 'return_payment_method', 'cash');
        _same(r, 'funds_holder', 'lounge');
        _same(r, 'shift_id', shiftId);
        _id(r, 'shift_expense_id');
        if (_minor(r, 'commission_reversed_minor') +
                _minor(r, 'net_to_lounge_reversed_minor') !=
            request.amountMinor) {
          throw const FormatException();
        }
        return RefundReceipt(
          op,
          request.id,
          request.amountMinor,
          movementId: _id(r, 'refund_movement_id'),
        );
      },
    );
  }

  Future<RefundReceipt> _mutate(
    BookingRefundSummary summary,
    String phase,
    String rpc,
    Map<String, dynamic> payload,
    String revision,
    RefundReceipt Function(Map<String, dynamic>, String) parse,
  ) async {
    if (!writesEnabled) {
      throw const RefundFailure(RefundFailureKind.unavailable);
    }
    final actor = _actor, key = _key(summary.bookingId, phase);
    if (!_busy.add(key)) throw const RefundFailure(RefundFailureKind.pending);
    var dispatched = false;
    var previouslyPending = false;
    try {
      final fingerprint = sha256
          .convert(utf8.encode(jsonEncode(payload)))
          .toString();
      final prior = await _pending(key);
      previouslyPending = prior != null;
      if (prior != null && prior['fingerprint'] != fingerprint) {
        throw const RefundFailure(RefundFailureKind.pending);
      }
      // Same snapshot + same intent across tabs yields the same server operation.
      // Store only identifiers/hashes, never the reason, evidence, key or token.
      final operation =
          prior?['operation'] as String? ??
          const Uuid().v5(
            Namespace.url.value,
            'playspot-refund-v1|$actor|${summary.bookingId}|$phase|$revision|$fingerprint',
          );
      final prefs = await SharedPreferences.getInstance();
      if (!await prefs.setString(
        key,
        jsonEncode({'operation': operation, 'fingerprint': fingerprint}),
      )) {
        throw const RefundFailure(RefundFailureKind.unavailable);
      }
      if (_actor != actor) throw const RefundFailure(RefundFailureKind.denied);
      dispatched = true;
      final raw = await client.rpc(
        rpc,
        params: {...payload, 'p_operation_id': operation},
      );
      if (_actor != actor) {
        throw const RefundFailure(RefundFailureKind.uncertain);
      }
      final result = _map(raw);
      _same(result, 'success', true);
      _same(result, 'booking_id', summary.bookingId);
      _same(result, 'operation_id', operation);
      final receipt = parse(result, operation);
      // Persisting a validated receipt is optional; retaining the journal on a
      // storage error is safe and is resolved by the next authoritative read.
      try {
        await prefs.remove(key);
      } catch (_) {
        // The canonical receipt remains confirmed even if local cleanup fails.
      }
      return receipt;
    } on RefundFailure {
      rethrow;
    } on PostgrestException catch (e) {
      // A first definitive transaction rejection can be corrected. After any
      // earlier uncertain attempt, retain the identity until canonical recovery.
      final definitive = const {
        '42501',
        '22023',
        '55000',
        'P0001',
        'P0002',
        '40001',
        '40P01',
        'PGRST301',
      }.contains(e.code);
      if (!previouslyPending && dispatched && definitive) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(key);
      }
      throw definitive
          ? _failure(e)
          : const RefundFailure(RefundFailureKind.uncertain);
    } catch (_) {
      throw RefundFailure(
        dispatched
            ? RefundFailureKind.uncertain
            : RefundFailureKind.unavailable,
      );
    } finally {
      _busy.remove(key);
    }
  }

  static RefundFailure _failure(PostgrestException e) => RefundFailure(
    e.code == '42501' || e.code == 'PGRST301'
        ? RefundFailureKind.denied
        : RefundFailureKind.rejected,
  );

  static BookingRefundSummary parseSummary(
    Object? raw,
    String booking,
    String lounge,
  ) {
    final r = _map(raw);
    _same(r, 'booking_id', booking);
    _same(r, 'lounge_id', lounge);
    final gross = _minor(r, 'gross_collected_minor'),
        refunded = _minor(r, 'total_refunded_minor'),
        net = _minor(r, 'net_collected_minor');
    if (gross - refunded != net) throw const FormatException();
    final movements = _list(r, 'movements')
        .map((v) {
          final m = _map(v);
          final type = _id(m, 'movement_type'),
              amount = _minor(m, 'amount_minor', signed: true);
          if (!['collection', 'refund'].contains(type) ||
              (type == 'collection' ? amount <= 0 : amount >= 0)) {
            throw const FormatException();
          }
          return RefundMovement(
            id: _id(m, 'movement_id'),
            operationId: _id(m, 'operation_id'),
            type: type,
            method: _id(m, 'payment_method'),
            holder: _id(m, 'funds_holder'),
            amountMinor: amount,
            reversalOf: m['reversal_of'] as String?,
          );
        })
        .toList(growable: false);
    final requests = _list(r, 'refund_requests')
        .map((v) {
          final q = _map(v), status = _id(q, 'status');
          if (![
            'approved_pending_return',
            'completed',
            'cancelled',
          ].contains(status)) {
            throw const FormatException();
          }
          return BookingRefundRequest(
            id: _id(q, 'refund_request_id'),
            operationId: _id(q, 'operation_id'),
            collectionId: _id(q, 'target_movement_id'),
            holder: _id(q, 'funds_holder'),
            status: status,
            amountMinor: _minor(q, 'requested_amount_minor'),
            refundMovementId: q['refund_movement_id'] as String?,
          );
        })
        .toList(growable: false);
    final pending = _minor(r, 'pending_refund_minor'),
        remaining = _minor(r, 'refundable_remaining_minor');
    if (pending > net ||
        remaining != net - pending ||
        movements.map((m) => m.id).toSet().length != movements.length ||
        requests.map((q) => q.id).toSet().length != requests.length ||
        movements
                .where((m) => m.type == 'collection')
                .fold(0, (s, m) => s + m.amountMinor) !=
            gross ||
        movements
                .where((m) => m.type == 'refund')
                .fold(0, (s, m) => s - m.amountMinor) !=
            refunded) {
      throw const FormatException();
    }
    return BookingRefundSummary(
      bookingId: booking,
      loungeId: lounge,
      grossMinor: gross,
      refundedMinor: refunded,
      netMinor: net,
      pendingMinor: pending,
      remainingMinor: remaining,
      movements: List.unmodifiable(movements),
      requests: List.unmodifiable(requests),
    );
  }

  static Map<String, dynamic> _map(Object? v) {
    if (v is! Map<String, dynamic>) throw const FormatException();
    return v;
  }

  static List<dynamic> _list(Map<String, dynamic> m, String k) {
    if (m[k] is! List) throw const FormatException();
    return m[k] as List;
  }

  static String _id(Map<String, dynamic> m, String k) {
    if (m[k] is! String || (m[k] as String).isEmpty) {
      throw const FormatException();
    }
    return m[k] as String;
  }

  static int _minor(Map<String, dynamic> m, String k, {bool signed = false}) {
    final v = m[k];
    if (v is! int || v.abs() > 9007199254740991 || (!signed && v < 0)) {
      throw const FormatException();
    }
    return v;
  }

  static void _same(Map<String, dynamic> m, String k, Object v) {
    if (m[k] != v) throw const FormatException();
  }
}
