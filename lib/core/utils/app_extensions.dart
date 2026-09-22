// lib/core/utils/app_extensions.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/app_constants.dart';
import '../theme/app_colors.dart';

extension DateTimeExtensions on DateTime {
  String get formatted => DateFormat('dd MMM yyyy').format(this);
  String get formattedWithTime => DateFormat('dd MMM yyyy, hh:mm a').format(this);
  String get formattedDate => DateFormat('MMM dd, yyyy').format(this);
  String get shortDate => DateFormat('dd/MM/yy').format(this);
  String get timeOnly => DateFormat('hh:mm a').format(this);
  String get monthYear => DateFormat('MMM yyyy').format(this);

  bool get isToday {
    final now = DateTime.now();
    return day == now.day && month == now.month && year == now.year;
  }

  bool get isTomorrow {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return day == tomorrow.day && month == tomorrow.month && year == tomorrow.year;
  }

  bool get isPast => isBefore(DateTime.now());
  bool get isOverdue => isPast && !isToday;
}

extension StringExtensions on String {
  String get capitalize {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  String get titleCase {
    return split(' ').map((word) => word.capitalize).join(' ');
  }

  bool get isValidEmail {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(this);
  }

  bool get isValidPhone {
    return RegExp(r'^\+?[\d\s\-\(\)]{7,15}$').hasMatch(this);
  }

  bool get isValidUrl {
    return Uri.tryParse(this)?.hasAbsolutePath ?? false;
  }

  String get initials {
    final words = trim().split(' ');
    if (words.isEmpty) return '';
    if (words.length == 1) return words[0][0].toUpperCase();
    return '${words[0][0]}${words[words.length - 1][0]}'.toUpperCase();
  }
}

extension NumberExtensions on double {
  String get formatted {
    if (this >= 10000000) {
      return '₹${(this / 10000000).toStringAsFixed(2)}Cr';
    } else if (this >= 100000) {
      return '₹${(this / 100000).toStringAsFixed(2)}L';
    } else if (this >= 1000) {
      return '₹${(this / 1000).toStringAsFixed(1)}K';
    }
    return '₹${toStringAsFixed(0)}';
  }

