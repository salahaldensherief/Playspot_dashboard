import '../../domain/entities/lounge_review_entity.dart';

class LoungeReviewModel extends LoungeReviewEntity {
  const LoungeReviewModel({
    required super.id,
    required super.loungeId,
    super.userId,
    super.userName,
    super.userAvatarUrl,
    required super.rating,
    super.comment,
    required super.createdAt,
  });

  factory LoungeReviewModel.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic val) {
      if (val == null) return 0.0;
      if (val is num) return val.toDouble();
      return double.tryParse(val.toString()) ?? 0.0;
    }

    final profileData = json['profiles'] as Map<String, dynamic>?;
    final userData = json['users'] as Map<String, dynamic>?;

    final String userName = (
      json['user_name'] ??
      json['full_name'] ??
      profileData?['full_name'] ??
      profileData?['name'] ??
      userData?['full_name'] ??
      'Anonymous Client'
    ).toString();

    final String? userAvatarUrl = (
      json['user_avatar'] ??
      json['avatar_url'] ??
      profileData?['avatar_url'] ??
      userData?['avatar_url']
    )?.toString();

    DateTime parsedDate;
    try {
      parsedDate = json['created_at'] != null
          ? DateTime.parse(json['created_at'].toString())
          : DateTime.now();
    } catch (_) {
      parsedDate = DateTime.now();
    }

    return LoungeReviewModel(
      id: (json['id'] ?? '').toString(),
      loungeId: (json['lounge_id'] ?? json['loungeId'] ?? '').toString(),
      userId: (json['user_id'] ?? json['userId'])?.toString(),
      userName: userName,
      userAvatarUrl: userAvatarUrl,
      rating: parseDouble(json['rating'] ?? json['score'] ?? json['stars']),
      comment: json['comment']?.toString() ?? json['review_text']?.toString() ?? json['notes']?.toString(),
      createdAt: parsedDate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'lounge_id': loungeId,
      'user_id': userId,
      'user_name': userName,
      'user_avatar': userAvatarUrl,
      'rating': rating,
      'comment': comment,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
