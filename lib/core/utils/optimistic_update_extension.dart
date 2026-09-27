// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member

import 'package:dartz/dartz.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:play_spot_dashboard/core/error/failures.dart';

extension OptimisticUpdateExtension<S> on Cubit<S> {
  /// Helper method for applying optimistic state updates before a server call,
  /// and automatically rolling back if the server call returns a Failure.
  Future<bool> optimisticUpdate<T>({
    required S Function(S currentState) apply,
    required Future<Either<Failure, T>> Function() onServer,
    required S Function(S currentState, Failure failure) rollback,
    void Function(T data)? onSuccess,
  }) async {
    final previousState = state;
    emit(apply(previousState));

    final result = await onServer();

    if (isClosed) return false;

    return result.fold(
      (failure) {
        emit(rollback(state, failure));
        return false;
      },
      (data) {
        if (onSuccess != null) {
          onSuccess(data);
        }
        return true;
      },
    );
  }
}