  String get currency => NumberFormat.currency(
        locale: 'en_IN',
        symbol: '₹',
        decimalDigits: 2,
      ).format(this);
}

extension IntExtensions on int {
  String get fileSizeFormatted {
    if (this < 1024) return '$this B';
    if (this < 1024 * 1024) return '${(this / 1024).toStringAsFixed(1)} KB';
    if (this < 1024 * 1024 * 1024) {
      return '${(this / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(this / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}

extension LeadStatusExtensions on LeadStatus {
  Color get color {
    switch (this) {
      case LeadStatus.newLead:
        return AppColors.statusNew;
      case LeadStatus.contacted:
        return AppColors.statusContacted;
      case LeadStatus.interested:
        return AppColors.info;
      case LeadStatus.notInterested:
        return AppColors.textMuted;
      case LeadStatus.noResponse:
        return AppColors.warning;
      case LeadStatus.followUp:
        return AppColors.statusFollowUp;
      case LeadStatus.demoScheduled:
        return AppColors.statusMeeting;
      case LeadStatus.proposalSent:
        return AppColors.statusProposal;
      case LeadStatus.negotiation:
        return AppColors.statusNegotiation;
      case LeadStatus.won:
        return AppColors.statusWon;
      case LeadStatus.lost:
        return AppColors.statusLost;
    }
  }

  Color get backgroundColor {
    switch (this) {
      case LeadStatus.newLead:
        return AppColors.statusNewBg;
      case LeadStatus.contacted:
        return AppColors.statusContactedBg;
      case LeadStatus.interested:
        return AppColors.infoContainer;
      case LeadStatus.notInterested:
        return AppColors.surfaceVariant;
      case LeadStatus.noResponse:
        return AppColors.warningContainer;
      case LeadStatus.followUp:
        return AppColors.statusFollowUpBg;
      case LeadStatus.demoScheduled:
        return AppColors.statusMeetingBg;
      case LeadStatus.proposalSent:
        return AppColors.statusProposalBg;
      case LeadStatus.negotiation:
        return AppColors.statusNegotiationBg;
      case LeadStatus.won:
        return AppColors.statusWonBg;
      case LeadStatus.lost:
        return AppColors.statusLostBg;
    }
  }

  IconData get icon {
    switch (this) {
      case LeadStatus.newLead:
        return Icons.fiber_new_rounded;
      case LeadStatus.contacted:
        return Icons.phone_rounded;
      case LeadStatus.interested:
        return Icons.thumb_up_alt_rounded;
      case LeadStatus.notInterested:
        return Icons.thumb_down_alt_rounded;
      case LeadStatus.noResponse:
        return Icons.person_off_rounded;
      case LeadStatus.followUp:
        return Icons.schedule_rounded;
      case LeadStatus.demoScheduled:
        return Icons.calendar_today_rounded;
      case LeadStatus.proposalSent:
        return Icons.description_rounded;
      case LeadStatus.negotiation:
        return Icons.handshake_rounded;
      case LeadStatus.won:
        return Icons.check_circle_rounded;
      case LeadStatus.lost:
        return Icons.cancel_rounded;
    }
  }
}

extension LeadPriorityExtensions on LeadPriority {
  Color get color {
    switch (this) {
      case LeadPriority.low:
        return AppColors.priorityLow;
      case LeadPriority.medium:
        return AppColors.priorityMedium;
      case LeadPriority.high:
        return AppColors.priorityHigh;
      case LeadPriority.urgent:
        return AppColors.priorityUrgent;
    }
  }

  Color get backgroundColor {
    switch (this) {
      case LeadPriority.low:
        return AppColors.priorityLowBg;
      case LeadPriority.medium:
        return AppColors.priorityMediumBg;
      case LeadPriority.high:
        return AppColors.priorityHighBg;
      case LeadPriority.urgent:
        return AppColors.priorityUrgentBg;
    }
  }

  IconData get icon {
    switch (this) {
      case LeadPriority.low:
        return Icons.arrow_downward_rounded;
      case LeadPriority.medium:
        return Icons.remove_rounded;
      case LeadPriority.high:
        return Icons.arrow_upward_rounded;
      case LeadPriority.urgent:
        return Icons.priority_high_rounded;
    }
  }
}

extension QuotationStatusExtensions on QuotationStatus {
  Color get color {
    switch (this) {
      case QuotationStatus.draft:
        return AppColors.onSurfaceVariant;
      case QuotationStatus.sent:
        return AppColors.info;
      case QuotationStatus.viewed:
        return AppColors.secondary;
      case QuotationStatus.accepted:
        return AppColors.success;
      case QuotationStatus.rejected:
        return AppColors.error;
      case QuotationStatus.expired:
        return AppColors.warning;
      case QuotationStatus.cancelled:
        return AppColors.error;
      case QuotationStatus.converted:
        return AppColors.primary;
    }
  }

  Color get backgroundColor {
    switch (this) {
      case QuotationStatus.draft:
        return AppColors.surfaceVariant;
      case QuotationStatus.sent:
        return AppColors.infoContainer;
      case QuotationStatus.viewed:
        return AppColors.secondaryContainer;
      case QuotationStatus.accepted:
        return AppColors.successContainer;
      case QuotationStatus.rejected:
        return AppColors.errorContainer;
      case QuotationStatus.expired:
        return AppColors.warningContainer;
      case QuotationStatus.cancelled:
        return AppColors.errorContainer;
      case QuotationStatus.converted:
        return AppColors.primaryContainer;
    }
  }

  IconData get icon {
    switch (this) {
      case QuotationStatus.draft:
        return Icons.edit_note_rounded;
      case QuotationStatus.sent:
        return Icons.send_rounded;
      case QuotationStatus.viewed:
        return Icons.visibility_outlined;
      case QuotationStatus.accepted:
        return Icons.check_circle_outline_rounded;
      case QuotationStatus.rejected:
        return Icons.highlight_off_rounded;
      case QuotationStatus.expired:
        return Icons.timer_off_outlined;
      case QuotationStatus.cancelled:
        return Icons.cancel_outlined;
      case QuotationStatus.converted:
        return Icons.rocket_launch_outlined;
    }
  }
}

extension FollowUpStatusExtensions on FollowUpStatus {
  Color get color {
    switch (this) {
      case FollowUpStatus.pending:
        return AppColors.warning;
      case FollowUpStatus.completed:
        return AppColors.success;
      case FollowUpStatus.cancelled:
        return AppColors.error;
      case FollowUpStatus.missed:
        return AppColors.error;
      case FollowUpStatus.rescheduled:
        return AppColors.info;
    }
  }

  Color get backgroundColor {
    switch (this) {
      case FollowUpStatus.pending:
        return AppColors.warningContainer;
      case FollowUpStatus.completed:
        return AppColors.successContainer;
      case FollowUpStatus.cancelled:
        return AppColors.errorContainer;
      case FollowUpStatus.missed:
        return AppColors.errorContainer;
      case FollowUpStatus.rescheduled:
        return AppColors.infoContainer;
    }
  }
}

extension ClientStatusExtensions on ClientStatus {
  Color get color {
    switch (this) {
      case ClientStatus.active:
        return AppColors.success;
      case ClientStatus.inactive:
        return AppColors.onSurfaceVariant;
      case ClientStatus.onHold:
        return AppColors.warning;
      case ClientStatus.completed:
        return AppColors.info;
      case ClientStatus.archived:
        return AppColors.error;
    }
  }

  Color get backgroundColor {
    switch (this) {
      case ClientStatus.active:
        return AppColors.successContainer;
      case ClientStatus.inactive:
        return AppColors.surfaceVariant;
      case ClientStatus.onHold:
        return AppColors.warningContainer;
      case ClientStatus.completed:
        return AppColors.infoContainer;
      case ClientStatus.archived:
        return AppColors.errorContainer;
    }
  }
}

extension ClientPriorityExtensions on ClientPriority {
  Color get color {
    switch (this) {
      case ClientPriority.urgent:
        return AppColors.error;
      case ClientPriority.high:
        return AppColors.warning;
      case ClientPriority.medium:
        return AppColors.secondary;
      case ClientPriority.low:
        return AppColors.onSurfaceVariant;
    }
  }

  Color get backgroundColor {
    switch (this) {
      case ClientPriority.urgent:
        return AppColors.errorContainer;
      case ClientPriority.high:
        return AppColors.warningContainer;
      case ClientPriority.medium:
        return AppColors.secondaryContainer;
      case ClientPriority.low:
        return AppColors.surfaceVariant;
    }
  }
}

extension ClientTypeExtensions on ClientType {
  IconData get icon {
    switch (this) {
      case ClientType.corporate:
        return Icons.business_rounded;
      case ClientType.individual:
        return Icons.person_outline_rounded;
      case ClientType.partner:
        return Icons.handshake_outlined;
      case ClientType.repeatClient:
        return Icons.replay_rounded;
      case ClientType.newClient:
        return Icons.fiber_new_rounded;
      case ClientType.existingClient:
        return Icons.check_circle_outline_rounded;
      case ClientType.other:
        return Icons.category_outlined;
    }
  }
}

extension ProjectStatusExtensions on ProjectStatus {
  Color get color {
    switch (this) {
      case ProjectStatus.planning:
        return AppColors.secondary;
      case ProjectStatus.active:
        return AppColors.primary;
      case ProjectStatus.onHold:
        return AppColors.warning;
      case ProjectStatus.completed:
        return AppColors.success;
      case ProjectStatus.cancelled:
        return AppColors.error;
      case ProjectStatus.archived:
        return AppColors.textMuted;
    }
  }

  Color get backgroundColor {
    switch (this) {
      case ProjectStatus.planning:
        return AppColors.secondaryContainer;
      case ProjectStatus.active:
        return AppColors.primaryContainer;
      case ProjectStatus.onHold:
        return AppColors.warningContainer;
      case ProjectStatus.completed:
        return AppColors.successContainer;
      case ProjectStatus.cancelled:
        return AppColors.errorContainer;
      case ProjectStatus.archived:
        return AppColors.surfaceBorder;
    }
  }

  IconData get icon {
    switch (this) {
      case ProjectStatus.planning:
        return Icons.edit_calendar_rounded;
      case ProjectStatus.active:
        return Icons.play_circle_outline_rounded;
      case ProjectStatus.onHold:
        return Icons.pause_circle_outline_rounded;
      case ProjectStatus.completed:
        return Icons.check_circle_outline_rounded;
      case ProjectStatus.cancelled:
        return Icons.cancel_outlined;
      case ProjectStatus.archived:
        return Icons.archive_outlined;
    }
  }
}

extension ProjectTypeExtensions on ProjectType {
  IconData get icon {
    switch (this) {
      case ProjectType.website:
        return Icons.language_rounded;
      case ProjectType.mobileApp:
        return Icons.smartphone_rounded;
      case ProjectType.webApplication:
        return Icons.web_rounded;
      case ProjectType.uiUxDesign:
        return Icons.palette_outlined;
      case ProjectType.ecommerce:
        return Icons.shopping_cart_outlined;
      case ProjectType.apiBackend:
        return Icons.dns_rounded;
      case ProjectType.adminPanel:
        return Icons.dashboard_outlined;
      case ProjectType.maintenance:
        return Icons.build_outlined;
      case ProjectType.consulting:
        return Icons.lightbulb_outline_rounded;
      case ProjectType.other:
        return Icons.folder_outlined;
    }
  }
}

extension ProjectPriorityExtensions on ProjectPriority {
  Color get color {
    switch (this) {
      case ProjectPriority.urgent:
        return AppColors.error;
      case ProjectPriority.high:
        return AppColors.warning;
      case ProjectPriority.medium:
        return AppColors.secondary;
      case ProjectPriority.low:
        return AppColors.onSurfaceVariant;
    }
  }

  Color get backgroundColor {
    switch (this) {
      case ProjectPriority.urgent:
        return AppColors.errorContainer;
      case ProjectPriority.high:
        return AppColors.warningContainer;
      case ProjectPriority.medium:
        return AppColors.secondaryContainer;
      case ProjectPriority.low:
        return AppColors.surfaceVariant;
    }
  }

  Color get containerColor => backgroundColor;

  IconData get icon {
    switch (this) {
      case ProjectPriority.urgent:
        return Icons.error_rounded;
      case ProjectPriority.high:
        return Icons.arrow_upward_rounded;
      case ProjectPriority.medium:
        return Icons.remove_rounded;
      case ProjectPriority.low:
        return Icons.arrow_downward_rounded;
    }
  }
}

