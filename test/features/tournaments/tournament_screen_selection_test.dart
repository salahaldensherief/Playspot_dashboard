import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:play_spot_dashboard/features/auth/presentation/login/login_cubit.dart';
import 'package:play_spot_dashboard/features/auth/presentation/login/login_state.dart';
import 'package:play_spot_dashboard/features/tournaments/domain/entities/tournament_entity.dart';
import 'package:play_spot_dashboard/features/tournaments/domain/entities/tournament_participant_entity.dart';
import 'package:play_spot_dashboard/features/tournaments/presentation/tournament_cubit.dart';
import 'package:play_spot_dashboard/features/tournaments/presentation/tournament_state.dart';
import 'package:play_spot_dashboard/features/tournaments/presentation/tournament_matches_cubit.dart';
import 'package:play_spot_dashboard/features/tournaments/presentation/tournament_matches_state.dart';
import 'package:play_spot_dashboard/features/tournaments/presentation/tournament_participants_cubit.dart';
import 'package:play_spot_dashboard/features/tournaments/presentation/tournament_participants_state.dart';
import 'package:play_spot_dashboard/features/tournaments/presentation/tournaments_screen.dart';
import '../../support/mock_login_cubit.dart';

TournamentEntity tournament(String id) => TournamentEntity(
  id: id,
  title: id,
  gameTitle: 'EA FC',
  treeSize: 8,
  status: TournamentStatus.completed,
  entryFee: 100,
  prizePool: 0,
  startDate: DateTime(2026, 10, 15),
  endDate: DateTime(2026, 10, 16),
  registrationDeadline: DateTime(2026, 10, 14),
  minPlayers: 2,
  maxPlayers: 8,
);

class _Tournaments extends Cubit<TournamentState> implements TournamentCubit {
  _Tournaments() : super(const TournamentState());
  final requestedLocations = <bool>[];
  @override
  Future<void> loadTournaments({
    String? loungeId,
    String? status,
    bool requestLocation = true,
  }) async {
    requestedLocations.add(requestLocation);
    emit(state.copyWith(status: TournamentCubitStatus.loading));
    final list = [tournament('first'), tournament('second')];
    emit(
      state.copyWith(
        status: TournamentCubitStatus.success,
        tournaments: list,
        selectedTournament: state.selectedTournament ?? list.first,
      ),
    );
  }

  @override
  void selectTournament(TournamentEntity t) =>
      emit(state.copyWith(selectedTournament: t));
  @override
  void setTab(int index) => emit(state.copyWith(selectedTab: index));
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Participants extends Cubit<TournamentParticipantsState>
    implements TournamentParticipantsCubit {
  _Participants() : super(const TournamentParticipantsState());
  final loaded = <String>[];
  @override
  Future<void> loadParticipants(String id) async {
    loaded.add(id);
    emit(
      state.copyWith(
        status: TournamentParticipantsStatus.success,
        participants: [
          TournamentParticipantEntity(
            id: 'player',
            tournamentId: id,
            userId: 'customer',
            userName: 'Player',
            registeredAt: DateTime(2026, 10, 15),
            paymentStatus: ParticipantPaymentStatus.approved,
          ),
        ],
      ),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Matches extends Cubit<TournamentMatchesState>
    implements TournamentMatchesCubit {
  _Matches() : super(const TournamentMatchesState());
  final loaded = <String>[];
  final watched = <String>[];
  @override
  Future<void> loadMatches(String id) async {
    loaded.add(id);
  }

  @override
  void startWatchingDisputes(String id) {
    watched.add(id);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets(
    'automatic selection, changed selection and refresh load child data and counts',
    (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final main = _Tournaments();
      final participants = _Participants();
      final matches = _Matches();
      final login = MockLoginCubit();
      when(() => login.state).thenReturn(const LoginState());
      when(
        () => login.stream,
      ).thenAnswer((_) => const Stream<LoginState>.empty());
      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<TournamentCubit>.value(value: main),
            BlocProvider<TournamentParticipantsCubit>.value(
              value: participants,
            ),
            BlocProvider<TournamentMatchesCubit>.value(value: matches),
            BlocProvider<LoginCubit>.value(value: login),
          ],
          child: ScreenUtilInit(
            designSize: const Size(1920, 1080),
            builder: (_, _) =>
                const MaterialApp(home: Scaffold(body: TournamentsScreen())),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(participants.loaded, ['first']);
      expect(matches.loaded, ['first']);
      expect(find.textContaining('(1)'), findsOneWidget);
      main.selectTournament(tournament('second'));
      await tester.pumpAndSettle();
      expect(participants.loaded, ['first', 'second']);
      expect(matches.loaded, ['first', 'second']);
      await main.loadTournaments();
      await tester.pumpAndSettle();
      expect(participants.loaded, ['first', 'second', 'second']);
      expect(matches.watched, ['first', 'second', 'second']);
      matches.emit(
        matches.state.copyWith(status: TournamentMatchesStatus.actionSuccess),
      );
      await tester.pumpAndSettle();
      expect(
        main.requestedLocations.last,
        isFalse,
        reason:
            'After a match write, reload authoritative tournament state without requesting geolocation',
      );
      expect(participants.loaded, ['first', 'second', 'second', 'second']);
      expect(main.state.selectedTournament?.id, 'second');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await main.close();
      await participants.close();
      await matches.close();
    },
  );
}
