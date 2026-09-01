import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/promo_entity.dart';
import '../../domain/entities/notification_entity.dart';
import '../../domain/repositories/marketing_repository.dart';
import 'marketing_state.dart';

class MarketingCubit extends Cubit<MarketingState> {
  final MarketingRepository repository;

  MarketingCubit(this.repository) : super(const MarketingState());

  Future<void> loadPromotions({String? loungeId, String? city}) async {
    emit(state.copyWith(status: MarketingStatus.loading));
    final result = await repository.getPromotions(loungeId: loungeId, city: city);
    
    if (isClosed) return;

    result.fold(
      (failure) => emit(state.copyWith(
        status: MarketingStatus.failure,
        errorMessage: failure.message,
      )),
      (promos) => emit(state.copyWith(
        status: MarketingStatus.success,
        promotions: promos,
      )),
    );
  }

  Future<void> deletePromotion(String id, {String? loungeId}) async {
    final result = await repository.deletePromotion(id);
    if (isClosed) return;
    result.fold(
      (failure) => emit(state.copyWith(status: MarketingStatus.failure, errorMessage: failure.message)),
      (_) {
        emit(state.copyWith(status: MarketingStatus.actionSuccess));
        loadPromotions(loungeId: loungeId);
      },
    );
  }

  Future<void> createPromotion(PromoEntity promo) async {
    emit(state.copyWith(status: MarketingStatus.loading));
    final result = await repository.createPromotion(promo);
    if (isClosed) return;
    result.fold(
      (failure) => emit(state.copyWith(status: MarketingStatus.failure, errorMessage: failure.message)),
      (_) {
        emit(state.copyWith(status: MarketingStatus.actionSuccess));
        loadPromotions(loungeId: promo.loungeId);
      },
    );
  }

  // Notifications
  Future<void> loadNotifications() async {
    emit(state.copyWith(status: MarketingStatus.loading));
    final result = await repository.getNotifications();
    if (isClosed) return;
    result.fold(
      (failure) => emit(state.copyWith(status: MarketingStatus.failure, errorMessage: failure.message)),
      (notifications) => emit(state.copyWith(status: MarketingStatus.success, notifications: notifications)),
    );
  }

  Future<void> sendNotification(NotificationEntity notification) async {
    emit(state.copyWith(status: MarketingStatus.loading));
    final result = await repository.sendNotification(notification);
    if (isClosed) return;
    result.fold(
      (failure) => emit(state.copyWith(status: MarketingStatus.failure, errorMessage: failure.message)),
      (_) {
        emit(state.copyWith(status: MarketingStatus.actionSuccess));
        loadNotifications();
      },
    );
  }
}
