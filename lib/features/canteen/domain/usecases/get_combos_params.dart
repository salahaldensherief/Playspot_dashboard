import 'package:equatable/equatable.dart';

class GetCombosParams extends Equatable {
  final String loungeId;
  final bool forceRefresh;

  const GetCombosParams({
    required this.loungeId,
    this.forceRefresh = false,
  });

  @override
  List<Object?> get props => [loungeId, forceRefresh];
}
