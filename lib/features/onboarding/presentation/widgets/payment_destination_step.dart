import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../../art_core/widgets/app_text.dart';
import '../../../../art_core/widgets/app_text_field.dart';

class PaymentDestinationStep extends StatelessWidget {
  final TextEditingController walletPhoneController;
  final TextEditingController instapayAccountController;

  const PaymentDestinationStep({
    super.key,
    required this.walletPhoneController,
    required this.instapayAccountController,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      AppText.heading('onboarding_payment.title'.tr(), fontSize: 22),
      const SizedBox(height: 12),
      AppText.body('onboarding_payment.description'.tr(), fontSize: 15),
      const SizedBox(height: 24),
      AppTextField(
        fontSize: 16,
        controller: walletPhoneController,
        label: 'onboarding_payment.wallet'.tr(),
        keyboardType: TextInputType.phone,
      ),
      const SizedBox(height: 16),
      AppTextField(
        fontSize: 16,
        controller: instapayAccountController,
        label: 'onboarding_payment.instapay'.tr(),
      ),
    ],
  );
}
