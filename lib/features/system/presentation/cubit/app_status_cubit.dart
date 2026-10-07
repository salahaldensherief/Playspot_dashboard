import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:play_spot_dashboard/features/system/domain/entities/app_status_entity.dart';
import 'package:play_spot_dashboard/features/system/domain/usecases/get_app_status_usecase.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppStatusCubitState {
  final AppStatusEntity appStatus;
  final bool isLoading;
  final String? errorMessage;

  const AppStatusCubitState({
    this.appStatus = const AppStatusEntity(),
    this.isLoading = false,
    this.errorMessage,
  });

  AppStatusCubitState copyWith({
    AppStatusEntity? appStatus,
    bool? isLoading,
    String? errorMessage,
  }) {
    return AppStatusCubitState(
      appStatus: appStatus ?? this.appStatus,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class AppStatusCubit extends Cubit<AppStatusCubitState> {
  final GetAppStatusUseCase _getAppStatusUseCase;
  final SupabaseClient _supabaseClient;
  RealtimeChannel? _statusChannel;
  Timer? _pollingTimer;
  bool _watching = false;

  AppStatusCubit({
    required GetAppStatusUseCase getAppStatusUseCase,
    required SupabaseClient supabaseClient,
  })  : _getAppStatusUseCase = getAppStatusUseCase,
        _supabaseClient = supabaseClient,
        super(const AppStatusCubitState());

  void initAppStatusWatch() {
    if (isClosed || _watching) return;
    _watching = true;
    checkAppStatus();

    // Listen to Realtime updates on app_status table
    try {
      _statusChannel = _supabaseClient
          .channel('public:app_status_watcher')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'app_status',
            callback: (_) => checkAppStatus(),
          )
          .subscribe();
    } catch (_) {}

    // Backup polling every 60 seconds
    _pollingTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      checkAppStatus();
    });
  }

  Future<void> checkAppStatus() async {
    if (isClosed) return;
    final result = await _getAppStatusUseCase();
    if (isClosed) return;

    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.message)),
      (status) => emit(state.copyWith(appStatus: status, isLoading: false)),
    );
  }

  @override
  Future<void> close() async {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    final channel = _statusChannel;
    _statusChannel = null;
    // Mark the Cubit closed before awaiting channel cleanup, so late reads
    // cannot publish state during teardown.
    await super.close();
    if (channel != null) await _supabaseClient.removeChannel(channel);
  }
}
