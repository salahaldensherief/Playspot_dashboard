import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:play_spot_dashboard/core/services/local_cache_service.dart';
import 'package:play_spot_dashboard/features/lounges/data/datasources/lounge_remote_data_source.dart';
import 'package:play_spot_dashboard/features/lounges/data/repositories/lounge_cache_helper.dart';
import 'package:play_spot_dashboard/features/lounges/domain/entities/lounge.dart';

class _Cache extends Mock implements LocalCacheService {}
class _Remote extends Mock implements LoungeRemoteDataSource {}

void main() {
  test('lounge profile conversion keeps payment and cash settings', () {
    final lounge = Lounge(
      id: 'lounge-1',
      name: 'PlaySpot',
      imageUrl: '',
      opensAt: '10:00:00',
      closesAt: '23:00:00',
      vodafoneCashNumber: '',
      instapayAccount: 'user@instapay',
      allowCashPayment: false,
      requirePrepaidFirstTime: true,
      cashGracePeriodMinutes: 20,
      isActive: true,
    );

    final data = LoungeCacheHelper(_Cache(), _Remote()).toModel(lounge).toJson();

    expect(data['vodafone_cash_number'], '');
    expect(data['instapay_account'], 'user@instapay');
    expect(data['allow_cash_payment'], false);
    expect(data['require_prepaid_first_time'], true);
    expect(data['cash_grace_period_minutes'], 20);
  });
}
