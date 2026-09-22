import 'package:equatable/equatable.dart';
import '../../domain/entities/payout_entity.dart';

enum PayoutCubitStatus { initial, loading, success, actionSuccess, failure }

class PayoutState extends Equatable {
  final PayoutCubitStatus status;
  final List<PendingPayoutOverview> pendingOverviews;
  final List<PayoutEntity> allPayouts;
  final List<PayoutEntity> loungePayouts;
  final Map<String, dynamic>? selectedPayoutDetails;
  final String? errorMessage;
  final String? successMessage;

  const PayoutState({
    this.status = PayoutCubitStatus.initial,
    this.pendingOverviews = const [],
    this.allPayouts = const [],
    this.loungePayouts = const [],
    this.selectedPayoutDetails,
    this.errorMessage,
    this.successMessage,
  });

  PayoutState copyWith({
    PayoutCubitStatus? status,
    List<PendingPayoutOverview>? pendingOverviews,
    List<PayoutEntity>? allPayouts,
    List<PayoutEntity>? loungePayouts,
    Map<String, dynamic>? selectedPayoutDetails,
    String? errorMessage,
    String? successMessage,
  }) {
    return PayoutState(
      status: status ?? this.status,
      pendingOverviews: pendingOverviews ?? this.pendingOverviews,
      allPayouts: allPayouts ?? this.allPayouts,
      loungePayouts: loungePayouts ?? this.loungePayouts,
      selectedPayoutDetails: selectedPayoutDetails ?? this.selectedPayoutDetails,
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        pendingOverviews,
        allPayouts,
        loungePayouts,
        selectedPayoutDetails,
        errorMessage,
        successMessage,
      ];
}
