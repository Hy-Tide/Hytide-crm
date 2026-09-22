// test/features/projects/project_model_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:hytide/core/constants/app_constants.dart';
import 'package:hytide/features/projects/models/project_model.dart';

void main() {
  group('ProjectModel Unit Tests', () {
    final now = DateTime(2026, 9, 4, 10, 0);

    final project = ProjectModel(
      id: 'proj-001',
      projectNumber: 'PRJ-2026-0001',
      clientId: 'client-101',
      clientName: 'Rahul Verma',
      companyName: 'TechCorp India',
      sourceQuotationId: 'quot-201',
      quotationNumber: 'QT-2026-0050',
      sourceLeadId: 'lead-301',
      title: 'Enterprise CRM Portal',
      description: 'Full stack web platform development',
      notes: 'Phase 1 MVP priority',
      projectType: ProjectType.webApplication,
      status: ProjectStatus.active,
      priority: ProjectPriority.high,
      startDate: now,
      expectedEndDate: now.add(const Duration(days: 60)),
      actualEndDate: null,
      assignedTo: 'user-emp-1',
      assignedToName: 'Suresh Kumar',
      assignedToNames: const ['Suresh Kumar', 'Anita Roy'],
      projectManager: 'user-mgr-1',
      projectManagerName: 'Anita Roy',
      quotationValue: 250000.0,
      estimatedValue: 250000.0,
      budget: 250000.0,
      progress: 45,
      createdBy: 'user-admin',
      createdByName: 'Admin',
      createdAt: now,
      updatedAt: now,
      isArchived: false,
    );

    test('verifies project fields and getters', () {
      expect(project.id, equals('proj-001'));
      expect(project.projectNumber, equals('PRJ-2026-0001'));
      expect(project.title, equals('Enterprise CRM Portal'));
      expect(project.name, equals('Enterprise CRM Portal')); // backward compatibility
      expect(project.status, equals(ProjectStatus.active));
      expect(project.priority, equals(ProjectPriority.high));
      expect(project.progress, equals(45));
      expect(project.isCompleted, isFalse);
      expect(project.isOverdue, isFalse);
    });

    test('overdue calculation works accurately', () {
      // Past deadline and active -> overdue
      final overdueProject = project.copyWith(
        expectedEndDate: now.subtract(const Duration(days: 5)),
        status: ProjectStatus.active,
      );
      expect(overdueProject.isOverdue, isTrue);

      // Past deadline but completed -> not overdue
      final completedProject = overdueProject.copyWith(
        status: ProjectStatus.completed,
      );
      expect(completedProject.isOverdue, isFalse);
      expect(completedProject.isCompleted, isTrue);

      // Past deadline but cancelled or archived -> not overdue
      final cancelledProject = overdueProject.copyWith(
        status: ProjectStatus.cancelled,
      );
      expect(cancelledProject.isOverdue, isFalse);

      final archivedProject = overdueProject.copyWith(
        status: ProjectStatus.archived,
      );
      expect(archivedProject.isOverdue, isFalse);
    });

    test('search tokens generation includes identifiers and keywords', () {
      final tokens = project.toSearchTokens();
      expect(tokens, contains('prj-2026-0001'));
      expect(tokens, contains('enterprise'));
      expect(tokens, contains('crm'));
      expect(tokens, contains('portal'));
      expect(tokens, contains('techcorp'));
      expect(tokens, contains('rahul'));
    });

    test('static buildSearchTokens generates correct tokens', () {
      final tokens = ProjectModel.buildSearchTokens(
        projectNumber: 'PRJ-2026-0099',
        title: 'Mobile Banking App',
        clientName: 'Amit Patel',
        companyName: 'FinSecure Bank',
      );
      expect(tokens, contains('prj-2026-0099'));
      expect(tokens, contains('mobile'));
      expect(tokens, contains('banking'));
      expect(tokens, contains('amit'));
      expect(tokens, contains('finsecure'));
    });

    test('toMap and fromMap preserves all fields faithfully', () {
      final map = project.toMap();
      expect(map['projectNumber'], equals('PRJ-2026-0001'));
      expect(map['title'], equals('Enterprise CRM Portal'));
      expect(map['name'], equals('Enterprise CRM Portal'));
      expect(map['progress'], equals(45));
      expect(map['budget'], equals(250000.0));
      expect(map['notes'], equals('Phase 1 MVP priority'));

      final restored = ProjectModel.fromMap(map, id: 'proj-001');
      expect(restored.id, equals(project.id));
      expect(restored.projectNumber, equals(project.projectNumber));
      expect(restored.title, equals(project.title));
      expect(restored.status, equals(project.status));
      expect(restored.priority, equals(project.priority));
      expect(restored.notes, equals(project.notes));
    });

    test('copyWith properly updates selective attributes', () {
      final updated = project.copyWith(
        title: 'Enterprise CRM Portal v2',
        progress: 80,
        status: ProjectStatus.completed,
      );
      expect(updated.title, equals('Enterprise CRM Portal v2'));
      expect(updated.progress, equals(80));
      expect(updated.status, equals(ProjectStatus.completed));
      expect(updated.id, equals(project.id));
      expect(updated.projectNumber, equals(project.projectNumber));
    });
  });
}
