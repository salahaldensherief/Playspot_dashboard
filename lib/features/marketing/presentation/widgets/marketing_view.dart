import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
import 'package:play_spot_dashboard/features/auth/presentation/login/login_cubit.dart';
import 'package:play_spot_dashboard/features/rooms/presentation/cubit/room_cubit.dart';
import 'package:play_spot_dashboard/features/rooms/presentation/cubit/room_state.dart';
import '../../domain/entities/promo_entity.dart';
import '../../domain/entities/notification_entity.dart';
import '../cubit/marketing_cubit.dart';
import '../cubit/marketing_state.dart';
import 'promo_form_section.dart';
import 'design_style_section.dart';
import 'promo_dialog.dart';
import 'notification_dialog.dart';
import 'promo_card.dart';

class MarketingView extends StatefulWidget {
  const MarketingView({super.key});

  @override
  State<MarketingView> createState() => _MarketingViewState();
}

class _MarketingViewState extends State<MarketingView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  String _selectedFilterTag = 'All';
  late TextEditingController _titleArController;
  late TextEditingController _titleEnController;
  late TextEditingController _expirationDateController;
  DateTime? _expiresAt;
  String? _selectedTag;
  bool _isRoomSpecific = false;
  String? _selectedRoomId;
  String _targetAudience = 'all';
  Uint8List? _selectedImageBytes;
  String? _selectedImageName;
  bool _isUploading = false;

  final List<List<Color>> _colorTemplates = [
    [AppColors.neonPurple, AppColors.neonBlue],
    [Colors.orange, Colors.red],
    [Colors.green, Colors.teal],
    [Colors.blue, Colors.indigo],
  ];

  int _selectedTemplate = 0;
  String _selectedIcon = 'Flash';
  String _selectedDeepLink = 'Specific Room';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _titleArController = TextEditingController();
    _titleEnController = TextEditingController();
    _expirationDateController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<LoginCubit>().state.user;
      final loungeId = user?.loungeId;
      if (loungeId != null) {
        context.read<RoomCubit>().watchRooms(loungeId);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleArController.dispose();
    _titleEnController.dispose();
    _expirationDateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.read<LoginCubit>().state.user;
    final isSuperAdmin = user?.role.name == 'superAdmin';
    final marketingCubit = context.read<MarketingCubit>();

    return BlocListener<MarketingCubit, MarketingState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        if (state.status == MarketingStatus.actionSuccess) {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppStrings.promoPublishedSuccess),
              backgroundColor: Colors.green,
            ),
          );
        } else if (state.status == MarketingStatus.failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage ?? AppStrings.promoPublishError),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Padding(
        padding: EdgeInsets.all(24.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppStrings.marketing,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 28.sp,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Orbitron',
                  ),
                ),
                if (isSuperAdmin)
                  Row(
                    children: [
                      AppButton(
                        text: AppStrings.newNotification,
                        onPressed: () => _showNotificationDialog(context, marketingCubit),
                        icon: Icons.notifications_active_outlined,
                        variant: AppButtonVariant.outlined,
                      ),
                      SizedBox(width: 16.w),
                      AppButton(
                        text: AppStrings.createGlobalPromo,
                        onPressed: () => _showEditPromoDialog(context, marketingCubit, const PromoEntity(id: '', titleAr: '', titleEn: '', tagAr: '', tagEn: '', hexColors: [], iconKey: '')),
                        icon: Icons.add,
                      ),
                    ],
                  ),
              ],
            ),
            SizedBox(height: 32.h),
            if (isSuperAdmin) ...[
              TabBar(
                controller: _tabController,
                isScrollable: true,
                labelColor: AppColors.neonBlue,
                indicatorColor: AppColors.neonBlue,
                tabs: [
                  Tab(text: AppStrings.promotionsTab),
                  Tab(text: AppStrings.notificationsTab),
                ],
              ),
              SizedBox(height: 24.h),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildPromotionsList(marketingCubit),
                    _buildNotificationsList(marketingCubit),
                  ],
                ),
              ),
            ] else
              Expanded(child: SingleChildScrollView(child: _buildLoungeAdminForm())),
          ],
        ),
      ),
    );
  }

  Widget _buildLoungeAdminForm() {
    return BlocBuilder<RoomCubit, RoomState>(
      builder: (context, roomState) {
        return Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: PromoFormSection(
                      titleArController: _titleArController,
                      titleEnController: _titleEnController,
                      expirationDateController: _expirationDateController,
                      selectedDeepLink: _selectedDeepLink,
                      onDeepLinkChanged: (v) => setState(() => _selectedDeepLink = v ?? 'Lounge Profile'),
                      expiresAt: _expiresAt,
                      onDateChanged: (v) => setState(() {
                        _expiresAt = v;
                        _expirationDateController.text = v.toLocal().toString().split(' ')[0];
                      }),
                      selectedTag: _selectedTag,
                      onTagChanged: (v) => setState(() => _selectedTag = v),
                      isRoomSpecific: _isRoomSpecific,
                      onRoomSpecificChanged: (v) => setState(() => _isRoomSpecific = v),
                      selectedRoomId: _selectedRoomId,
                      onRoomChanged: (v) => setState(() => _selectedRoomId = v),
                      targetAudience: _targetAudience,
                      onTargetAudienceChanged: (v) => setState(() => _targetAudience = v),
                      availableRooms: roomState.rooms,
                    ),
                  ),
                  SizedBox(width: 32.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.promoPoster,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 16.h),
                        GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            height: 300.h,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: AppColors.mutedBackground,
                              borderRadius: BorderRadius.circular(12.r),
                              border: Border.all(color: AppColors.borderDefault),
                              image: _selectedImageBytes != null
                                  ? DecorationImage(
                                      image: MemoryImage(_selectedImageBytes!),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: _selectedImageBytes == null
                                ? Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.add_photo_alternate_outlined, size: 48.r, color: AppColors.textSecondary),
                                      SizedBox(height: 8.h),
                                      Text(AppStrings.uploadPoster, style: TextStyle(color: AppColors.textSecondary, fontSize: 12.sp)),
                                    ],
                                  )
                                : Align(
                                    alignment: Alignment.topRight,
                                    child: IconButton(
                                      onPressed: () => setState(() => _selectedImageBytes = null),
                                      icon: Container(
                                        padding: EdgeInsets.all(4.r),
                                        decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                                        child: const Icon(Icons.close, color: Colors.white, size: 16),
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                        if (_selectedImageBytes != null) ...[
                          SizedBox(height: 12.h),
                          AppButton(
                            text: AppStrings.changePoster,
                            onPressed: _pickImage,
                            variant: AppButtonVariant.outlined,
                            height: 36.h,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 32.h),
              DesignStyleSection(
                colorTemplates: _colorTemplates,
                selectedTemplate: _selectedTemplate,
                onTemplateSelected: (index) => setState(() => _selectedTemplate = index),
                selectedIcon: _selectedIcon,
                onIconChanged: (v) => setState(() => _selectedIcon = v ?? 'Flash'),
              ),
              SizedBox(height: 40.h),
              AppButton(
                text: AppStrings.createPromotion,
                isLoading: _isUploading,
                onPressed: _isUploading
                    ? null
                    : () async {
                        if (_formKey.currentState!.validate()) {
                          setState(() => _isUploading = true);
                          String? imageUrl;
                          if (_selectedImageBytes != null) {
                            imageUrl = await context.read<MarketingCubit>().uploadPromoPoster(_selectedImageBytes!, _selectedImageName ?? 'promo.png');
                          }

                          final promo = PromoEntity(
                            id: '',
                            titleAr: _titleArController.text,
                            titleEn: _titleEnController.text,
                            tagAr: _selectedTag ?? '',
                            tagEn: _selectedTag ?? '',
                            hexColors: _colorTemplates[_selectedTemplate].map((e) => '#${e.value.toRadixString(16).substring(2)}').toList(),
                            iconKey: _selectedIcon,
                            deepLink: _selectedDeepLink,
                            expiresAt: _expiresAt,
                            tag: _selectedTag,
                            isRoomSpecific: _isRoomSpecific,
                            roomId: _selectedRoomId,
                            targetAudience: _targetAudience,
                            imageUrl: imageUrl,
                          );
                          if (mounted) {
                            context.read<MarketingCubit>().createPromotion(promo);
                            setState(() {
                              _isUploading = false;
                              _selectedImageBytes = null;
                            });
                          }
                        }
                      },
                width: 250.w,
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null) {
      setState(() {
        _selectedImageBytes = result.files.first.bytes;
        _selectedImageName = result.files.first.name;
      });
    }
  }

  Widget _buildPromotionsList(MarketingCubit cubit) {
    return BlocBuilder<MarketingCubit, MarketingState>(
      buildWhen: (previous, current) =>
          previous.promotions != current.promotions ||
          previous.status != current.status,
      builder: (context, state) {
        if (state.status == MarketingStatus.loading) {
          return const Center(child: CircularProgressIndicator(color: AppColors.neonBlue));
        }

        final tags = ['All', ...state.promotions.map((p) => p.tag).whereType<String>().toSet()];
        final filteredPromos = _selectedFilterTag == 'All' ? state.promotions : state.promotions.where((p) => p.tag == _selectedFilterTag).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: tags
                    .map((tag) => Padding(
                          padding: EdgeInsets.only(right: 8.w),
                          child: FilterChip(
                            label: Text(tag),
                            selected: _selectedFilterTag == tag,
                            onSelected: (selected) {
                              setState(() {
                                _selectedFilterTag = tag;
                              });
                            },
                            selectedColor: AppColors.neonBlue.withOpacity(0.2),
                            checkmarkColor: AppColors.neonBlue,
                          ),
                        ))
                    .toList(),
              ),
            ),
            SizedBox(height: 24.h),
            if (filteredPromos.isEmpty)
              Expanded(child: Center(child: Text(AppStrings.noPromotions, style: const TextStyle(color: AppColors.textSecondary))))
            else
              Expanded(
                child: GridView.builder(
                  gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 400.w,
                    mainAxisExtent: 220.h,
                    crossAxisSpacing: 24.w,
                    mainAxisSpacing: 24.h,
                  ),
                  itemCount: filteredPromos.length,
                  itemBuilder: (context, index) {
                    final promo = filteredPromos[index];
                    return PromoCard(
                      promo: promo,
                      onEdit: () => _showEditPromoDialog(context, cubit, promo),
                      onDelete: () => _confirmDelete(context, cubit, promo),
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildNotificationsList(MarketingCubit cubit) {
    return BlocBuilder<MarketingCubit, MarketingState>(
      buildWhen: (previous, current) =>
          previous.notifications != current.notifications ||
          previous.status != current.status,
      builder: (context, state) {
        if (state.status == MarketingStatus.loading) return const Center(child: CircularProgressIndicator());
        if (state.notifications.isEmpty) return Center(child: Text(AppStrings.noNotifications, style: const TextStyle(color: AppColors.textSecondary)));

        return ListView.separated(
          itemCount: state.notifications.length,
          separatorBuilder: (_, __) => Divider(color: AppColors.borderDefault),
          itemBuilder: (context, index) {
            final n = state.notifications[index];
            return ListTile(
              leading: Icon(_getNotifyIcon(n.type), color: AppColors.neonBlue),
              title: Text(n.titleEn, style: const TextStyle(color: AppColors.textPrimary)),
              subtitle: Text(n.bodyEn, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.textSecondary)),
              trailing: Text(DateFormat('yyyy-MM-dd HH:mm').format(n.createdAt), style: TextStyle(color: AppColors.textMuted, fontSize: 12.sp)),
            );
          },
        );
      },
    );
  }

  IconData _getNotifyIcon(NotificationType type) {
    switch (type) {
      case NotificationType.offer: return Icons.local_offer_outlined;
      case NotificationType.booking: return Icons.event_available;
      case NotificationType.loyalty: return Icons.card_giftcard;
      default: return Icons.info_outline;
    }
  }

  DataRow _buildPromoRow(BuildContext context, MarketingCubit cubit, PromoEntity promo) {
    return DataRow(cells: [
      DataCell(Text(promo.titleEn, style: const TextStyle(color: AppColors.textPrimary))),
      DataCell(Container(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
        decoration: BoxDecoration(color: AppColors.neonBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(4.r)),
        child: Text(promo.tagEn, style: const TextStyle(color: AppColors.neonBlue, fontWeight: FontWeight.bold)),
      )),
      DataCell(Text(promo.deepLink ?? 'Global', style: const TextStyle(color: AppColors.textSecondary))),
      DataCell(Text(AppStrings.active, style: const TextStyle(color: AppColors.success))),
      DataCell(Row(
        children: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: AppColors.textSecondary, size: 20), 
            onPressed: () => _showEditPromoDialog(context, cubit, promo),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.danger, size: 20), 
            onPressed: () => _confirmDelete(context, cubit, promo),
          ),
        ],
      )),
    ]);
  }

  void _showEditPromoDialog(BuildContext context, MarketingCubit cubit, PromoEntity promo) {
    showDialog(
      context: context,
      builder: (diagContext) => PromoDialog(
        promo: promo,
        onSave: (updatedPromo) {
          cubit.createPromotion(updatedPromo);
        },
      ),
    );
  }

  void _showNotificationDialog(BuildContext context, MarketingCubit cubit) {
    showDialog(
      context: context,
      builder: (diagContext) => NotificationDialog(
        onSend: (n) => cubit.sendNotification(n),
      ),
    );
  }

  void _confirmDelete(BuildContext context, MarketingCubit cubit, PromoEntity promo) {
    showDialog(
      context: context,
      builder: (diagContext) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: Text(AppStrings.deleteConfirmation, style: const TextStyle(color: AppColors.textPrimary)),
        content: Text('${AppStrings.deleteWarning} "${promo.titleEn}"?'),
        actions: [
          AppButton(
            text: AppStrings.cancel,
            variant: AppButtonVariant.outlined,
            onPressed: () => Navigator.pop(diagContext),
          ),
          AppButton(
            text: AppStrings.delete,
            variant: AppButtonVariant.danger,
            onPressed: () {
              cubit.deletePromotion(promo.id);
              Navigator.pop(diagContext);
            },
          ),
        ],
      ),
    );
  }
}
