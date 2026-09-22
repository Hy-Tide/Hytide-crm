// lib/features/documents/models/document_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class DocumentModel extends Equatable {
  final String id;
  final String name;
  final String fileUrl;
  final String fileType; // pdf, image, doc, xls, other
  final int sizeBytes;
  final String uploadedBy;
  final String uploadedByName;
  final DateTime uploadedAt;
  final String? leadId;
  final String? clientId;
  final String? projectId;

  const DocumentModel({
    required this.id,
    required this.name,
    required this.fileUrl,
    required this.fileType,
    required this.sizeBytes,
    required this.uploadedBy,
    required this.uploadedByName,
    required this.uploadedAt,
    this.leadId,
    this.clientId,
    this.projectId,
  });

  factory DocumentModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return DocumentModel(
      id: doc.id,
      name: data['name'] as String? ?? '',
      fileUrl: data['fileUrl'] as String? ?? '',
      fileType: data['fileType'] as String? ?? 'other',
      sizeBytes: data['sizeBytes'] as int? ?? 0,
      uploadedBy: data['uploadedBy'] as String? ?? '',
      uploadedByName: data['uploadedByName'] as String? ?? '',
      uploadedAt:
          (data['uploadedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      leadId: data['leadId'] as String?,
      clientId: data['clientId'] as String?,
      projectId: data['projectId'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'fileUrl': fileUrl,
      'fileType': fileType,
      'sizeBytes': sizeBytes,
      'uploadedBy': uploadedBy,
      'uploadedByName': uploadedByName,
      'uploadedAt': Timestamp.fromDate(uploadedAt),
      'leadId': leadId,
      'clientId': clientId,
      'projectId': projectId,
    };
  }

  IconData get icon {
    switch (fileType.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf_rounded;
      case 'image':
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Icons.image_rounded;
      case 'doc':
      case 'docx':
        return Icons.description_rounded;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart_rounded;
      case 'link':
      case 'url':
        return Icons.link_rounded;
      default:
        return Icons.attach_file_rounded;
    }
  }

  Color get iconColor {
    switch (fileType.toLowerCase()) {
      case 'pdf':
        return const Color(0xFFDC2626);
      case 'image':
      case 'jpg':
      case 'jpeg':
      case 'png':
        return const Color(0xFF7C3AED);
      case 'doc':
      case 'docx':
        return const Color(0xFF2563EB);
      case 'xls':
      case 'xlsx':
        return const Color(0xFF16A34A);
      case 'link':
      case 'url':
        return const Color(0xFF0284C7);
      default:
        return const Color(0xFF64748B);
    }
  }

  bool get isLink => fileType == 'link' || (sizeBytes == 0 && (fileUrl.startsWith('http://') || fileUrl.startsWith('https://')));

  static String getFileType(String fileName) {
    if (fileName.startsWith('http://') || fileName.startsWith('https://')) {
      return 'link';
    }
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf':
        return 'pdf';
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'webp':
        return 'image';
      case 'doc':
      case 'docx':
        return 'doc';
      case 'xls':
      case 'xlsx':
        return 'xls';
      default:
        return 'other';
    }
  }

  DocumentModel copyWith({
    String? id,
    String? name,
    String? fileUrl,
    String? fileType,
    int? sizeBytes,
    String? uploadedBy,
    String? uploadedByName,
    DateTime? uploadedAt,
    String? leadId,
    String? clientId,
    String? projectId,
  }) {
    return DocumentModel(
      id: id ?? this.id,
      name: name ?? this.name,
      fileUrl: fileUrl ?? this.fileUrl,
      fileType: fileType ?? this.fileType,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      uploadedBy: uploadedBy ?? this.uploadedBy,
      uploadedByName: uploadedByName ?? this.uploadedByName,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      leadId: leadId ?? this.leadId,
      clientId: clientId ?? this.clientId,
      projectId: projectId ?? this.projectId,
    );
  }

  @override
  List<Object?> get props => [id, name, fileUrl, uploadedBy, uploadedAt];
}
