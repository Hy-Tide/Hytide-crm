// lib/core/constants/app_constants.dart

enum UserRole {
  admin,
  manager,
  salesStaff;

  String get displayName {
    switch (this) {
      case UserRole.admin:
        return 'Admin';
      case UserRole.manager:
        return 'Manager';
      case UserRole.salesStaff:
        return 'Sales Staff';
    }
  }

  static UserRole fromString(String value) {
    switch (value) {
      case 'admin':
        return UserRole.admin;
      case 'manager':
        return UserRole.manager;
      default:
        return UserRole.salesStaff;
    }
  }
}

class AppAuthConstants {
  static const String superAdminEmail = 'adminsupport.hytide@gmail.com';
}

enum LeadStatus {
  newLead,
  contacted,
  interested,
  notInterested,
  noResponse,
  followUp,
  demoScheduled,
  proposalSent,
  negotiation,
  won,
  lost;

  String get displayName {
    switch (this) {
      case LeadStatus.newLead:
        return 'New';
      case LeadStatus.contacted:
        return 'Contacted';
      case LeadStatus.interested:
        return 'Interested';
      case LeadStatus.notInterested:
        return 'Not Interested';
      case LeadStatus.noResponse:
        return 'Haven\'t Responded';
      case LeadStatus.followUp:
        return 'Follow-up';
      case LeadStatus.demoScheduled:
        return 'Demo Scheduled';
      case LeadStatus.proposalSent:
        return 'Proposal Sent';
      case LeadStatus.negotiation:
        return 'Negotiation';
      case LeadStatus.won:
        return 'Won';
      case LeadStatus.lost:
        return 'Lost';
    }
  }

  String get label => displayName;

  static LeadStatus fromString(String value) {
    switch (value) {
      case 'contacted':
        return LeadStatus.contacted;
      case 'interested':
        return LeadStatus.interested;
      case 'notInterested':
        return LeadStatus.notInterested;
      case 'noResponse':
        return LeadStatus.noResponse;
      case 'followUp':
        return LeadStatus.followUp;
      case 'meetingScheduled': // backward compatibility
      case 'demoScheduled':
        return LeadStatus.demoScheduled;
      case 'proposalSent':
        return LeadStatus.proposalSent;
      case 'negotiation':
        return LeadStatus.negotiation;
      case 'won':
        return LeadStatus.won;
      case 'lost':
        return LeadStatus.lost;
      default:
        return LeadStatus.newLead;
    }
  }
}

enum LeadPriority {
  low,
  medium,
  high,
  urgent;

  String get displayName {
    switch (this) {
      case LeadPriority.low:
        return 'Low';
      case LeadPriority.medium:
        return 'Medium';
      case LeadPriority.high:
        return 'High';
      case LeadPriority.urgent:
        return 'Urgent';
    }
  }

  String get label => displayName;

  static LeadPriority fromString(String value) {
    switch (value) {
      case 'medium':
        return LeadPriority.medium;
      case 'high':
        return LeadPriority.high;
      case 'urgent':
        return LeadPriority.urgent;
      default:
        return LeadPriority.low;
    }
  }
}

enum LeadSource {
  website,
  googleMaps,
  referral,
  instagram,
  facebook,
  linkedin,
  whatsapp,
  coldCall,
  email,
  direct,
  freelancer,
  other;

  String get displayName {
    switch (this) {
      case LeadSource.website:
        return 'Website';
      case LeadSource.googleMaps:
        return 'Google Maps';
      case LeadSource.referral:
        return 'Referral';
      case LeadSource.instagram:
        return 'Instagram';
      case LeadSource.facebook:
        return 'Facebook';
      case LeadSource.linkedin:
        return 'LinkedIn';
      case LeadSource.whatsapp:
        return 'WhatsApp';
      case LeadSource.coldCall:
        return 'Cold Call';
      case LeadSource.email:
        return 'Email';
      case LeadSource.direct:
        return 'Direct Enquiry';
      case LeadSource.freelancer:
        return 'Freelancer';
      case LeadSource.other:
        return 'Other';
    }
  }

