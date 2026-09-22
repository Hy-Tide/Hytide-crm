// lib/features/quotations/models/quotation_item_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import '../../../core/constants/app_constants.dart';

class QuotationItemModel extends Equatable {
  final String id;
  final String name;
  final String description;
  final QuotationItemType itemType;
  final double quantity;
  final String unit;
  final double unitPrice;
  final DiscountType discountType;
  final double discountValue;
  final double discountAmount;
  final double taxPercentage;
  final double taxAmount;
  final double lineSubtotal;
  final double lineTotal;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  const QuotationItemModel({
    required this.id,
    required this.name,
    this.description = '',
    this.itemType = QuotationItemType.service,
    required this.quantity,
    this.unit = 'Units',
    required this.unitPrice,
    this.discountType = DiscountType.percentage,
    this.discountValue = 0.0,
    this.discountAmount = 0.0,
    this.taxPercentage = 18.0,
    this.taxAmount = 0.0,
    this.lineSubtotal = 0.0,
    required this.lineTotal,
    this.sortOrder = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Calculate base before discount
  double get baseAmount => (quantity * unitPrice * 100).round() / 100.0;

  factory QuotationItemModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return QuotationItemModel.fromMap(doc.data()!, id: doc.id);
  }

  factory QuotationItemModel.fromMap(
    Map<String, dynamic> data, {
    String? id,
  }) {
    return QuotationItemModel(
      id: id ?? data['id'] as String? ?? '',
      name: data['name'] as String? ?? '',
      description: data['description'] as String? ?? '',
      itemType: QuotationItemType.fromString(data['itemType'] as String? ?? 'service'),
      quantity: (data['quantity'] as num?)?.toDouble() ?? 1.0,
      unit: data['unit'] as String? ?? 'Units',
      unitPrice: (data['unitPrice'] as num?)?.toDouble() ?? 0.0,
      discountType: DiscountType.fromString(data['discountType'] as String? ?? 'percentage'),
      discountValue: (data['discountValue'] as num?)?.toDouble() ?? 0.0,
      discountAmount: (data['discountAmount'] as num?)?.toDouble() ?? 0.0,
      taxPercentage: (data['taxPercentage'] as num?)?.toDouble() ?? 18.0,
      taxAmount: (data['taxAmount'] as num?)?.toDouble() ?? 0.0,
      lineSubtotal: (data['lineSubtotal'] as num?)?.toDouble() ?? 0.0,
      lineTotal: (data['lineTotal'] as num?)?.toDouble() ?? 0.0,
      sortOrder: (data['sortOrder'] as num?)?.toInt() ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'itemType': itemType.name,
      'quantity': quantity,
      'unit': unit,
      'unitPrice': unitPrice,
      'discountType': discountType.name,
      'discountValue': discountValue,
      'discountAmount': discountAmount,
      'taxPercentage': taxPercentage,
      'taxAmount': taxAmount,
      'lineSubtotal': lineSubtotal,
      'lineTotal': lineTotal,
      'sortOrder': sortOrder,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  QuotationItemModel copyWith({
    String? id,
    String? name,
    String? description,
    QuotationItemType? itemType,
    double? quantity,
    String? unit,
    double? unitPrice,
    DiscountType? discountType,
    double? discountValue,
    double? discountAmount,
    double? taxPercentage,
    double? taxAmount,
    double? lineSubtotal,
    double? lineTotal,
    int? sortOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return QuotationItemModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      itemType: itemType ?? this.itemType,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      unitPrice: unitPrice ?? this.unitPrice,
      discountType: discountType ?? this.discountType,
      discountValue: discountValue ?? this.discountValue,
      discountAmount: discountAmount ?? this.discountAmount,
      taxPercentage: taxPercentage ?? this.taxPercentage,
      taxAmount: taxAmount ?? this.taxAmount,
      lineSubtotal: lineSubtotal ?? this.lineSubtotal,
      lineTotal: lineTotal ?? this.lineTotal,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        itemType,
        quantity,
        unit,
        unitPrice,
        discountType,
        discountValue,
        discountAmount,
        taxPercentage,
        taxAmount,
        lineSubtotal,
        lineTotal,
        sortOrder,
        createdAt,
        updatedAt,
      ];
}
