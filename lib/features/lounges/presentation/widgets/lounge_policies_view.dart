import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:play_spot_dashboard/core/di/di.dart';
import '../cubit/lounge_payment_settings_cubit.dart';
import 'lounge_policies_form.dart';

/// Lounge Policies & Payment Settings Screen / Widget
/// (شاشة إعدادات سياسات الدفع والحجوزات)
class LoungePoliciesView extends StatelessWidget {
  const LoungePoliciesView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<LoungePaymentSettingsCubit>(),
      child: const LoungePoliciesForm(),
    );
  }
}
