import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text.dart';
import 'package:play_spot_dashboard/features/bookings/domain/entities/booking.dart';
import 'package:play_spot_dashboard/features/lounges/domain/entities/extra_entity.dart';
import 'package:play_spot_dashboard/features/lounges/presentation/cubit/extras_cubit.dart';

import 'package:play_spot_dashboard/core/utils/item_name_resolver.dart';

/// Redesigned Products & Canteen Items Section on Booking Card
/// Itemizes canteen orders and extras directly on the card so cashiers
/// can see exact product names (e.g. بيبسي) and quantities without opening dialogs.
class BookingProductsPreview extends StatelessWidget {
  final Booking booking;
  final int maxVisibleItems;

  const BookingProductsPreview({
    super.key,
    required this.booking,
    this.maxVisibleItems = 3,
  });

  String _resolveItemName(Map itemMap, List<ExtraEntity> availableExtras) {
    return resolveItemName(Map<String, dynamic>.from(itemMap), availableExtras);
  }

  List<Map<String, dynamic>> _extractAllOrderedItems(List<ExtraEntity> availableExtras) {
    final List<Map<String, dynamic>> items = [];

    for (final extra in booking.extras) {
      final name = _resolveItemName(extra, availableExtras);
      final qty = (extra['quantity'] ?? extra['qty'] ?? extra['count'] as num?)?.toInt() ?? 1;
      final unitPrice = (extra['unit_price'] ?? extra['price'] as num?)?.toDouble() ?? 0.0;
      final totalPrice = (extra['total_price'] as num?)?.toDouble() ?? (unitPrice * qty);
      items.add({
        'name': name,
        'qty': qty,
        'unit_price': unitPrice,
        'price': unitPrice,
        'total_price': totalPrice,
        'type': 'extra',
      });
    }

    for (final order in booking.canteenOrders) {
      final List<dynamic> sourceLists = [
        order['items'],
        order['canteen_order_items'],
        order['canteen_items'],
      ];

      for (var rawItems in sourceLists) {
        if (rawItems is String && rawItems.trim().isNotEmpty) {
          try {
            rawItems = jsonDecode(rawItems);
          } catch (_) {}
        }
        if (rawItems is List) {
          for (final item in rawItems) {
            if (item is Map) {
              final name = _resolveItemName(item, availableExtras);
              final qty = (item['quantity'] ?? item['qty'] ?? item['count'] as num?)?.toInt() ?? 1;
              final unitPrice = (item['unit_price'] ?? item['price'] as num?)?.toDouble() ?? 0.0;
              final totalPrice = (item['total_price'] as num?)?.toDouble() ?? (unitPrice * qty);
              
              final alreadyExists = items.any((existing) => 
                existing['name'].toString().toLowerCase() == name.toLowerCase() && 
                existing['qty'] == qty
              );
              if (!alreadyExists) {
                items.add({
                  'name': name,
                  'qty': qty,
                  'unit_price': unitPrice,
                  'price': unitPrice,
                  'total_price': totalPrice,
                  'type': 'canteen',
                });
              }
            }
          }
        }
      }
    }

    return items;
  }

  IconData _getItemIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('بيبسي') || lower.contains('بيسي') || lower.contains('كوكا') || lower.contains('مشروب') || lower.contains('ماء') || lower.contains('cola') || lower.contains('water') || lower.contains('drink') || lower.contains('عصير') || lower.contains('pepsi')) {
      return Icons.local_drink_rounded;
    }
    if (lower.contains('قهوة') || lower.contains('شاي') || lower.contains('coffee') || lower.contains('tea') || lower.contains('نسكافيه')) {
      return Icons.coffee_rounded;
    }
    if (lower.contains('دراع') || lower.contains('controller') || lower.contains('ألعاب')) {
      return Icons.sports_esports_rounded;
    }
    return Icons.fastfood_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final extrasCubit = context.watch<ExtrasCubit?>();
    if (extrasCubit != null && extrasCubit.state.extras.isEmpty && booking.loungeId.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          extrasCubit.loadExtras(booking.loungeId);
        }
      });
    }
    final List<ExtraEntity> availableExtras = extrasCubit?.state.extras ?? [];

    final allItems = _extractAllOrderedItems(availableExtras);

    if (allItems.isEmpty) {
      return const SizedBox.shrink();
    }

    final int overflowCount = allItems.length - maxVisibleItems;
    final visibleItems = allItems.take(maxVisibleItems).toList();

    return Container(
      margin: EdgeInsets.only(top: 4.h, bottom: 2.h),
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: AppColors.mutedBackground.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: AppColors.neonPurple.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.restaurant_menu_rounded, size: 12.r, color: AppColors.neonPurple),
                  SizedBox(width: 4.w),
                  AppText.body(
                    'الطلبات والمنتجات (${allItems.length}):',
                    fontSize: 9.5.sp,
                    color: AppColors.neonPurple,
                    fontWeight: FontWeight.bold,
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 2.h),
          ...visibleItems.map((item) {
            final String name = item['name'];
            final int qty = item['qty'];
            final double price = item['price'];
            final double itemTotal = price * qty;
            final IconData itemIcon = _getItemIcon(name);

            return Padding(
              padding: EdgeInsets.symmetric(vertical: 1.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(itemIcon, size: 10.r, color: AppColors.neonCyan),
                        SizedBox(width: 4.w),
                        Expanded(
                          child: Text(
                            '${qty}x $name',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 9.5.sp,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (itemTotal > 0)
                    Text(
                      '${itemTotal.toStringAsFixed(0)} ج.م',
                      style: TextStyle(
                        color: AppColors.neonGreen,
                        fontSize: 9.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            );
          }),
          if (overflowCount > 0) ...[
            SizedBox(height: 2.h),
            Text(
              '+ $overflowCount أصناف أخرى (اضغط لمعاينة الكل)',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 8.5.sp,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
