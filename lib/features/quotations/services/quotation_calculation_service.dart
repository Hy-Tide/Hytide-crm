// lib/features/quotations/services/quotation_calculation_service.dart
import 'dart:math';
import '../../../core/constants/app_constants.dart';
import '../models/quotation_item_model.dart';

class QuotationTotalsResult {
  final double subtotal;
  final double discountAmount;
  final double taxableAmount;
  final double taxAmount;
  final double shippingAmount;
  final double otherCharges;
  final double grandTotal;

  const QuotationTotalsResult({
    required this.subtotal,
    required this.discountAmount,
    required this.taxableAmount,
    required this.taxAmount,
    required this.shippingAmount,
    required this.otherCharges,
    required this.grandTotal,
  });
}

class QuotationCalculationService {
  const QuotationCalculationService();

  /// Round value to 2 decimal places using decimal-safe rounding
  static double roundTo2(double val) {
    return (val * 100).round() / 100.0;
  }

  /// Recalculates all fields of a single QuotationItemModel
  QuotationItemModel calculateLineItem({
    required QuotationItemModel item,
    double? quantity,
    double? unitPrice,
    DiscountType? discountType,
    double? discountValue,
    double? taxPercentage,
  }) {
    final qty = max(0.0, quantity ?? item.quantity);
    final price = max(0.0, unitPrice ?? item.unitPrice);
    final dType = discountType ?? item.discountType;
    final dVal = max(0.0, discountValue ?? item.discountValue);
    final taxPct = max(0.0, min(100.0, taxPercentage ?? item.taxPercentage));

    final baseAmount = roundTo2(qty * price);

    double discountAmt = 0.0;
    if (dType == DiscountType.percentage) {
      final cappedPct = min(100.0, dVal);
      discountAmt = roundTo2(baseAmount * (cappedPct / 100.0));
    } else {
      discountAmt = roundTo2(min(dVal, baseAmount));
    }

    final taxable = max(0.0, roundTo2(baseAmount - discountAmt));
    final taxAmt = roundTo2(taxable * (taxPct / 100.0));
    final total = roundTo2(taxable + taxAmt);

    return item.copyWith(
      quantity: qty,
      unitPrice: price,
      discountType: dType,
      discountValue: dVal,
      discountAmount: discountAmt,
      taxPercentage: taxPct,
      taxAmount: taxAmt,
      lineSubtotal: baseAmount,
      lineTotal: total,
    );
  }

  /// Computes overall Quotation Totals from line items and quotation-level modifiers
  QuotationTotalsResult calculateQuotationTotals({
    required List<QuotationItemModel> items,
    DiscountType discountType = DiscountType.percentage,
    double discountValue = 0.0,
    TaxType taxType = TaxType.gst,
    double quotationTaxPercentage = 0.0,
    double shippingAmount = 0.0,
    double otherCharges = 0.0,
  }) {
    double itemsSubtotal = 0.0;
    double itemsTax = 0.0;

    for (final item in items) {
      itemsSubtotal += item.lineSubtotal;
      itemsTax += item.taxAmount;
    }
    itemsSubtotal = roundTo2(itemsSubtotal);
    itemsTax = roundTo2(itemsTax);

    // Quotation-level discount
    double overallDiscount = 0.0;
    final dVal = max(0.0, discountValue);
    if (discountType == DiscountType.percentage) {
      final cappedPct = min(100.0, dVal);
      overallDiscount = roundTo2(itemsSubtotal * (cappedPct / 100.0));
    } else {
      overallDiscount = roundTo2(min(dVal, itemsSubtotal));
    }

    final taxableAmount = max(0.0, roundTo2(itemsSubtotal - overallDiscount));

    // If quotation-level tax is explicitly specified and items don't have individual taxes
    double totalTax = itemsTax;
    if (itemsTax == 0.0 && quotationTaxPercentage > 0.0 && taxType != TaxType.none) {
      final cappedTaxPct = min(100.0, quotationTaxPercentage);
      totalTax = roundTo2(taxableAmount * (cappedTaxPct / 100.0));
    }

    final shipping = max(0.0, roundTo2(shippingAmount));
    final other = max(0.0, roundTo2(otherCharges));

    final grandTotal = roundTo2(taxableAmount + totalTax + shipping + other);

    return QuotationTotalsResult(
      subtotal: itemsSubtotal,
      discountAmount: overallDiscount,
      taxableAmount: taxableAmount,
      taxAmount: totalTax,
      shippingAmount: shipping,
      otherCharges: other,
      grandTotal: grandTotal,
    );
  }
}