  String get label => displayName;

  static LeadSource fromString(String value) {
    switch (value) {
      case 'googleMaps':
        return LeadSource.googleMaps;
      case 'referral':
        return LeadSource.referral;
      case 'instagram':
        return LeadSource.instagram;
      case 'facebook':
        return LeadSource.facebook;
      case 'linkedin':
        return LeadSource.linkedin;
      case 'whatsapp':
        return LeadSource.whatsapp;
      case 'coldCall':
        return LeadSource.coldCall;
      case 'email':
        return LeadSource.email;
      case 'direct':
        return LeadSource.direct;
      case 'freelancer':
        return LeadSource.freelancer;
      case 'other':
        return LeadSource.other;
      default:
        return LeadSource.website;
    }
  }
}

enum FollowUpType {
  call,
  whatsapp,
  email,
  meeting,
  siteVisit,
  demo,
  quotationFollowUp,
  paymentFollowUp,
  general,
  other;

  String get displayName {
    switch (this) {
      case FollowUpType.call:
        return 'Call';
      case FollowUpType.whatsapp:
        return 'WhatsApp';
      case FollowUpType.email:
        return 'Email';
      case FollowUpType.meeting:
        return 'Meeting';
      case FollowUpType.siteVisit:
        return 'Site Visit';
      case FollowUpType.demo:
        return 'Demo';
      case FollowUpType.quotationFollowUp:
        return 'Quotation Follow-up';
      case FollowUpType.paymentFollowUp:
        return 'Payment Follow-up';
      case FollowUpType.general:
        return 'General';
      case FollowUpType.other:
        return 'Other';
    }
  }

  static FollowUpType fromString(String value) {
    switch (value) {
      case 'whatsapp':
        return FollowUpType.whatsapp;
      case 'email':
        return FollowUpType.email;
      case 'meeting':
        return FollowUpType.meeting;
      case 'siteVisit':
        return FollowUpType.siteVisit;
      case 'demo':
        return FollowUpType.demo;
      case 'quotationFollowUp':
        return FollowUpType.quotationFollowUp;
      case 'paymentFollowUp':
        return FollowUpType.paymentFollowUp;
      case 'general':
        return FollowUpType.general;
      case 'other':
        return FollowUpType.other;
      default:
        return FollowUpType.call;
    }
  }
}

enum FollowUpStatus {
  pending,
  completed,
  cancelled,
  missed,
  rescheduled;

  String get displayName {
    switch (this) {
      case FollowUpStatus.pending:
        return 'Pending';
      case FollowUpStatus.completed:
        return 'Completed';
      case FollowUpStatus.cancelled:
        return 'Cancelled';
      case FollowUpStatus.missed:
        return 'Missed';
      case FollowUpStatus.rescheduled:
        return 'Rescheduled';
    }
  }

  static FollowUpStatus fromString(String value) {
    switch (value) {
      case 'completed':
        return FollowUpStatus.completed;
      case 'cancelled':
        return FollowUpStatus.cancelled;
      case 'missed':
        return FollowUpStatus.missed;
      case 'rescheduled':
        return FollowUpStatus.rescheduled;
      default:
        return FollowUpStatus.pending;
    }
  }
}

enum FollowUpPriority {
  low,
  medium,
  high,
  urgent;

  String get displayName {
    switch (this) {
      case FollowUpPriority.low:
        return 'Low';
      case FollowUpPriority.medium:
        return 'Medium';
      case FollowUpPriority.high:
        return 'High';
      case FollowUpPriority.urgent:
        return 'Urgent';
    }
  }

  static FollowUpPriority fromString(String value) {
    switch (value) {
      case 'low':
        return FollowUpPriority.low;
      case 'high':
        return FollowUpPriority.high;
      case 'urgent':
        return FollowUpPriority.urgent;
      default:
        return FollowUpPriority.medium;
    }
  }
}

