// lib/core/widgets/lead_status_badge.dart
import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../utils/app_extensions.dart';
import 'status_badge.dart';

class LeadStatusBadge extends StatelessWidget {
  final LeadStatus status;
  final bool showDot;
  final bool compact;

  const LeadStatusBadge({
    super.key,
    required this.status,
    this.showDot = false,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return StatusBadge(
      label: status.displayName,
      color: status.color,
      backgroundColor: status.backgroundColor,
      showDot: showDot,
      compact: compact,
    );
  }
}
