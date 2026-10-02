import 'package:equatable/equatable.dart';

class ReviewKycParams extends Equatable {
  final String requestId;
  final int revision;
  final bool approve;
  final String? notes;

  const ReviewKycParams({
    required this.requestId,
    required this.revision,
    required this.approve,
    this.notes,
  });

  @override
  List<Object?> get props => [requestId, revision, approve, notes];
}
