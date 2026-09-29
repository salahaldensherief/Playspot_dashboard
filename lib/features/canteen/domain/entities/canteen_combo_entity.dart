import 'package:equatable/equatable.dart';
import 'canteen_combo_component_entity.dart';

class CanteenComboEntity extends Equatable {
  final String id;
  final String loungeId;
  final String nameAr;
  final String? nameEn;
  final String? descriptionAr;
  final String? descriptionEn;
  final String? imageUrl;
  final double price;
  final List<int>? daysOfWeek;
  final String? availableFrom;
  final String? availableTo;
  final DateTime? validFrom;
  final DateTime? validTo;
  final bool isActive;
  final int sortOrder;
  final List<CanteenComboComponentEntity> items;

  const CanteenComboEntity({
    required this.id,
    required this.loungeId,
    required this.nameAr,
    this.nameEn,
    this.descriptionAr,
    this.descriptionEn,
    this.imageUrl,
    required this.price,
    this.daysOfWeek,
    this.availableFrom,
    this.availableTo,
    this.validFrom,
    this.validTo,
    this.isActive = true,
    this.sortOrder = 0,
    this.items = const [],
  });

  double get separateItemsTotal {
    double total = 0.0;
    for (final item in items) {
      total += (item.extraPrice ?? 0.0) * item.quantity;
    }
    return total;
  }

  double get estimatedCostTotal {
    double total = 0.0;
    for (final item in items) {
      if (item.extraCostPrice != null) {
        total += item.extraCostPrice! * item.quantity;
      }
    }
    return total;
  }

  double? get profitMargin {
    final cost = estimatedCostTotal;
    if (cost <= 0 || price <= 0) return null;
    return price - cost;
  }

  double? get profitMarginPercent {
    final margin = profitMargin;
    if (margin == null || price <= 0) return null;
    return (margin / price) * 100.0;
  }

  double get savings => (separateItemsTotal > price) ? (separateItemsTotal - price) : 0.0;

  @override
  List<Object?> get props => [
        id,
        loungeId,
        nameAr,
        nameEn,
        descriptionAr,
        descriptionEn,
        imageUrl,
        price,
        daysOfWeek,
        availableFrom,
        availableTo,
        validFrom,
        validTo,
        isActive,
        sortOrder,
        items,
      ];
}