enum ClientType {
  newClient,
  existingClient,
  repeatClient,
  corporate,
  individual,
  partner,
  other;

  String get displayName {
    switch (this) {
      case ClientType.newClient:
        return 'New Client';
      case ClientType.existingClient:
        return 'Existing Client';
      case ClientType.repeatClient:
        return 'Repeat Client';
      case ClientType.corporate:
        return 'Corporate';
      case ClientType.individual:
        return 'Individual';
      case ClientType.partner:
        return 'Partner';
      case ClientType.other:
        return 'Other';
    }
  }

  static ClientType fromString(String value) {
    switch (value) {
      case 'newClient':
        return ClientType.newClient;
      case 'existingClient':
        return ClientType.existingClient;
      case 'repeatClient':
        return ClientType.repeatClient;
      case 'corporate':
        return ClientType.corporate;
      case 'individual':
        return ClientType.individual;
      case 'partner':
        return ClientType.partner;
      default:
        return ClientType.other;
    }
  }
}

enum ClientStatus {
  active,
  inactive,
  onHold,
  completed,
  archived;

  String get displayName {
    switch (this) {
      case ClientStatus.active:
        return 'Active';
      case ClientStatus.inactive:
        return 'Inactive';
      case ClientStatus.onHold:
        return 'On Hold';
      case ClientStatus.completed:
        return 'Completed';
      case ClientStatus.archived:
        return 'Archived';
    }
  }

  static ClientStatus fromString(String value) {
    switch (value) {
      case 'inactive':
        return ClientStatus.inactive;
      case 'onHold':
        return ClientStatus.onHold;
      case 'completed':
        return ClientStatus.completed;
      case 'archived':
        return ClientStatus.archived;
      default:
        return ClientStatus.active;
    }
  }
}

enum ClientPriority {
  low,
  medium,
  high,
  urgent;

  String get displayName {
    switch (this) {
      case ClientPriority.low:
        return 'Low';
      case ClientPriority.medium:
        return 'Medium';
      case ClientPriority.high:
        return 'High';
      case ClientPriority.urgent:
        return 'Urgent';
    }
  }

  static ClientPriority fromString(String value) {
    switch (value) {
      case 'low':
        return ClientPriority.low;
      case 'high':
        return ClientPriority.high;
      case 'urgent':
        return ClientPriority.urgent;
      default:
        return ClientPriority.medium;
    }
  }
}

const List<String> clientIndustries = [
  'Technology',
  'Healthcare',
  'Education',
  'Retail',
  'Manufacturing',
  'Finance',
  'Real Estate',
  'Hospitality',
  'Logistics',
  'Construction',
  'Consulting',
  'Automotive',
  'Media & Entertainment',
  'Other',
];

/// Prefilled major job titles and executive roles for CRM leads and clients
const List<String> standardJobTitles = [
  'Managing Director',
  'Chief Executive Officer (CEO)',
  'Chief Technology Officer (CTO)',
  'Chief Financial Officer (CFO)',
  'Chief Operating Officer (COO)',
  'Founder / Co-Founder',
  'President / Vice President',
  'Director',
  'General Manager',
  'Partner / Principal',
  'Head of Sales',
  'Sales Director',
  'Sales Manager',
  'Business Development Manager (BDM)',
  'Account Executive',
  'Key Account Manager',
  'Head of Procurement',
  'Procurement Director',
  'Purchasing Manager',
  'Supply Chain Manager',
  'Project Director',
  'Project Manager',
  'Operations Manager',
  'Site Engineer / Project Engineer',
  'Head of IT / IT Director',
  'Technical Lead',
  'Software Architect',
  'Marketing Director',
  'Marketing Manager',
  'Product Manager',
  'Finance Manager',
  'Commercial Manager',
  'Legal Counsel / Advisor',
  'Consultant / Strategist',
  'Other',
];

