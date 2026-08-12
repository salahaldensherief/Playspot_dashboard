import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/promo_entity.dart';
import 'package:play_spot_dashboard/features/lounges/domain/repositories/lounge_repository.dart'; // Assume it handles promos or create a new one

abstract class MarketingState extends Equatable {
  const MarketingState();
  @override
  List<Object?> get props => [];
}

class MarketingInitial extends MarketingState {}
class MarketingLoading extends MarketingState {}
class MarketingLoaded extends MarketingState {
  final List<PromoEntity> promotions;
  const MarketingLoaded(this.promotions);
  @override
  List<Object?> get props => [promotions];
}
class MarketingError extends MarketingState {
  final String message;
  const MarketingError(this.message);
  @override
  List<Object?> get props => [message];
}

class MarketingCubit extends Cubit<MarketingState> {
  // For simplicity, let's use a repository that handles promotions
  // In a real scenario, this would be MarketingRepository
  MarketingCubit() : super(MarketingInitial());

  Future<void> loadPromotions({String? loungeId}) async {
    emit(MarketingLoading());
    // In a real implementation, you'd call a repository here
    // For now, let's keep it empty or emit an empty list
    emit(const MarketingLoaded([]));
  }

  Future<void> deletePromotion(String id) async {
    // Implementation for deleting
    // After success, reload
    loadPromotions();
  }
}
