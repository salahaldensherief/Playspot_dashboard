import 'package:easy_localization/easy_localization.dart';
import '../../domain/services/onboarding_submission_validator.dart';
import 'onboarding_review_summary.dart';
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_multi_image_picker.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text.dart';
import 'package:play_spot_dashboard/features/auth/presentation/login/login_cubit.dart';
import 'package:play_spot_dashboard/features/lounges/domain/entities/lounge.dart';
import 'package:play_spot_dashboard/features/kyc/presentation/cubit/kyc_cubit.dart';
import 'package:play_spot_dashboard/features/kyc/presentation/cubit/kyc_state.dart';
import 'package:play_spot_dashboard/features/kyc/presentation/widgets/kyc_step.dart';
import 'package:play_spot_dashboard/features/onboarding/presentation/cubit/onboarding_cubit.dart';
import 'package:play_spot_dashboard/features/onboarding/presentation/cubit/onboarding_state.dart';
import 'package:play_spot_dashboard/features/onboarding/presentation/widgets/venue_type_step.dart';
import 'package:play_spot_dashboard/features/onboarding/presentation/widgets/basic_info_step.dart';
import 'package:play_spot_dashboard/features/onboarding/presentation/widgets/location_step.dart';
import 'package:play_spot_dashboard/features/onboarding/presentation/widgets/operating_hours_step.dart';
import 'package:play_spot_dashboard/features/onboarding/presentation/widgets/assets_step.dart';
import 'package:play_spot_dashboard/features/onboarding/presentation/widgets/marketplace_step.dart';

part 'lounge_setup_state.dart';
part 'lounge_setup_submission.dart';
part 'lounge_setup_content.dart';
part 'lounge_setup_sections.dart';

class LoungeSetupView extends StatefulWidget {
  const LoungeSetupView({super.key});

  @override
  State<LoungeSetupView> createState() => _LoungeSetupViewState();
}
