import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../art_core/app_strings.dart';
import '../../../../art_core/theme/app_colors.dart';
import 'kyc_document_preview.dart';
import '../../../../art_core/widgets/app_text.dart';
import '../../domain/entities/kyc_request.dart';
import '../cubit/kyc_cubit.dart';
import '../cubit/kyc_state.dart';
import 'kyc_snapshot_details.dart';
import 'kyc_rejection_dialog.dart';

class KycInspectionDialog extends StatelessWidget {
  final KycRequest request;
  final KycCubit cubit;
  const KycInspectionDialog({
    super.key,
    required this.request,
    required this.cubit,
  });

  @override
  Widget build(BuildContext context) {
    EasyLocalization.of(context);
    final size = MediaQuery.sizeOf(context);
    return Dialog(
      backgroundColor: AppColors.cardBackground,
      insetPadding: const EdgeInsets.all(16),
      child: SizedBox(
        width: math.min(1000, size.width - 32),
        height: math.min(800, size.height - 32),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: AppText.heading(
                      AppStrings.kycInspection,
                      fontSize: 22,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: SingleChildScrollView(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final details = KycSnapshotDetails(request: request);
                      final documents = _documents(context);
                      if (constraints.maxWidth < 700) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            details,
                            const SizedBox(height: 24),
                            documents,
                          ],
                        );
                      }
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: details),
                          const SizedBox(width: 24),
                          Expanded(child: documents),
                        ],
                      );
                    },
                  ),
                ),
              ),
              const Divider(),
              _actions(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _documents(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      AppText.subHeading(AppStrings.idCardImage, fontSize: 16),
      _document(context, request.idDocumentUrl),
      if (request.businessDocumentUrl?.isNotEmpty == true) ...[
        const SizedBox(height: 20),
        AppText.subHeading(AppStrings.businessDocImage, fontSize: 16),
        _document(context, request.businessDocumentUrl!),
      ],
    ],
  );

  Widget _document(BuildContext context, String url) =>
      KycDocumentPreview(url: url);

  Widget _actions(BuildContext context) => BlocBuilder<KycCubit, KycState>(
    bloc: cubit,
    buildWhen: (previous, current) =>
        previous.status != current.status ||
        previous.errorMessage != current.errorMessage,
    builder: (context, state) {
      final busy = state.status == KycStatus.loading;
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (state.status == KycStatus.failure)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                state.errorMessage ?? AppStrings.actionFailed,
                style: const TextStyle(color: AppColors.danger),
              ),
            ),
          OverflowBar(
            spacing: 12,
            overflowSpacing: 8,
            children: [
              OutlinedButton(
                onPressed: busy ? null : () => _reject(context),
                child: Text(AppStrings.reject),
              ),
              FilledButton(
                onPressed: busy ? null : () => _decide(context, true),
                child: busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(AppStrings.approve),
              ),
            ],
          ),
        ],
      );
    },
  );

  Future<void> _reject(BuildContext context) async {
    final notes = await showDialog<String>(
      context: context,
      builder: (_) => const KycRejectionDialog(),
    );
    if (notes != null && context.mounted) await _decide(context, false, notes);
  }

  Future<void> _decide(
    BuildContext context,
    bool approve, [
    String? notes,
  ]) async {
    final accepted = await cubit.reviewKyc(
      requestId: request.submissionId,
      revision: request.revision,
      approve: approve,
      notes: notes,
    );
    if (accepted && context.mounted) Navigator.pop(context);
  }
}
