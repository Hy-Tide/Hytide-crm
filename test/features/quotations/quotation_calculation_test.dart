// test/features/quotations/quotation_calculation_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:hytide/core/constants/app_constants.dart';
import 'package:hytide/features/quotations/models/quotation_item_model.dart';
import 'package:hytide/features/quotations/services/quotation_calculation_service.dart';

void main() {
  group('QuotationCalculationService Unit Tests', () {
    const calcService = QuotationCalculationService();
    final now = DateTime(2026, 9, 4, 10, 0);

    test('calculates line item without discount and tax', () {
      final item = QuotationItemModel(
        id: 'item-1',
        name: 'CRM Setup Service',
        quantity: 3,
        unitPrice: 10000.0,
        discountType: DiscountType.percentage,
        discountValue: 0.0,
        taxPercentage: 0.0,
        lineTotal: 0.0,
        sortOrder: 0,
        createdAt: now,
        updatedAt: now,
      );

      final calculated = calcService.calculateLineItem(item: item);
      expect(calculated.lineSubtotal, equals(30000.0));
      expect(calculated.discountAmount, equals(0.0));
      expect(calculated.taxAmount, equals(0.0));
      expect(calculated.lineTotal, equals(30000.0));
    });

    test('calculates line item with percentage discount and GST tax', () {
      // 2 units @ ₹5,000 = ₹10,000
      // 10% discount = ₹1,000 -> After discount = ₹9,000
      // 18% GST on ₹9,000 = ₹1,620 -> Total = ₹10,620
      final item = QuotationItemModel(
        id: 'item-2',
        name: 'Hardware Sensor Unit',
        quantity: 2,
        unitPrice: 5000.0,
        discountType: DiscountType.percentage,
        discountValue: 10.0,
        taxPercentage: 18.0,
        lineTotal: 0.0,
        sortOrder: 1,
        createdAt: now,
        updatedAt: now,
      );

      final calculated = calcService.calculateLineItem(item: item);
      expect(calculated.lineSubtotal, equals(10000.0));
      expect(calculated.discountAmount, equals(1000.0));
      expect(calculated.taxAmount, equals(1620.0));
      expect(calculated.lineTotal, equals(10620.0));
    });

    test('calculates line item with fixed discount', () {
      // 1 unit @ ₹15,000 = ₹15,000
      // ₹2,500 fixed discount -> After discount = ₹12,500
      // 12% GST on ₹12,500 = ₹1,500 -> Total = ₹14,000
      final item = QuotationItemModel(
        id: 'item-3',
        name: 'Custom Integration',
        quantity: 1,
        unitPrice: 15000.0,
        discountType: DiscountType.fixedAmount,
        discountValue: 2500.0,
        taxPercentage: 12.0,
        lineTotal: 0.0,
        sortOrder: 2,
        createdAt: now,
        updatedAt: now,
      );

      final calculated = calcService.calculateLineItem(item: item);
      expect(calculated.lineSubtotal, equals(15000.0));
      expect(calculated.discountAmount, equals(2500.0));
      expect(calculated.taxAmount, equals(1500.0));
      expect(calculated.lineTotal, equals(14000.0));
    });

    test('calculates full quotation totals with shipping and other charges', () {
      final item1 = QuotationItemModel(
        id: 'item-1',
        name: 'Cloud Server',
        quantity: 2,
        unitPrice: 10000.0, // 20000
        lineSubtotal: 20000.0,
        discountType: DiscountType.percentage,
        discountValue: 0.0,
        discountAmount: 0.0,
        taxPercentage: 0.0,
        taxAmount: 0.0,
        lineTotal: 20000.0,
        sortOrder: 0,
        createdAt: now,
        updatedAt: now,
      );

      final item2 = QuotationItemModel(
        id: 'item-2',
        name: 'Support Package',
        quantity: 1,
        unitPrice: 10000.0, // 10000
        lineSubtotal: 10000.0,
        discountType: DiscountType.percentage,
        discountValue: 0.0,
        discountAmount: 0.0,
        taxPercentage: 0.0,
        taxAmount: 0.0,
        lineTotal: 10000.0,
        sortOrder: 1,
        createdAt: now,
        updatedAt: now,
      );

      // Subtotal = 30,000
      // 10% quotation discount = 3,000 -> After discount = 27,000
      // 18% quotation tax on 27,000 = 4,860
      // Shipping = 500, Other = 250
      // Grand Total = 27,000 + 4,860 + 500 + 250 = 32,610
      final result = calcService.calculateQuotationTotals(
        items: [item1, item2],
        discountType: DiscountType.percentage,
        discountValue: 10.0,
        taxType: TaxType.gst,
        quotationTaxPercentage: 18.0,
        shippingAmount: 500.0,
        otherCharges: 250.0,
      );

      expect(result.subtotal, equals(30000.0));
      expect(result.discountAmount, equals(3000.0));
      expect(result.taxableAmount, equals(27000.0));
      expect(result.taxAmount, equals(4860.0));
      expect(result.shippingAmount, equals(500.0));
      expect(result.otherCharges, equals(250.0));
      expect(result.grandTotal, equals(32610.0));
    });

    test('handles empty item list gracefully with 0 totals', () {
      final result = calcService.calculateQuotationTotals(
        items: [],
        discountType: DiscountType.percentage,
        discountValue: 5.0,
        taxType: TaxType.gst,
        quotationTaxPercentage: 18.0,
        shippingAmount: 100.0,
      );

      expect(result.subtotal, equals(0.0));
      expect(result.discountAmount, equals(0.0));
      expect(result.taxAmount, equals(0.0));
      expect(result.grandTotal, equals(100.0));
    });

    test('fixed discount capped at subtotal', () {
      final item = QuotationItemModel(
        id: 'item-1',
        name: 'Micro Service',
        quantity: 1,
        unitPrice: 500.0,
        lineSubtotal: 500.0,
        lineTotal: 500.0,
        sortOrder: 0,
        createdAt: now,
        updatedAt: now,
      );

      // Attempt ₹1,000 discount on ₹500 subtotal
      final result = calcService.calculateQuotationTotals(
        items: [item],
        discountType: DiscountType.fixedAmount,
        discountValue: 1000.0,
      );

      expect(result.subtotal, equals(500.0));
      expect(result.discountAmount, equals(500.0));
      expect(result.taxableAmount, equals(0.0));
      expect(result.grandTotal, equals(0.0));
    });
  });
}
