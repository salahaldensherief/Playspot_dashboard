import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:play_spot_dashboard/core/utils/app_logger.dart';
import '../../domain/entities/lounge.dart';
import '../../domain/repositories/lounge_repository.dart';
import 'lounge_state.dart';

class LoungeCubit extends Cubit<LoungeState> {
  final LoungeRepository repository;

  LoungeCubit(this.repository) : super(const LoungeState());

  void selectLounge(String loungeId) {
    if (state.selectedLoungeId != loungeId) {
      emit(state.copyWith(selectedLoungeId: loungeId));
    }
  }

  void initSelectedLounge(String? defaultLoungeId) {
    if (state.selectedLoungeId == null && defaultLoungeId != null && defaultLoungeId.isNotEmpty) {
      emit(state.copyWith(selectedLoungeId: defaultLoungeId));
    }
  }

  Future<void> fetchLounges({bool forceRefresh = false, String? ownerId}) async {
    if (!forceRefresh && state.status == LoungeStatus.loading) return;
    if (!forceRefresh && state.status == LoungeStatus.success && state.lounges.isNotEmpty) return;

    emit(state.copyWith(status: LoungeStatus.loading, clearError: true));
    final result = (ownerId != null && ownerId.isNotEmpty)
        ? await repository.getOwnerBranches(ownerId, forceRefresh: forceRefresh)
        : await repository.getLounges(forceRefresh: forceRefresh);
    
    if (isClosed) return;

    result.fold(
      (failure) {
        AppLogger.warning('fetchLounges failure: ${failure.message}');
        emit(state.copyWith(
          status: LoungeStatus.success,
          clearError: true,
          lounges: state.lounges,
        ));
      },
      (lounges) {
        final currentSelected = state.selectedLoungeId;
        final validSelected = (currentSelected != null && lounges.any((l) => l.id == currentSelected))
            ? currentSelected
            : (lounges.isNotEmpty ? lounges.first.id : null);

        emit(state.copyWith(
          status: LoungeStatus.success,
          lounges: lounges,
          selectedLoungeId: validSelected,
          clearError: true,
        ));
      },
    );
  }

  Future<String?> addBranch(Map<String, dynamic> branchData, {String? ownerId}) async {
    emit(state.copyWith(status: LoungeStatus.loading));
    final result = await repository.addLoungeBranch(branchData);
    if (isClosed) return null;

    return result.fold(
      (failure) {
        emit(state.copyWith(
          status: LoungeStatus.failure,
          errorMessage: failure.message,
        ));
        return null;
      },
      (newBranchId) {
        fetchLounges(forceRefresh: true, ownerId: ownerId);
        return newBranchId;
      },
    );
  }

