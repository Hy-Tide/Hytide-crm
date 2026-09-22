// lib/features/documents/providers/document_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/document_model.dart';
import '../repositories/document_repository.dart';

enum DocumentViewMode { table, grid }

enum DocumentTypeFilter {
  all('All Files'),
  pdf('PDFs'),
  image('Images'),
  doc('Documents'),
  xls('Spreadsheets'),
  link('Links & URLs'),
  other('Other');

  final String label;
  const DocumentTypeFilter(this.label);
}

enum DocumentEntityFilter {
  all('All Associations'),
  lead('Leads'),
  client('Clients'),
  project('Projects'),
  general('General');

  final String label;
  const DocumentEntityFilter(this.label);
}

class DocumentKpiData {
  final int totalCount;
  final int pdfCount;
  final int sheetCount;
  final int imageCount;
  final int otherCount;
  final int totalSizeBytes;

  const DocumentKpiData({
    this.totalCount = 0,
    this.pdfCount = 0,
    this.sheetCount = 0,
    this.imageCount = 0,
    this.otherCount = 0,
    this.totalSizeBytes = 0,
  });
}

final documentSearchQueryProvider = StateProvider<String>((ref) => '');
final documentTypeFilterProvider = StateProvider<DocumentTypeFilter>((ref) => DocumentTypeFilter.all);
final documentEntityFilterProvider = StateProvider<DocumentEntityFilter>((ref) => DocumentEntityFilter.all);
final documentViewModeProvider = StateProvider<DocumentViewMode>((ref) => DocumentViewMode.table);

final documentKpiProvider = Provider<DocumentKpiData>((ref) {
  final docs = ref.watch(documentsStreamProvider).asData?.value ?? [];

  int pdfs = 0;
  int sheets = 0;
  int images = 0;
  int others = 0;
  int totalBytes = 0;

  for (final doc in docs) {
    totalBytes += doc.sizeBytes;
    final type = doc.fileType.toLowerCase();
    if (type == 'pdf') {
      pdfs++;
    } else if (type == 'xls' || type == 'xlsx' || type == 'csv') {
      sheets++;
    } else if (type == 'image' || type == 'jpg' || type == 'jpeg' || type == 'png') {
      images++;
    } else {
      others++;
    }
  }

  return DocumentKpiData(
    totalCount: docs.length,
    pdfCount: pdfs,
    sheetCount: sheets,
    imageCount: images,
    otherCount: others,
    totalSizeBytes: totalBytes,
  );
});

final filteredDocumentsProvider = Provider<List<DocumentModel>>((ref) {
  final docs = ref.watch(documentsStreamProvider).asData?.value ?? [];
  final query = ref.watch(documentSearchQueryProvider).trim().toLowerCase();
  final typeFilter = ref.watch(documentTypeFilterProvider);
  final entityFilter = ref.watch(documentEntityFilterProvider);

  return docs.where((doc) {
    // Search query
    if (query.isNotEmpty) {
      final nameMatches = doc.name.toLowerCase().contains(query);
      final uploaderMatches = doc.uploadedByName.toLowerCase().contains(query);
      if (!nameMatches && !uploaderMatches) return false;
    }

    // Type filter
    if (typeFilter != DocumentTypeFilter.all) {
      final ft = doc.fileType.toLowerCase();
      switch (typeFilter) {
        case DocumentTypeFilter.pdf:
          if (ft != 'pdf') return false;
          break;
        case DocumentTypeFilter.image:
          if (!['image', 'jpg', 'jpeg', 'png', 'gif', 'webp'].contains(ft)) return false;
          break;
        case DocumentTypeFilter.doc:
          if (!['doc', 'docx', 'txt', 'rtf'].contains(ft)) return false;
          break;
        case DocumentTypeFilter.xls:
          if (!['xls', 'xlsx', 'csv'].contains(ft)) return false;
          break;
        case DocumentTypeFilter.link:
          if (ft != 'link' && ft != 'url' && !doc.isLink) return false;
          break;
        case DocumentTypeFilter.other:
          if (['pdf', 'image', 'jpg', 'jpeg', 'png', 'doc', 'docx', 'xls', 'xlsx', 'link', 'url'].contains(ft) || doc.isLink) {
            return false;
          }
          break;
        case DocumentTypeFilter.all:
          break;
      }
    }

    // Entity association filter
    if (entityFilter != DocumentEntityFilter.all) {
      switch (entityFilter) {
        case DocumentEntityFilter.lead:
          if (doc.leadId == null || doc.leadId!.isEmpty) return false;
          break;
        case DocumentEntityFilter.client:
          if (doc.clientId == null || doc.clientId!.isEmpty) return false;
          break;
        case DocumentEntityFilter.project:
          if (doc.projectId == null || doc.projectId!.isEmpty) return false;
          break;
        case DocumentEntityFilter.general:
          if ((doc.leadId != null && doc.leadId!.isNotEmpty) ||
              (doc.clientId != null && doc.clientId!.isNotEmpty) ||
              (doc.projectId != null && doc.projectId!.isNotEmpty)) {
            return false;
          }
          break;
        case DocumentEntityFilter.all:
          break;
      }
    }

    return true;
  }).toList();
});
