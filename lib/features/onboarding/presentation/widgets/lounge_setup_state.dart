part of 'lounge_setup_view.dart';

class _LoungeSetupViewState extends State<LoungeSetupView> {
  final int _totalSteps = 9;
  bool _reviewConfirmed = false;
  bool _restoringFields = false;

  // Step 0 - Venue Model Controllers & State
  bool _isChain = false;
  late final TextEditingController _brandNameController;
  late final TextEditingController _branchesCountController;
  late final TextEditingController _branchNameController;

  // Step 1 - Basic Info Controllers
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _cityController;
  late final TextEditingController _addressController;
  late final TextEditingController _opensAtController;
  late final TextEditingController _closesAtController;

  late final TextEditingController _walletPhoneController;
  late final TextEditingController _instapayAccountController;
  Timer? _saveDraftDebounceTimer;
  bool _isSubmitting = false;
  late final TextEditingController _contactPhoneController;

  Uint8List? _mainImageBytes;
  String? _mainImageName;
  List<SelectedImage> _galleryImages = [];

  // KYC Data
  Uint8List? _idCardBytes;
  String? _idCardName;
  Uint8List? _businessDocBytes;
  String? _businessDocName;

  @override
  void initState() {
    super.initState();
    final cubit = context.read<OnboardingCubit>();
    final user = context.read<LoginCubit>().state.user;
    final assignedLoungeId = user?.loungeId;
    if (user != null && assignedLoungeId != null) {
      cubit.restoreDraft(ownerId: user.id, loungeId: assignedLoungeId);
    }
    final draft = cubit.state.draft;
    _walletPhoneController = TextEditingController(text: draft.walletPhone);
    _walletPhoneController.addListener(_onFieldChanged);
    _instapayAccountController = TextEditingController(
      text: draft.instapayAccount,
    );
    _instapayAccountController.addListener(_onFieldChanged);
    _isChain = draft.isChain;
    _contactPhoneController = TextEditingController(text: draft.contactPhone);
    _contactPhoneController.addListener(_onFieldChanged);
    _brandNameController = TextEditingController(text: draft.brandName);
    _branchesCountController = TextEditingController(
      text: draft.branchesCount > 1 ? draft.branchesCount.toString() : '2',
    );
    _branchNameController = TextEditingController(text: draft.branchName);

    _nameController = TextEditingController(text: draft.name);
    _descriptionController = TextEditingController(text: draft.description);
    _cityController = TextEditingController(text: draft.city);
    _addressController = TextEditingController(text: draft.address);
    _opensAtController = TextEditingController(text: draft.opensAt);
    _closesAtController = TextEditingController(text: draft.closesAt);

    _brandNameController.addListener(_onFieldChanged);
    _branchesCountController.addListener(_onFieldChanged);
    _branchNameController.addListener(_onBranchNameChanged);

    _nameController.addListener(_onFieldChanged);
    _descriptionController.addListener(_onFieldChanged);
    _cityController.addListener(_onFieldChanged);
    _addressController.addListener(_onFieldChanged);
    _opensAtController.addListener(_onFieldChanged);
    _closesAtController.addListener(_onFieldChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final loungeId = context.read<LoginCubit>().state.user?.loungeId;
      if (loungeId != null) {
        context.read<OnboardingCubit>().restoreSavedDraft(loungeId);
      }
    });
  }

  void _onBranchNameChanged() {
    if (_isChain && _nameController.text.isEmpty) {
      _nameController.text = _branchNameController.text;
    }
    _onFieldChanged();
  }

  void _onFieldChanged() {
    if (_restoringFields) return;
    _reviewConfirmed = false;
    _saveDraftDebounceTimer?.cancel();
    _saveDraftDebounceTimer = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      final cubit = context.read<OnboardingCubit>();
      final currentDraft = cubit.state.draft;
      final count = int.tryParse(_branchesCountController.text) ?? 1;

      cubit.saveDraft(
        currentDraft.copyWith(
          isChain: _isChain,
          brandName: _brandNameController.text,
          branchesCount: count,
          branchName: _branchNameController.text,
          name: _nameController.text,
          description: _descriptionController.text,
          walletPhone: _walletPhoneController.text,
          instapayAccount: _instapayAccountController.text,
          contactPhone: _contactPhoneController.text,
          city: _cityController.text,
          address: _addressController.text,
          opensAt: _opensAtController.text,
          closesAt: _closesAtController.text,
        ),
      );
    });
  }

  @override
  void dispose() {
    _saveDraftDebounceTimer?.cancel();
    _walletPhoneController.dispose();
    _instapayAccountController.dispose();
    _contactPhoneController.dispose();
    _brandNameController.dispose();
    _branchesCountController.dispose();
    _branchNameController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _cityController.dispose();
    _addressController.dispose();
    _opensAtController.dispose();
    _closesAtController.dispose();
    super.dispose();
  }

  void _onNext(int currentStep) {
    if (_isSubmitting) return;
    _saveFieldsImmediately();
    final onboardingCubit = context.read<OnboardingCubit>();
    if (currentStep < _totalSteps - 1) {
      onboardingCubit.nextStep();
    } else {
      _submit();
    }
  }

  void _onPrevious() {
    if (_isSubmitting) return;
    _reviewConfirmed = false;
    context.read<OnboardingCubit>().previousStep();
  }

  void _saveFieldsImmediately() {
    _saveDraftDebounceTimer?.cancel();
    final cubit = context.read<OnboardingCubit>();
    cubit.saveDraft(
      cubit.state.draft.copyWith(
        name: _nameController.text,
        description: _descriptionController.text,
        city: _cityController.text,
        address: _addressController.text,
        walletPhone: _walletPhoneController.text,
        instapayAccount: _instapayAccountController.text,
        contactPhone: _contactPhoneController.text,
        opensAt: _opensAtController.text,
        closesAt: _closesAtController.text,
        isChain: _isChain,
        brandName: _brandNameController.text,
        branchName: _branchNameController.text,
        branchesCount: int.tryParse(_branchesCountController.text) ?? 1,
      ),
    );
  }

  void _confirmReview(bool value) => setState(() => _reviewConfirmed = value);

  void _setSubmitting(bool value) => setState(() => _isSubmitting = value);

  void _restoreFields(OnboardingState state) {
    _restoringFields = true;
    final draft = state.draft;
    _nameController.text = draft.name;
    _descriptionController.text = draft.description;
    _cityController.text = draft.city;
    _addressController.text = draft.address;
    _contactPhoneController.text = draft.contactPhone;
    _opensAtController.text = draft.opensAt;
    _closesAtController.text = draft.closesAt;
    _walletPhoneController.text = draft.walletPhone;
    _instapayAccountController.text = draft.instapayAccount;
    _brandNameController.text = draft.brandName;
    _branchNameController.text = draft.branchName;
    _branchesCountController.text = draft.branchesCount.toString();
    _restoringFields = false;
    setState(() {
      _isChain = draft.isChain;
      _reviewConfirmed = false;
    });
  }

  void _changeVenueType(bool value) => setState(() => _isChain = value);

  @override
  Widget build(BuildContext context) => _buildScaffold(context);
}