  Future<Map<String, dynamic>?> getMultiBranchOverview({
    required String ownerId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final result = await repository.getMultiBranchOverview(
      ownerId: ownerId,
      startDate: startDate,
      endDate: endDate,
    );
    return result.fold(
      (failure) => null,
      (overview) => overview,
    );
  }

  Future<void> createLoungeAndAdmin({
    required Lounge lounge,
    required String ownerName,
    required String ownerEmail,
    required String ownerPassword,
    String? city,
    String? address,
    String? phone,
  }) async {
    emit(state.copyWith(status: LoungeStatus.loading));
    
    final result = await repository.createLoungeWithOwner(
      email: ownerEmail,
      password: ownerPassword.isNotEmpty ? ownerPassword : 'LoungeOwner@123',
      ownerName: ownerName,
      loungeName: lounge.name,
      city: city ?? lounge.city,
      address: address ?? lounge.location,
      phone: phone,
    );
    
    if (isClosed) return;

    result.fold(
      (failure) => emit(state.copyWith(
        status: LoungeStatus.failure,
        errorMessage: failure.message,
      )),
      (_) => fetchLounges(forceRefresh: true),
    );
  }

  Future<void> createLoungeWithOwner({
    required String loungeName,
    String? city,
    String? address,
    String? phone,
    required String ownerName,
    required String ownerEmail,
    String? ownerPhone,
    String? ownerPassword,
  }) async {
    emit(state.copyWith(status: LoungeStatus.loading));
    
    final result = await repository.createLoungeWithOwner(
      email: ownerEmail,
      password: (ownerPassword != null && ownerPassword.isNotEmpty) ? ownerPassword : 'LoungeOwner@123',
      ownerName: ownerName,
      loungeName: loungeName,
      city: city,
      address: address,
      phone: phone,
    );

    if (isClosed) return;

    result.fold(
      (failure) => emit(state.copyWith(
        status: LoungeStatus.failure,
        errorMessage: failure.message,
      )),
      (_) => fetchLounges(forceRefresh: true),
    );
  }

  Future<void> updateLoungeLocation(String loungeId, double lat, double lng) async {
    await repository.updateLoungeLocation(loungeId, lat, lng);
  }

  Future<void> toggleLoungeStatus(String loungeId, bool isOpen) async {
    // Optimistic UI update
    final currentState = state;
    if (currentState.lounges.isNotEmpty) {
      final updatedLounges = currentState.lounges.map((l) {
        if (l.id == loungeId) return l.copyWith(isOpen: isOpen);
        return l;
      }).toList();
      emit(state.copyWith(lounges: updatedLounges));
    }

    final result = await repository.toggleLoungeOpenStatus(loungeId, isOpen);
    result.fold(
      (failure) {
        emit(state.copyWith(status: LoungeStatus.failure, errorMessage: failure.message));
        fetchLounges(forceRefresh: true);
      },
      (_) => null,
    );
  }

  Future<void> updateLounge(Lounge lounge) async {
    emit(state.copyWith(status: LoungeStatus.loading));
    final result = await repository.updateLounge(lounge);
    
    if (isClosed) return;

    result.fold(
      (failure) => emit(state.copyWith(
        status: LoungeStatus.failure,
        errorMessage: failure.message,
      )),
      (_) {
        final updatedLounges = state.lounges.map((l) => l.id == lounge.id ? lounge : l).toList();
        emit(state.copyWith(status: LoungeStatus.success, lounges: updatedLounges));
        fetchLounges(forceRefresh: true);
      },
    );
  }

  Future<void> updateLoungeDiscount({
    required String loungeId,
    required bool hasDiscount,
    required int discountPercentage,
    String? titleAr,
    String? titleEn,
    DateTime? expiresAt,
    String? vodafoneCashNumber,
    String? instapayAccount,
  }) async {
    emit(state.copyWith(status: LoungeStatus.loading));
    final result = await repository.updateLoungeDiscount(
      loungeId: loungeId,
      hasDiscount: hasDiscount,
      discountPercentage: discountPercentage,
      titleAr: titleAr,
      titleEn: titleEn,
      expiresAt: expiresAt,
      vodafoneCashNumber: vodafoneCashNumber,
      instapayAccount: instapayAccount,
    );

    if (isClosed) return;

    result.fold(
      (failure) => emit(state.copyWith(
        status: LoungeStatus.failure,
        errorMessage: failure.message,
      )),
      (_) {
        final updatedLounges = state.lounges.map((l) {
          if (l.id == loungeId) {
            return l.copyWith(
              hasDiscount: hasDiscount,
              discountPercentage: discountPercentage,
              discountTitleAr: titleAr,
              discountTitleEn: titleEn,
              discountExpiresAt: expiresAt,
              vodafoneCashNumber: vodafoneCashNumber ?? l.vodafoneCashNumber,
              instapayAccount: instapayAccount ?? l.instapayAccount,
            );
          }
          return l;
        }).toList();
        emit(state.copyWith(status: LoungeStatus.success, lounges: updatedLounges));
        fetchLounges(forceRefresh: true);
      },
    );
  }

  Future<void> updateLoungePolicies({
    required String loungeId,
    required bool allowCashPayment,
    required bool requirePrepaidFirstTime,
    required int cashGracePeriodMinutes,
    String? vodafoneCashNumber,
    String? instapayAccount,
  }) async {
    emit(state.copyWith(status: LoungeStatus.loading));
    final result = await repository.updateLoungePolicies(
      loungeId: loungeId,
      allowCashPayment: allowCashPayment,
      requirePrepaidFirstTime: requirePrepaidFirstTime,
      cashGracePeriodMinutes: cashGracePeriodMinutes,
      vodafoneCashNumber: vodafoneCashNumber,
      instapayAccount: instapayAccount,
    );

    if (isClosed) return;

    result.fold(
      (failure) => emit(state.copyWith(
        status: LoungeStatus.failure,
        errorMessage: failure.message,
      )),
      (_) {
        final updatedLounges = state.lounges.map((l) {
          if (l.id == loungeId) {
            return l.copyWith(
              allowCashPayment: allowCashPayment,
              requirePrepaidFirstTime: requirePrepaidFirstTime,
              cashGracePeriodMinutes: cashGracePeriodMinutes,
              vodafoneCashNumber: vodafoneCashNumber ?? l.vodafoneCashNumber,
              instapayAccount: instapayAccount ?? l.instapayAccount,
            );
          }
          return l;
        }).toList();
        emit(state.copyWith(status: LoungeStatus.success, lounges: updatedLounges));
        fetchLounges(forceRefresh: true);
      },
    );
  }

  Future<void> deleteLounge(String id) async {
    emit(state.copyWith(status: LoungeStatus.loading));
    final result = await repository.deleteLounge(id);
    
    if (isClosed) return;

    result.fold(
      (failure) => emit(state.copyWith(
        status: LoungeStatus.failure,
        errorMessage: failure.message,
      )),
      (_) {
        final updatedLounges = state.lounges.where((l) => l.id != id).toList();
        emit(state.copyWith(status: LoungeStatus.success, lounges: updatedLounges));
        fetchLounges(forceRefresh: true);
      },
    );
  }
}