/// Prefilled major industries and verticals for CRM leads and clients
const List<String> standardIndustries = [
  'Technology & Software',
  'Civil Construction & Contracting',
  'Commercial Real Estate & Developers',
  'Architecture & Interior Design',
  'Building Materials & Hardware',
  'Industrial Manufacturing',
  'Logistics & Freight Forwarding',
  'Banking & Financial Services',
  'Healthcare & Medical Devices',
  'Retail & E-Commerce',
  'Automotive & Transportation',
  'Heavy Machinery & Engineering',
  'Hospitality, Hotels & Resorts',
  'FMCG & Consumer Goods',
  'Renewable Energy & Power',
  'Oil, Gas & Energy',
  'Higher Education & EdTech',
  'Media, PR & Advertising',
  'Management Consulting',
  'Telecommunications',
  'Pharmaceuticals & Biotech',
  'Warehousing & Distribution',
  'Agriculture & AgriTech',
  'Government & Public Sector',
  'Other',
];

enum ProjectStatus {
  planning,
  active,
  onHold,
  completed,
  cancelled,
  archived;

  String get displayName {
    switch (this) {
      case ProjectStatus.planning:
        return 'Planning';
      case ProjectStatus.active:
        return 'Active';
      case ProjectStatus.onHold:
        return 'On Hold';
      case ProjectStatus.completed:
        return 'Completed';
      case ProjectStatus.cancelled:
        return 'Cancelled';
      case ProjectStatus.archived:
        return 'Archived';
    }
  }

  static ProjectStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'active':
      case 'inprogress':
        return ProjectStatus.active;
      case 'onhold':
        return ProjectStatus.onHold;
      case 'completed':
        return ProjectStatus.completed;
      case 'cancelled':
        return ProjectStatus.cancelled;
      case 'archived':
        return ProjectStatus.archived;
      default:
        return ProjectStatus.planning;
    }
  }
}

enum ProjectType {
  website,
  mobileApp,
  webApplication,
  uiUxDesign,
  ecommerce,
  apiBackend,
  adminPanel,
  maintenance,
  consulting,
  other;

  String get displayName {
    switch (this) {
      case ProjectType.website:
        return 'Website';
      case ProjectType.mobileApp:
        return 'Mobile App';
      case ProjectType.webApplication:
        return 'Web Application';
      case ProjectType.uiUxDesign:
        return 'UI/UX Design';
      case ProjectType.ecommerce:
        return 'E-commerce';
      case ProjectType.apiBackend:
        return 'API / Backend';
      case ProjectType.adminPanel:
        return 'Admin Panel';
      case ProjectType.maintenance:
        return 'Maintenance';
      case ProjectType.consulting:
        return 'Consulting';
      case ProjectType.other:
        return 'Other';
    }
  }

  static ProjectType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'website':
        return ProjectType.website;
      case 'mobileapp':
      case 'mobile':
        return ProjectType.mobileApp;
      case 'webapplication':
      case 'webapp':
        return ProjectType.webApplication;
      case 'uiuxdesign':
      case 'design':
        return ProjectType.uiUxDesign;
      case 'ecommerce':
        return ProjectType.ecommerce;
      case 'apibackend':
      case 'backend':
      case 'api':
        return ProjectType.apiBackend;
      case 'adminpanel':
        return ProjectType.adminPanel;
      case 'maintenance':
        return ProjectType.maintenance;
      case 'consulting':
        return ProjectType.consulting;
      default:
        return ProjectType.other;
    }
  }
}

enum ProjectPriority {
  low,
  medium,
  high,
  urgent;

  String get displayName {
    switch (this) {
      case ProjectPriority.low:
        return 'Low';
      case ProjectPriority.medium:
        return 'Medium';
      case ProjectPriority.high:
        return 'High';
      case ProjectPriority.urgent:
        return 'Urgent';
    }
  }

  static ProjectPriority fromString(String value) {
    switch (value.toLowerCase()) {
      case 'low':
        return ProjectPriority.low;
      case 'high':
        return ProjectPriority.high;
      case 'urgent':
        return ProjectPriority.urgent;
      default:
        return ProjectPriority.medium;
    }
  }
}

