import 'dart:typed_data';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:play_spot_dashboard/core/usecases/base_usecase.dart';
import 'package:play_spot_dashboard/core/utils/app_logger.dart';
import '../../domain/entities/promo_entity.dart';
import '../../domain/entities/notification_entity.dart';
import '../../domain/usecases/marketing_usecases.dart';
import 'marketing_state.dart';

class MarketingCubit extends Cubit<MarketingState> {
  final GetPromotionsUseCase _getPromotionsUseCase;
  final CreatePromotionUseCase _createPromotionUseCase;
  final UpdatePromotionUseCase _updatePromotionUseCase;
  final DeletePromotionUseCase _deletePromotionUseCase;
  final UploadPromoPosterUseCase _uploadPromoPosterUseCase;
  final GetNotificationsUseCase _getNotificationsUseCase;
  final GetNotificationsPageUseCase _getNotificationsPageUseCase;
  final SendNotificationUseCase _sendNotificationUseCase;

  MarketingCubit({
    required GetPromotionsUseCase getPromotionsUseCase,
    required CreatePromotionUseCase createPromotionUseCase,
    required UpdatePromotionUseCase updatePromotionUseCase,
    required DeletePromotionUseCase deletePromotionUseCase,
    required UploadPromoPosterUseCase uploadPromoPosterUseCase,
    required GetNotificationsUseCase getNotificationsUseCase,
    required GetNotificationsPageUseCase getNotificationsPageUseCase,
    required SendNotificationUseCase sendNotificationUseCase,
  })  : _getPromotionsUseCase = getPromotionsUseCase,
        _createPromotionUseCase = createPromotionUseCase,
        _updatePromotionUseCase = updatePromotionUseCase,
        _deletePromotionUseCase = deletePromotionUseCase,
        _uploadPromoPosterUseCase = uploadPromoPosterUseCase,
        _getNotificationsUseCase = getNotificationsUseCase,
        _getNotificationsPageUseCase = getNotificationsPageUseCase,
        _sendNotificationUseCase = sendNotificationUseCase,
        super(const MarketingState());

  Future<void> loadPromotions({String? loungeId, String? city}) async {
    emit(state.copyWith(status: MarketingStatus.loading));
    final result = await _getPromotionsUseCase(GetPromotionsParams(loungeId: loungeId, city: city));

    if (isClosed) return;

    result.fold(
      (failure) {
        AppLogger.error('Load promotions error: ${failure.message}');
        emit(state.copyWith(
          status: MarketingStatus.failure,
          errorMessage: failure.message,
        ));
      },
      (promos) => emit(state.copyWith(
        status: MarketingStatus.success,
        promotions: promos,
      )),
    );
  }

  Future<void> deletePromotion(String id, {String? loungeId}) async {
    final result = await _deletePromotionUseCase(id);
    if (isClosed) return;
    result.fold(
      (failure) {
        AppLogger.error('Delete promotion error: ${failure.message}');
        emit(state.copyWith(status: MarketingStatus.failure, errorMessage: failure.message));
      },
      (_) {
        emit(state.copyWith(status: MarketingStatus.actionSuccess));
        loadPromotions(loungeId: loungeId);
      },
    );
  }

  Future<void> createPromotion(PromoEntity promo) async {
    emit(state.copyWith(status: MarketingStatus.loading));
    final result = (promo.id.isNotEmpty)
        ? await _updatePromotionUseCase(promo)
        : await _createPromotionUseCase(promo);
    if (isClosed) return;
    result.fold(
      (failure) {
        AppLogger.error('Create/update promotion error: ${failure.message}');
        emit(state.copyWith(status: MarketingStatus.failure, errorMessage: failure.message));
      },
      (_) {
        emit(state.copyWith(status: MarketingStatus.actionSuccess));
        loadPromotions(loungeId: promo.loungeId);
      },
    );
  }

  Future<String?> uploadPromoPoster(Uint8List fileBytes, String fileName) async {
    final result = await _uploadPromoPosterUseCase(UploadPromoPosterParams(
      fileBytes: fileBytes,
      fileName: fileName,
    ));
    return result.fold(
      (failure) {
        AppLogger.error('Upload promo poster error: ${failure.message}');
        emit(state.copyWith(status: MarketingStatus.failure, errorMessage: failure.message));
        return null;
      },
      (url) => url,
    );
  }

  // Notifications
  Future<void> loadNotifications() async {
    emit(state.copyWith(status: MarketingStatus.loading));
    final result = await _getNotificationsUseCase(const NoParams());
    if (isClosed) return;
    result.fold(
      (failure) {
        AppLogger.error('Load notifications error: ${failure.message}');
        emit(state.copyWith(status: MarketingStatus.failure, errorMessage: failure.message));
      },
      (notifications) => emit(state.copyWith(status: MarketingStatus.success, notifications: notifications)),
    );
  }

  Future<void> loadNotificationsPage({int page = 1, int pageSize = 20}) async {
    emit(state.copyWith(status: MarketingStatus.loading));
    final result = await _getNotificationsPageUseCase(GetNotificationsPageParams(page: page, pageSize: pageSize));
    if (isClosed) return;
    result.fold(
      (failure) {
        AppLogger.error('Load notifications page error: ${failure.message}');
        emit(state.copyWith(status: MarketingStatus.failure, errorMessage: failure.message));
      },
      (paginated) => emit(state.copyWith(
        status: MarketingStatus.success,
        notifications: paginated.items,
        notificationPage: paginated.page,
        notificationPageSize: paginated.pageSize,
        totalNotificationsCount: paginated.totalCount,
      )),
    );
  }

  Future<void> sendNotification(NotificationEntity notification) async {
    emit(state.copyWith(status: MarketingStatus.loading));
    final result = await _sendNotificationUseCase(notification);
    if (isClosed) return;
    result.fold(
      (failure) {
        AppLogger.error('Send notification error: ${failure.message}');
        emit(state.copyWith(status: MarketingStatus.failure, errorMessage: failure.message));
      },
      (_) {
        emit(state.copyWith(status: MarketingStatus.actionSuccess));
        loadNotifications();
      },
    );
  }
}
