import 'package:equatable/equatable.dart';

class GetUpsellRulesParams extends Equatable {
  final String loungeId;
  final bool forceRefresh;

  const GetUpsellRulesParams({
    required this.loungeId,
    this.forceRefresh = false,
  });

  @override
  List<Object?> get props => [loungeId, forceRefresh];
}
