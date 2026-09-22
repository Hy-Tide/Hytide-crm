// lib/core/widgets/quotation_status_badge.dart
import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../utils/app_extensions.dart';
import 'status_badge.dart';

class QuotationStatusBadge extends StatelessWidget {
  final QuotationStatus status;
  final bool showDot;

  const QuotationStatusBadge({
    super.key,
    required this.status,
    this.showDot = false,
  });

  @override
  Widget build(BuildContext context) {
    return StatusBadge(
      label: status.displayName,
      color: status.color,
      backgroundColor: status.backgroundColor,
      showDot: showDot,
    );
  }
}
