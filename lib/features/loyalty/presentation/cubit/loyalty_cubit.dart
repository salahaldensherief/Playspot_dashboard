import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/loyalty_repository.dart';
import '../../../marketing/domain/entities/redemption_option_entity.dart';
import 'loyalty_state.dart';

class LoyaltyCubit extends Cubit<LoyaltyState> {
  final LoyaltyRepository repository;

  LoyaltyCubit(this.repository) : super(const LoyaltyState());

  Future<void> loadLoyaltyData() async {
    emit(state.copyWith(status: LoyaltyStatus.loading));
    
    final statsResult = await repository.getLoyaltyStats();
    final optionsResult = await repository.getRedemptionOptions();

    statsResult.fold(
      (failure) => emit(state.copyWith(status: LoyaltyStatus.failure, errorMessage: failure.message)),
      (stats) {
        optionsResult.fold(
          (failure) => emit(state.copyWith(status: LoyaltyStatus.failure, errorMessage: failure.message)),
          (options) => emit(state.copyWith(
            status: LoyaltyStatus.success,
            stats: stats,
            options: options,
          )),
        );
      },
    );
  }

  Future<void> createOption(RedemptionOptionEntity option) async {
    final result = await repository.createRedemptionOption(option);
    result.fold(
      (failure) => emit(state.copyWith(status: LoyaltyStatus.failure, errorMessage: failure.message)),
      (_) => loadLoyaltyData(),
    );
  }

  Future<void> updateOption(String id, Map<String, dynamic> data) async {
    final result = await repository.updateRedemptionOption(id, data);
    result.fold(
      (failure) => emit(state.copyWith(status: LoyaltyStatus.failure, errorMessage: failure.message)),
      (_) => loadLoyaltyData(),
    );
  }

  Future<void> toggleOptionStatus(String id, bool isActive) async {
    await updateOption(id, {'is_active': isActive});
  }

  Future<void> deleteOption(String id) async {
    final result = await repository.deleteRedemptionOption(id);
    result.fold(
      (failure) => emit(state.copyWith(status: LoyaltyStatus.failure, errorMessage: failure.message)),
      (_) => loadLoyaltyData(),
    );
  }
}
