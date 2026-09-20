import 'package:equatable/equatable.dart';
import '../../domain/entities/user_ban_request.dart';

enum ModerationStatus { initial, loading, success, error }

class ModerationState extends Equatable {
  final ModerationStatus status;
  final List<UserBanRequest> banRequests;
  final List<UserBanRequest> pendingRequests;
  final String? errorMessage;
  final String? successMessage;
  final bool isSubmitting;

  const ModerationState({
    this.status = ModerationStatus.initial,
    this.banRequests = const [],
    this.pendingRequests = const [],
    this.errorMessage,
    this.successMessage,
    this.isSubmitting = false,
  });

  ModerationState copyWith({
    ModerationStatus? status,
    List<UserBanRequest>? banRequests,
    List<UserBanRequest>? pendingRequests,
    String? errorMessage,
    String? successMessage,
    bool? isSubmitting,
  }) {
    return ModerationState(
      status: status ?? this.status,
      banRequests: banRequests ?? this.banRequests,
      pendingRequests: pendingRequests ?? this.pendingRequests,
      errorMessage: errorMessage,
      successMessage: successMessage,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }

  @override
  List<Object?> get props => [
        status,
        banRequests,
        pendingRequests,
        errorMessage,
        successMessage,
        isSubmitting,
      ];
}
