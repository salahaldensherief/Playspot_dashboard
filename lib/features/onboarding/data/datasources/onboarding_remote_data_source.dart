import '../../../lounges/data/models/lounge_model.dart';
import '../../../lounges/domain/entities/lounge.dart';
import '../../../rooms/data/models/room_model.dart';

abstract class OnboardingRemoteDataSource {
  Future<LoungeModel> setupLounge(Lounge lounge);
  Future<LoungeModel> batchCompleteOnboarding({
    required String loungeId,
    required Map<String, dynamic> loungeData,
    required List<Map<String, dynamic>> rooms,
    required List<Map<String, dynamic>> extras,
  });
  Future<void> updateLoungeData(String id, Map<String, dynamic> data);
  Future<RoomModel> addRoom(RoomModel room);
}
