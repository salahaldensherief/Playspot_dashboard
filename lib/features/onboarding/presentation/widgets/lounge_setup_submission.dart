part of 'lounge_setup_view.dart';

extension _LoungeSetupSubmission on _LoungeSetupViewState {
  Future<void> _submit() async {
    if (_isSubmitting || !_canSubmit()) return;
    final user = context.read<LoginCubit>().state.user;
    final userId = user?.id;
    final loungeId = user?.loungeId;
    if (userId == null || loungeId == null) return;
    _isSubmitting = true;
    try {
      await _uploadKyc(userId);
      if (!mounted ||
          context.read<KycCubit>().state.status != KycStatus.success) {
        return;
      }
      await _submitLoungeDetails(loungeId);
    } finally {
      _isSubmitting = false;
    }
  }

  bool _canSubmit() {
    _saveFieldsImmediately();
    final cubit = context.read<OnboardingCubit>();
    final user = context.read<LoginCubit>().state.user;
    final validation = OnboardingSubmissionValidator.validate(
      cubit.state.draft,
      roomCount: cubit.state.rooms.length,
      hasMainImage:
          _mainImageBytes?.isNotEmpty == true && _mainImageName != null,
      hasIdentityDocument:
          _idCardBytes?.isNotEmpty == true && _idCardName != null,
    );
    final error =
        (!_reviewConfirmed ? 'onboarding_review.confirm_required' : null) ??
        validation ??
        ((user?.id.isNotEmpty != true || user?.loungeId?.isNotEmpty != true)
            ? 'onboarding_validation.session_required'
            : null);
    if (error == null) return true;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: AppText.body(error.tr())));
    return false;
  }

  Future<void> _uploadKyc(String userId) async {
    final bytes = _idCardBytes;
    final name = _idCardName;
    if (bytes == null || name == null) return;
    await context.read<KycCubit>().submitKyc(
      userId: userId,
      idCardBytes: bytes,
      idCardName: name,
      businessDocBytes: _businessDocBytes,
      businessDocName: _businessDocName,
    );
  }

  Future<void> _submitLoungeDetails(String loungeId) async {
    final cubit = context.read<OnboardingCubit>();
    final draft = cubit.state.draft;
    await cubit.submitLounge(
      lounge: Lounge(
        id: loungeId,
        name: draft.name,
        descriptionEn: draft.description,
        city: draft.city,
        location: draft.address,
        opensAt: draft.opensAt,
        closesAt: draft.closesAt,
        imageUrl: '',
        lat: draft.lat,
        lng: draft.lng,
      ),
      mainImageBytes: _mainImageBytes,
      mainImageName: _mainImageName,
      galleryImages: _galleryImages,
      loungeId: loungeId,
      context: context,
    );
  }
}