enum QuotationStatus {
  draft,
  sent,
  viewed,
  accepted,
  rejected,
  expired,
  cancelled,
  converted;

  String get displayName {
    switch (this) {
      case QuotationStatus.draft:
        return 'Draft';
      case QuotationStatus.sent:
        return 'Sent';
      case QuotationStatus.viewed:
        return 'Viewed';
      case QuotationStatus.accepted:
        return 'Accepted';
      case QuotationStatus.rejected:
        return 'Rejected';
      case QuotationStatus.expired:
        return 'Expired';
      case QuotationStatus.cancelled:
        return 'Cancelled';
      case QuotationStatus.converted:
        return 'Converted';
    }
  }

  static QuotationStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'sent':
        return QuotationStatus.sent;
      case 'viewed':
        return QuotationStatus.viewed;
      case 'accepted':
        return QuotationStatus.accepted;
      case 'rejected':
        return QuotationStatus.rejected;
      case 'expired':
        return QuotationStatus.expired;
      case 'cancelled':
        return QuotationStatus.cancelled;
      case 'converted':
        return QuotationStatus.converted;
      default:
        return QuotationStatus.draft;
    }
  }
}

enum QuotationItemType {
  product,
  service,
  other;

  String get displayName {
    switch (this) {
      case QuotationItemType.product:
        return 'Product';
      case QuotationItemType.service:
        return 'Service';
      case QuotationItemType.other:
        return 'Other';
    }
  }

  static QuotationItemType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'product':
        return QuotationItemType.product;
      case 'service':
        return QuotationItemType.service;
      default:
        return QuotationItemType.other;
    }
  }
}

enum DiscountType {
  percentage,
  fixedAmount;

  String get displayName => this == percentage ? 'Percentage (%)' : 'Fixed (₹)';

  static DiscountType fromString(String value) {
    return value.toLowerCase() == 'fixedamount' || value.toLowerCase() == 'fixed'
        ? DiscountType.fixedAmount
        : DiscountType.percentage;
  }
}

enum TaxType {
  gst,
  vat,
  custom,
  none;

  String get displayName {
    switch (this) {
      case TaxType.gst:
        return 'GST';
      case TaxType.vat:
        return 'VAT';
      case TaxType.custom:
        return 'Custom';
      case TaxType.none:
        return 'None (0%)';
    }
  }

  static TaxType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'gst':
        return TaxType.gst;
      case 'vat':
        return TaxType.vat;
      case 'none':
        return TaxType.none;
      default:
        return TaxType.custom;
    }
  }
}

enum ActivityType {
  leadCreated,
  leadUpdated,
  statusChanged,
  followUpCreated,
  followUpCompleted,
  followUpRescheduled,
  followUpCancelled,
  followUpReminderSent,
  noteAdded,
  documentUploaded,
  quotationCreated,
  quotationUpdated,
  quotationSent,
  quotationViewed,
  quotationAccepted,
  quotationRejected,
  quotationRevised,
  quotationPdfGenerated,
  quotationShared,
  quotationConvertedToProject,
  quotationArchived,
  quotationRestored,
  quotationNoteAdded,
  projectCreated,
  projectUpdated,
  projectStatusChanged,
  projectPriorityChanged,
  projectAssigned,
  projectManagerChanged,
  projectProgressUpdated,
  projectMilestoneCreated,
  projectTaskCreated,
  projectTaskCompleted,
  projectNoteAdded,
  projectArchived,
  projectRestored,
  convertedToClient,
  clientCreated,
  clientCreatedFromLead,
  clientUpdated,
  clientStatusChanged,
  clientArchived,
  clientRestored,
  clientNoteAdded,
}

