import 'package:equatable/equatable.dart';

class LoungeReviewEntity extends Equatable {
  final String id;
  final String loungeId;
  final String? userId;
  final String? userName;
  final String? userAvatarUrl;
  final double rating;
  final String? comment;
  final DateTime createdAt;

  const LoungeReviewEntity({
    required this.id,
    required this.loungeId,
    this.userId,
    this.userName,
    this.userAvatarUrl,
    required this.rating,
    this.comment,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        loungeId,
        userId,
        userName,
        userAvatarUrl,
        rating,
        comment,
        createdAt,
      ];
}
