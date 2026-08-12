import 'package:equatable/equatable.dart';
import '../../domain/entities/kyc_request.dart';

enum KycStatus { initial, loading, success, failure }

class KycState extends Equatable {
  final KycStatus status;
  final List<KycRequest> requests;
  final String? errorMessage;

  const KycState({
    this.status = KycStatus.initial,
    this.requests = const [],
    this.errorMessage,
  });

  KycState copyWith({
    KycStatus? status,
    List<KycRequest>? requests,
    String? errorMessage,
  }) {
    return KycState(
      status: status ?? this.status,
      requests: requests ?? this.requests,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, requests, errorMessage];
}