enum ReminderOption {
  noReminder(null, 'No Reminder', false),
  atTime(0, 'At Time', true),
  fiveMin(5, '5 Minutes Before', true),
  fifteenMin(15, '15 Minutes Before', true),
  thirtyMin(30, '30 Minutes Before', true),
  oneHour(60, '1 Hour Before', true),
  twoHours(120, '2 Hours Before', true),
  oneDay(1440, '1 Day Before', true);

  final int? minutes;
  final String displayName;
  final bool isEnabled;

  const ReminderOption(this.minutes, this.displayName, this.isEnabled);

  static ReminderOption fromMinutes(int? minutes, bool enabled) {
    if (!enabled || minutes == null) return ReminderOption.noReminder;
    switch (minutes) {
      case 0:
        return ReminderOption.atTime;
      case 5:
        return ReminderOption.fiveMin;
      case 15:
        return ReminderOption.fifteenMin;
      case 30:
        return ReminderOption.thirtyMin;
      case 60:
        return ReminderOption.oneHour;
      case 120:
        return ReminderOption.twoHours;
      case 1440:
        return ReminderOption.oneDay;
      default:
        return ReminderOption.thirtyMin;
    }
  }
}

enum ReminderMinutes {
  fifteenMin,
  thirtyMin,
  oneHour,
  oneDay;

  int get minutes {
    switch (this) {
      case ReminderMinutes.fifteenMin:
        return 15;
      case ReminderMinutes.thirtyMin:
        return 30;
      case ReminderMinutes.oneHour:
        return 60;
      case ReminderMinutes.oneDay:
        return 1440;
    }
  }

  String get displayName {
    switch (this) {
      case ReminderMinutes.fifteenMin:
        return '15 minutes before';
      case ReminderMinutes.thirtyMin:
        return '30 minutes before';
      case ReminderMinutes.oneHour:
        return '1 hour before';
      case ReminderMinutes.oneDay:
        return '1 day before';
    }
  }

  static ReminderMinutes fromMinutes(int minutes) {
    switch (minutes) {
      case 15:
        return ReminderMinutes.fifteenMin;
      case 30:
        return ReminderMinutes.thirtyMin;
      case 60:
        return ReminderMinutes.oneHour;
      default:
        return ReminderMinutes.oneDay;
    }
  }
}

class AppCollections {
  static const String users = 'users';
  static const String devices = 'devices';
  static const String leads = 'leads';
  static const String followups = 'followUps';
  static const String clients = 'clients';
  static const String clientActivities = 'activities';
  static const String clientNotes = 'notes';
  static const String projects = 'projects';
  static const String projectActivities = 'activities';
  static const String projectNotes = 'notes';
  static const String projectRequirements = 'requirements';
  static const String projectTasks = 'tasks';
  static const String projectMilestones = 'milestones';
  static const String quotations = 'quotations';
  static const String quotationItems = 'items';
  static const String quotationActivities = 'activities';
  static const String quotationNotes = 'notes';
  static const String counters = 'counters';
  static const String documents = 'documents';
  static const String activities = 'activities';
  static const String notifications = 'notifications';
  static const String settings = 'settings';
  static const String expenses = 'expenses';
  static const String expenseActivities = 'activities';
  static const String moneyTransactions = 'moneyTransactions';
  static const String expenseAccounts = 'expenseAccounts';
  static const String expenseAccountSummaries = 'expenseAccountSummaries';
  static const String expenseDashboardSummaries = 'expenseDashboardSummaries';
}

