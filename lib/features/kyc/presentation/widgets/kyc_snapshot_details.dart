import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../../art_core/widgets/app_text.dart';
import '../../domain/entities/kyc_request.dart';

class KycSnapshotDetails extends StatelessWidget {
  final KycRequest request;
  const KycSnapshotDetails({super.key, required this.request});

  @override
  Widget build(BuildContext context) {
    final lounge = request.snapshot['lounge'] as Map? ?? const {};
    final rooms = request.snapshot['rooms'] as List? ?? const [];
    final extras = request.snapshot['extras'] as List? ?? const [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.subHeading(
          'kyc_snapshot.title'.tr(args: [request.revision.toString()]),
          fontSize: 18,
        ),
        _detail('owner', '${request.ownerName} · ${request.ownerEmail}'),
        for (final key in [
          'name',
          'city',
          'address',
          'contact_phone',
          'opening_time',
          'closing_time',
          'location_point',
          'vodafone_cash_number',
          'instapay_account',
          'description_ar',
          'description_en',
        ])
          if (lounge[key] != null && lounge[key].toString().isNotEmpty)
            _detail(key, lounge[key].toString()),
        const Divider(),
        AppText.subHeading('onboarding_review.rooms'.tr(), fontSize: 18),
        for (final room in rooms.whereType<Map>()) _room(context, room),
        const Divider(),
        AppText.subHeading(
          'onboarding_review.products'.tr(args: [extras.length.toString()]),
          fontSize: 18,
        ),
        for (final extra in extras.whereType<Map>())
          _detail(
            'product',
            '${_name(context, extra)} · ${extra['price'] ?? '—'}',
          ),
      ],
    );
  }

  Widget _detail(String key, String value) => Padding(
    padding: const EdgeInsetsDirectional.only(bottom: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.body('kyc_snapshot.$key'.tr(), fontSize: 12),
        AppText.body(value, fontSize: 15),
      ],
    ),
  );

  String _name(BuildContext context, Map resource) =>
      (resource[context.locale.languageCode == 'ar' ? 'name_ar' : 'name_en'] ??
              resource['name'] ??
              '—')
          .toString();

  Widget _room(BuildContext context, Map room) => Padding(
    padding: const EdgeInsetsDirectional.only(top: 8, bottom: 8),
    child: AppText.body(
      'onboarding_review.room'.tr(
        args: [
          _name(context, room),
          '${room['max_capacity'] ?? '—'}',
          '${room['hourly_rate_single'] ?? '—'}',
          '${room['hourly_rate_multi'] ?? '—'}',
        ],
      ),
      fontSize: 15,
    ),
  );
}
