// lib/core/events/app_domain_events.dart
import '../../features/leads/models/lead_model.dart';
import '../../features/followups/models/followup_model.dart';
import '../../features/clients/models/client_model.dart';
import '../../features/quotations/models/quotation_model.dart';
import '../../features/projects/models/project_model.dart';
import '../constants/app_constants.dart';

/// Sealed root for all domain events across the CRM
sealed class AppDomainEvent {
  const AppDomainEvent();
}

// ─── Lead Events ─────────────────────────────────────────────────────────────

class LeadCreatedEvent extends AppDomainEvent {
  final LeadModel lead;
  const LeadCreatedEvent(this.lead);
}

class LeadUpdatedEvent extends AppDomainEvent {
  final LeadModel lead;
  const LeadUpdatedEvent(this.lead);
}

class LeadStatusChangedEvent extends AppDomainEvent {
  final LeadModel lead;
  final LeadStatus oldStatus;
  final LeadStatus newStatus;

  const LeadStatusChangedEvent(
    this.lead, {
    required this.oldStatus,
    required this.newStatus,
  });
}

class LeadDeletedEvent extends AppDomainEvent {
  final String leadId;
  const LeadDeletedEvent(this.leadId);
}

// ─── Follow-up Events ────────────────────────────────────────────────────────

class FollowUpCreatedEvent extends AppDomainEvent {
  final FollowUpModel followUp;
  const FollowUpCreatedEvent(this.followUp);
}

class FollowUpUpdatedEvent extends AppDomainEvent {
  final FollowUpModel followUp;
  const FollowUpUpdatedEvent(this.followUp);
}

class FollowUpCompletedEvent extends AppDomainEvent {
  final FollowUpModel followUp;
  const FollowUpCompletedEvent(this.followUp);
}

class FollowUpCancelledEvent extends AppDomainEvent {
  final FollowUpModel followUp;
  const FollowUpCancelledEvent(this.followUp);
}

class FollowUpDeletedEvent extends AppDomainEvent {
  final String followUpId;
  const FollowUpDeletedEvent(this.followUpId);
}

// ─── Client Events ───────────────────────────────────────────────────────────

class ClientCreatedEvent extends AppDomainEvent {
  final ClientModel client;
  const ClientCreatedEvent(this.client);
}

class ClientUpdatedEvent extends AppDomainEvent {
  final ClientModel client;
  const ClientUpdatedEvent(this.client);
}

class ClientArchivedEvent extends AppDomainEvent {
  final String clientId;
  const ClientArchivedEvent(this.clientId);
}

class ClientRestoredEvent extends AppDomainEvent {
  final String clientId;
  const ClientRestoredEvent(this.clientId);
}

class ClientConvertedEvent extends AppDomainEvent {
  final ClientModel client;
  final String? sourceLeadId;
  const ClientConvertedEvent(this.client, {this.sourceLeadId});
}

// ─── Quotation Events ────────────────────────────────────────────────────────

class QuotationCreatedEvent extends AppDomainEvent {
  final QuotationModel quotation;
  const QuotationCreatedEvent(this.quotation);
}

class QuotationUpdatedEvent extends AppDomainEvent {
  final QuotationModel quotation;
  const QuotationUpdatedEvent(this.quotation);
}

class QuotationStatusChangedEvent extends AppDomainEvent {
  final QuotationModel quotation;
  final QuotationStatus oldStatus;
  final QuotationStatus newStatus;

  const QuotationStatusChangedEvent(
    this.quotation, {
    required this.oldStatus,
    required this.newStatus,
  });
}

class QuotationConvertedEvent extends AppDomainEvent {
  final QuotationModel quotation;
  final String createdProjectId;

  const QuotationConvertedEvent(
    this.quotation, {
    required this.createdProjectId,
  });
}

class QuotationDeletedEvent extends AppDomainEvent {
  final String quotationId;
  const QuotationDeletedEvent(this.quotationId);
}

// ─── Project Events ──────────────────────────────────────────────────────────

class ProjectCreatedEvent extends AppDomainEvent {
  final ProjectModel project;
  const ProjectCreatedEvent(this.project);
}

class ProjectUpdatedEvent extends AppDomainEvent {
  final ProjectModel project;
  const ProjectUpdatedEvent(this.project);
}

class ProjectStatusChangedEvent extends AppDomainEvent {
  final ProjectModel project;
  final ProjectStatus oldStatus;
  final ProjectStatus newStatus;

  const ProjectStatusChangedEvent(
    this.project, {
    required this.oldStatus,
    required this.newStatus,
  });
}

class ProjectCompletedEvent extends AppDomainEvent {
  final ProjectModel project;
  const ProjectCompletedEvent(this.project);
}

class ProjectArchivedEvent extends AppDomainEvent {
  final String projectId;
  const ProjectArchivedEvent(this.projectId);
}

class ProjectRestoredEvent extends AppDomainEvent {
  final String projectId;
  const ProjectRestoredEvent(this.projectId);
}

class ProjectDeletedEvent extends AppDomainEvent {
  final String projectId;
  const ProjectDeletedEvent(this.projectId);
}

// ─── Expense & Money Events ──────────────────────────────────────────────────

class ExpenseCreatedEvent extends AppDomainEvent {
  final String expenseId;
  final double amount;
  final String paidFromAccountId;
  final String? projectId;
  const ExpenseCreatedEvent({
    required this.expenseId,
    required this.amount,
    required this.paidFromAccountId,
    this.projectId,
  });
}

class ExpenseUpdatedEvent extends AppDomainEvent {
  final String expenseId;
  const ExpenseUpdatedEvent(this.expenseId);
}

class ExpenseVoidedEvent extends AppDomainEvent {
  final String expenseId;
  final double restoredAmount;
  final String paidFromAccountId;
  const ExpenseVoidedEvent({
    required this.expenseId,
    required this.restoredAmount,
    required this.paidFromAccountId,
  });
}

class MoneyAddedEvent extends AppDomainEvent {
  final String transactionId;
  final String accountId;
  final double amount;
  const MoneyAddedEvent({
    required this.transactionId,
    required this.accountId,
    required this.amount,
  });
}