class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String dashboard = '/dashboard';
  static const String leads = '/leads';
  static const String leadDetail = '/leads/:id';
  static const String leadCreate = '/leads/create';
  static const String leadEdit = '/leads/:id/edit';
  static const String followups = '/followups';
  static const String followupCreate = '/followups/create';
  static const String clients = '/clients';
  static const String clientDetail = '/clients/:id';
  static const String clientCreate = '/clients/new';
  static const String clientEdit = '/clients/:id/edit';
  static const String projects = '/projects';
  static const String projectDetail = '/projects/:id';
  static const String projectCreate = '/projects/new';
  static const String projectEdit = '/projects/:id/edit';
  static const String quotations = '/quotations';
  static const String quotationDetail = '/quotations/:id';
  static const String quotationCreate = '/quotations/new';
  static const String quotationEdit = '/quotations/:id/edit';
  static const String documents = '/documents';
  static const String notifications = '/notifications';
  static const String reports = '/reports';
  static const String users = '/users';
  static const String settings = '/settings';
  static const String more = '/more';
  static const String expenses = '/expenses';
  static const String expenseCreate = '/expenses/create';
  static const String expenseAddMoney = '/expenses/add-money';
  static const String expenseDetail = '/expenses/:id';
  static const String expenseEdit = '/expenses/:id/edit';
  static const String expenseAccountDetail = '/expenses/accounts/:id';
}

enum ExpenseCategory {
  travel,
  food,
  fuel,
  hosting,
  domain,
  software,
  subscription,
  marketing,
  office,
  equipment,
  clientExpense,
  communication,
  bankCharges,
  other;

  String get displayName {
    switch (this) {
      case ExpenseCategory.travel:
        return 'Travel';
      case ExpenseCategory.food:
        return 'Food';
      case ExpenseCategory.fuel:
        return 'Fuel';
      case ExpenseCategory.hosting:
        return 'Hosting';
      case ExpenseCategory.domain:
        return 'Domain';
      case ExpenseCategory.software:
        return 'Software';
      case ExpenseCategory.subscription:
        return 'Subscription';
      case ExpenseCategory.marketing:
        return 'Marketing';
      case ExpenseCategory.office:
        return 'Office';
      case ExpenseCategory.equipment:
        return 'Equipment';
      case ExpenseCategory.clientExpense:
        return 'Client Expense';
      case ExpenseCategory.communication:
        return 'Communication';
      case ExpenseCategory.bankCharges:
        return 'Bank Charges';
      case ExpenseCategory.other:
        return 'Other';
    }
  }

  static ExpenseCategory fromString(String? value) {
    if (value == null) return ExpenseCategory.other;
    final normalized = value.toLowerCase().replaceAll(' ', '').replaceAll('-', '');
    for (final cat in ExpenseCategory.values) {
      if (cat.name.toLowerCase() == normalized ||
          cat.displayName.toLowerCase().replaceAll(' ', '') == normalized) {
        return cat;
      }
    }
    return ExpenseCategory.other;
  }
}

enum ExpensePaymentMethod {
  cash,
  upi,
  bankTransfer,
  debitCard,
  creditCard,
  other;

  String get displayName {
    switch (this) {
      case ExpensePaymentMethod.cash:
        return 'Cash';
      case ExpensePaymentMethod.upi:
        return 'UPI';
      case ExpensePaymentMethod.bankTransfer:
        return 'Bank Transfer';
      case ExpensePaymentMethod.debitCard:
        return 'Debit Card';
      case ExpensePaymentMethod.creditCard:
        return 'Credit Card';
      case ExpensePaymentMethod.other:
        return 'Other';
    }
  }

  static ExpensePaymentMethod fromString(String? value) {
    if (value == null) return ExpensePaymentMethod.upi;
    final normalized = value.toLowerCase().replaceAll(' ', '').replaceAll('_', '');
    for (final m in ExpensePaymentMethod.values) {
      if (m.name.toLowerCase() == normalized ||
          m.displayName.toLowerCase().replaceAll(' ', '') == normalized) {
        return m;
      }
    }
    return ExpensePaymentMethod.other;
  }
}

enum MoneyTransactionType {
  credit,
  debit;

  String get displayName {
    switch (this) {
      case MoneyTransactionType.credit:
        return 'Credit';
      case MoneyTransactionType.debit:
        return 'Debit';
    }
  }

  static MoneyTransactionType fromString(String? value) {
    if (value == 'debit') return MoneyTransactionType.debit;
    return MoneyTransactionType.credit;
  }
}
