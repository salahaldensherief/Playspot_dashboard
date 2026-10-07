import 'package:flutter_test/flutter_test.dart';
import 'package:play_spot_dashboard/features/canteen/data/models/canteen_combo_model.dart';
import 'package:play_spot_dashboard/features/canteen/data/models/low_stock_alert_model.dart';
import 'package:play_spot_dashboard/features/canteen/data/models/upsell_conversion_model.dart';
import 'package:play_spot_dashboard/features/canteen/data/models/upsell_rule_model.dart';
import 'package:play_spot_dashboard/features/canteen/domain/entities/canteen_combo_component_entity.dart';
import 'package:play_spot_dashboard/features/canteen/domain/entities/canteen_combo_entity.dart';
import 'package:play_spot_dashboard/features/requests/data/models/canteen_item_extractor.dart';

void main() {
  group('Canteen Combo Financial & Margin Analytics', () {
    test(
      'calculates separate items total, cost total, profit margin, and customer savings correctly',
      () {
        final combo = CanteenComboEntity(
          id: 'combo-1',
          loungeId: 'lounge-1',
          nameAr: 'كومبو الأبطال',
          price: 80.0,
          items: const [
            CanteenComboComponentEntity(
              comboId: 'combo-1',
              extraId: 'extra-1',
              quantity: 2,
              extraNameAr: 'بيبسي',
              extraPrice: 25.0,
              extraCostPrice: 15.0,
            ),
            CanteenComboComponentEntity(
              comboId: 'combo-1',
              extraId: 'extra-2',
              quantity: 1,
              extraNameAr: 'شيبسي',
              extraPrice: 40.0,
              extraCostPrice: 20.0,
            ),
          ],
        );

        // Separate items total: (2 * 25) + (1 * 40) = 90 EGP
        expect(combo.separateItemsTotal, equals(90.0));

        // Estimated cost total: (2 * 15) + (1 * 20) = 50 EGP
        expect(combo.estimatedCostTotal, equals(50.0));

        // Customer savings: 90 - 80 = 10 EGP
        expect(combo.savings, equals(10.0));

        // Profit margin: 80 - 50 = 30 EGP
        expect(combo.profitMargin, equals(30.0));

        // Margin percentage: (30 / 80) * 100 = 37.5%
        expect(combo.profitMarginPercent, equals(37.5));
      },
    );

    test('handles combo without image and null cost prices gracefully', () {
      final combo = CanteenComboEntity(
        id: 'combo-2',
        loungeId: 'lounge-1',
        nameAr: 'عرض بدون صورة',
        imageUrl: null,
        price: 50.0,
        items: const [
          CanteenComboComponentEntity(
            comboId: 'combo-2',
            extraId: 'extra-3',
            quantity: 1,
            extraPrice: 60.0,
            extraCostPrice: null, // Cost price not tracked
          ),
        ],
      );

      expect(combo.imageUrl, isNull);
      expect(combo.separateItemsTotal, equals(60.0));
      expect(combo.savings, equals(10.0));
      expect(combo.estimatedCostTotal, equals(0.0));
      expect(combo.profitMargin, isNull);
      expect(combo.profitMarginPercent, isNull);
    });
  });

  group('Canteen Combo Serialization', () {
    test('parses CanteenComboModel with nested items from JSON', () {
      final json = {
        'id': 'combo-3',
        'lounge_id': 'lounge-1',
        'name_ar': 'كومبو تجريبي',
        'name_en': 'Test Combo',
        'price': 100.0,
        'days_of_week': [0, 1, 2, 3, 4, 5, 6],
        'is_active': true,
        'canteen_combo_items': [
          {
            'combo_id': 'combo-3',
            'extra_id': 'extra-1',
            'quantity': 2,
            'extras': {
              'id': 'extra-1',
              'name_ar': 'كولا',
              'price': 30.0,
              'cost_price': 18.0,
            },
          },
        ],
      };

      final model = CanteenComboModel.fromJson(json);

      expect(model.id, equals('combo-3'));
      expect(model.nameAr, equals('كومبو تجريبي'));
      expect(model.price, equals(100.0));
      expect(model.items.length, equals(1));
      expect(model.items.first.extraNameAr, equals('كولا'));
      expect(model.items.first.extraPrice, equals(30.0));
      expect(model.items.first.extraCostPrice, equals(18.0));
    });
  });

  group('Upsell Rule & Conversion Analytics', () {
    test('parses UpsellRuleModel with extra suggestion and discount', () {
      final json = {
        'id': 'rule-1',
        'lounge_id': 'lounge-1',
        'trigger_type': 'session_minutes_elapsed',
        'trigger_params': {'minutes': 45},
        'suggest_extra_id': 'extra-1',
        'discount_percent': 15.0,
        'max_impressions_per_booking': 2,
        'priority': 150,
        'is_active': true,
        'extras': {'id': 'extra-1', 'name_ar': 'شاي مثلج', 'price': 35.0},
      };

      final model = UpsellRuleModel.fromJson(json);

      expect(model.id, equals('rule-1'));
      expect(model.triggerType, equals('session_minutes_elapsed'));
      expect(model.triggerParams['minutes'], equals(45));
      expect(model.discountPercent, equals(15.0));
      expect(model.suggestedNameAr, equals('شاي مثلج'));
      expect(model.isCombo, isFalse);
    });

    test('parses UpsellConversionModel correctly', () {
      final json = {
        'lounge_id': 'lounge-1',
        'rule_id': 'rule-1',
        'trigger_type': 'session_minutes_elapsed',
        'impressions': 100,
        'conversions': 32,
        'conversion_rate_percent': 32.0,
        'revenue_generated': 1120.0,
      };

      final model = UpsellConversionModel.fromJson(json);

      expect(model.impressions, equals(100));
      expect(model.conversions, equals(32));
      expect(model.conversionRatePercent, equals(32.0));
      expect(model.revenueGenerated, equals(1120.0));
    });

    test('parses LowStockAlertModel correctly', () {
      final json = {
        'lounge_id': 'lounge-1',
        'extra_id': 'extra-5',
        'name_ar': 'ريد بول',
        'category': 'drinks',
        'stock_quantity': 2,
        'min_stock_threshold': 5,
      };

      final model = LowStockAlertModel.fromJson(json);

      expect(model.extraId, equals('extra-5'));
      expect(model.nameAr, equals('ريد بول'));
      expect(model.stockQuantity, equals(2));
      expect(model.minStockThreshold, equals(5));
    });
  });

  group('CanteenItemExtractor & Stock Alerts', () {
    test('catalogue price changes cannot overwrite the purchased offer price', () {
      final items = CanteenItemExtractor.extract({
        'items': [
          {
            'extra_id': 'drink',
            'quantity': 2,
            'unit_price': 36.0,
            'total_price': 72.0,
            'extras': {'name': 'Drink', 'price': 50.0},
          },
        ],
      });
      expect(items.single['price'], 36.0);
      expect(items.single['unit_price'], 36.0);
      expect(items.single['total_price'], 72.0);
    });

    test('extracts combo parent, combo components, and low stock flag', () {
      final rawData = {
        'canteen_order_items': [
          {
            'combo_id': 'combo-1',
            'line_kind': 'combo_parent',
            'item_name': 'وجبة كومبو',
            'quantity': 1,
            'unit_price': 80.0,
          },
          {
            'combo_id': 'combo-1',
            'combo_line_id': 'combo-1',
            'line_kind': 'combo_component',
            'item_name': 'عصير',
            'quantity': 2,
            'unit_price': 0.0,
            'track_stock': true,
            'stock_quantity': 1,
            'min_stock_alert': 5,
          },
          {
            'extra_id': 'extra-9',
            'line_kind': 'item',
            'item_name': 'مياه معدنية',
            'quantity': 1,
            'unit_price': 10.0,
            'track_stock': true,
            'stock_quantity': 15,
            'min_stock_alert': 5,
          },
        ],
      };

      final items = CanteenItemExtractor.extract(rawData);

      expect(items.length, equals(3));

      // Combo parent
      expect(items[0]['line_kind'], equals('combo_parent'));
      expect(items[0]['combo_id'], equals('combo-1'));

      // Combo component with low stock
      expect(items[1]['line_kind'], equals('combo_component'));
      expect(items[1]['is_low_stock'], isTrue);

      // Standard item with ample stock
      expect(items[2]['line_kind'], equals('item'));
      expect(items[2]['is_low_stock'], isFalse);
    });
  });
}
