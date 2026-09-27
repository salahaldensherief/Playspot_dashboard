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

  /// Pagination state ("load more" pattern).
  final int allPayoutsNextPage;
  final bool allPayoutsHasMore;
  final bool allPayoutsLoadingMore;
  final int loungePayoutsNextPage;
  final bool loungePayoutsHasMore;
  final bool loungePayoutsLoadingMore;

  const PayoutState({
    this.status = PayoutCubitStatus.initial,
    this.pendingOverviews = const [],
    this.allPayouts = const [],
    this.loungePayouts = const [],
    this.selectedPayoutDetails,
    this.errorMessage,
    this.successMessage,
    this.allPayoutsNextPage = 2,
    this.allPayoutsHasMore = false,
    this.allPayoutsLoadingMore = false,
    this.loungePayoutsNextPage = 2,
    this.loungePayoutsHasMore = false,
    this.loungePayoutsLoadingMore = false,
  });

  PayoutState copyWith({
    PayoutCubitStatus? status,
    List<PendingPayoutOverview>? pendingOverviews,
    List<PayoutEntity>? allPayouts,
    List<PayoutEntity>? loungePayouts,
    Map<String, dynamic>? selectedPayoutDetails,
    String? errorMessage,
    String? successMessage,
    int? allPayoutsNextPage,
    bool? allPayoutsHasMore,
    bool? allPayoutsLoadingMore,
    int? loungePayoutsNextPage,
    bool? loungePayoutsHasMore,
    bool? loungePayoutsLoadingMore,
  }) {
    return PayoutState(
      status: status ?? this.status,
      pendingOverviews: pendingOverviews ?? this.pendingOverviews,
      allPayouts: allPayouts ?? this.allPayouts,
      loungePayouts: loungePayouts ?? this.loungePayouts,
      selectedPayoutDetails: selectedPayoutDetails ?? this.selectedPayoutDetails,
      errorMessage: errorMessage,
      successMessage: successMessage,
      allPayoutsNextPage: allPayoutsNextPage ?? this.allPayoutsNextPage,
      allPayoutsHasMore: allPayoutsHasMore ?? this.allPayoutsHasMore,
      allPayoutsLoadingMore: allPayoutsLoadingMore ?? this.allPayoutsLoadingMore,
      loungePayoutsNextPage: loungePayoutsNextPage ?? this.loungePayoutsNextPage,
      loungePayoutsHasMore: loungePayoutsHasMore ?? this.loungePayoutsHasMore,
      loungePayoutsLoadingMore: loungePayoutsLoadingMore ?? this.loungePayoutsLoadingMore,
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
        allPayoutsNextPage,
        allPayoutsHasMore,
        allPayoutsLoadingMore,
        loungePayoutsNextPage,
        loungePayoutsHasMore,
        loungePayoutsLoadingMore,
      ];
}
