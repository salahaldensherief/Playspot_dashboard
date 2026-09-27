import 'package:play_spot_dashboard/features/rooms/data/models/room_model.dart';
import '../models/extra_model.dart';
import '../models/lounge_model.dart';

abstract class LoungeRemoteDataSource {
  Future<List<LoungeModel>> getLounges();
  Future<List<LoungeModel>> getOwnerBranches(String ownerId);
  Future<Map<String, dynamic>> addLoungeBranch(Map<String, dynamic> branchData);
  Future<Map<String, dynamic>> getMultiBranchOverview({
    required String ownerId,
    required DateTime startDate,
    required DateTime endDate,
  });
  Future<LoungeModel?> getLoungeById(String id);
  Future<Map<String, dynamic>> createLoungeWithOwner({
    required String email,
    required String password,
    required String ownerName,
    required String loungeName,
    String? city,
    String? address,
    String? phone,
  });
  Future<void> updateLounge(String id, Map<String, dynamic> data);
  Future<void> updateLoungeDiscount(String id, {
    required bool hasDiscount,
    required int discountPercentage,
    String? titleAr,
    String? titleEn,
    DateTime? expiresAt,
    String? vodafoneCashNumber,
    String? instapayAccount,
  });
  Future<Map<String, dynamic>> getDashboardStats(String? loungeId);
  Future<Map<String, dynamic>> getDashboardOverview();
  Future<List<Map<String, dynamic>>> getRevenueOverTime(int daysBack);
  Future<List<Map<String, dynamic>>> getTopLoungesByRevenue(int limitCount);

  // Rooms & Activities
  Future<List<RoomModel>> getRooms(String loungeId);
  Future<List<Map<String, dynamic>>> getActivities(String roomId);

  // Extras
  Future<List<ExtraModel>> getExtras(String loungeId);
  Future<void> addExtra(ExtraModel extra);
  Future<void> updateExtra(ExtraModel extra);
  Future<void> deleteExtra(String extraId);
  Future<void> toggleExtraStock(String extraId, bool isOutOfStock);
  Future<void> toggleLoungeOpenStatus(String loungeId, bool isOpen);
  Future<void> deleteLounge(String id);

  // Legacy methods - kept for compatibility if needed
  Future<String> createLounge(LoungeModel lounge);
  Future<void> createLoungeAdmin({
    required String email,
    required String password,
    required String name,
    required String loungeId,
  });
}
