// lib/features/documents/widgets/upload_document_dialog.dart
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/app_extensions.dart';
import '../../../core/widgets/app_dialogs.dart';
import '../../auth/repositories/auth_repository.dart';
import '../../clients/repositories/client_repository.dart';
import '../../leads/repositories/lead_repository.dart';
import '../../projects/repositories/project_repository.dart';
import '../models/document_model.dart';
import '../repositories/document_repository.dart';

enum DocumentSourceMode { file, link }

class UploadDocumentDialog extends ConsumerStatefulWidget {
  final String? initialLeadId;
  final String? initialClientId;
  final String? initialProjectId;

  const UploadDocumentDialog({
    super.key,
    this.initialLeadId,
    this.initialClientId,
    this.initialProjectId,
  });

  static Future<bool?> show(
    BuildContext context, {
    String? initialLeadId,
    String? initialClientId,
    String? initialProjectId,
  }) {
    return showDialog<bool>(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => UploadDocumentDialog(
        initialLeadId: initialLeadId,
        initialClientId: initialClientId,
        initialProjectId: initialProjectId,
      ),
    );
  }

  @override
  ConsumerState<UploadDocumentDialog> createState() => _UploadDocumentDialogState();
}

class _UploadDocumentDialogState extends ConsumerState<UploadDocumentDialog> {
  DocumentSourceMode _sourceMode = DocumentSourceMode.file;

  // File upload state
  PlatformFile? _pickedFile;

  // Link input state
  final _urlController = TextEditingController();
  String _linkFormatType = 'pdf'; // pdf, doc, xls, link

  // General fields
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String _entityType = 'general'; // project, lead, client, general (Other Doc)
  String? _selectedEntityId;
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.initialProjectId != null) {
      _entityType = 'project';
      _selectedEntityId = widget.initialProjectId;
    } else if (widget.initialLeadId != null) {
      _entityType = 'lead';
      _selectedEntityId = widget.initialLeadId;
    } else if (widget.initialClientId != null) {
      _entityType = 'client';
      _selectedEntityId = widget.initialClientId;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'csv', 'png', 'jpg', 'jpeg', 'txt', 'zip'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        setState(() {
          _pickedFile = file;
          _errorMessage = null;
          if (_nameController.text.trim().isEmpty) {
            _nameController.text = file.name;
          }
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to select file: $e';
      });
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final currentUser = ref.read(currentUserModelProvider).asData?.value;
    final userId = currentUser?.uid ?? 'unknown';
    final userName = currentUser?.displayName ?? 'Current User';

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.05;
      _errorMessage = null;
    });

    try {
      String finalFileUrl = '';
      String finalFileType = 'other';
      int finalSizeBytes = 0;

      if (_sourceMode == DocumentSourceMode.file) {
        if (_pickedFile == null) {
          setState(() {
            _isUploading = false;
            _errorMessage = 'Please choose a file to upload';
          });
          return;
        }

        final storageService = StorageService();
        final extension = _pickedFile!.extension ?? _pickedFile!.name.split('.').last;
        finalFileType = DocumentModel.getFileType(_pickedFile!.name);
        finalSizeBytes = _pickedFile!.size;
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final sanitizedName = _pickedFile!.name.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
        final path = 'documents/$_entityType/${_selectedEntityId ?? 'general'}/${timestamp}_$sanitizedName';

        dynamic filePayload;
        if (kIsWeb || _pickedFile!.bytes != null) {
          filePayload = _pickedFile!.bytes;
        } else if (_pickedFile!.path != null) {
          filePayload = File(_pickedFile!.path!);
        } else {
          throw Exception('No file data available for upload');
        }

        finalFileUrl = await storageService.uploadFile(
          path: path,
          file: filePayload,
          contentType: _getContentType(extension),
          onProgress: (progress) {
            if (mounted) {
              setState(() {
                _uploadProgress = progress;
              });
            }
          },
        );
      } else {
        // Link Mode
        final inputUrl = _urlController.text.trim();
        finalFileUrl = inputUrl.startsWith('http://') || inputUrl.startsWith('https://')
            ? inputUrl
            : 'https://$inputUrl';
        finalFileType = _linkFormatType;
        finalSizeBytes = 0;
      }

      final doc = DocumentModel(
        id: '',
        name: _nameController.text.trim(),
        fileUrl: finalFileUrl,
        fileType: finalFileType,
        sizeBytes: finalSizeBytes,
        uploadedBy: userId,
        uploadedByName: userName,
        uploadedAt: DateTime.now(),
        leadId: _entityType == 'lead' ? _selectedEntityId : null,
        clientId: _entityType == 'client' ? _selectedEntityId : null,
        projectId: _entityType == 'project' ? _selectedEntityId : null,
      );

      await ref.read(documentRepositoryProvider).addDocument(doc);

      if (mounted) {
        AppToast.success(
          context,
          _sourceMode == DocumentSourceMode.file
              ? 'Document uploaded successfully'
              : 'Document link added successfully',
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _errorMessage = 'Failed: $e';
        });
      }
    }
  }

  String _getContentType(String ext) {
    switch (ext.toLowerCase()) {
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'xls':
        return 'application/vnd.ms-excel';
      case 'xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case 'png':
        return 'image/png';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      default:
        return 'application/octet-stream';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Icon(
                        _sourceMode == DocumentSourceMode.file
                            ? Icons.upload_file_rounded
                            : Icons.add_link_rounded,
                        color: AppColors.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _sourceMode == DocumentSourceMode.file
                                ? 'Upload Document File'
                                : 'Add Document Link',
                            style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
                          ),
                          Text(
                            'Attach PDF, Doc, or cloud links to Project, Lead, or Other Doc',
                            style: AppTypography.caption.copyWith(
                              color: isDark ? AppColors.onSurfaceVariantDark : AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: _isUploading ? null : () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),

                // Source Mode Toggle: File Upload vs Cloud Link
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceContainerDark : AppColors.surfaceContainer,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: _isUploading
                              ? null
                              : () => setState(() => _sourceMode = DocumentSourceMode.file),
                          borderRadius: BorderRadius.horizontal(left: Radius.circular(AppRadius.md)),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _sourceMode == DocumentSourceMode.file
                                  ? AppColors.primary
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(AppRadius.md),
                            ),
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.file_upload_outlined,
                                  size: 18,
                                  color: _sourceMode == DocumentSourceMode.file
                                      ? Colors.white
                                      : (isDark ? AppColors.onSurfaceDark : AppColors.onSurface),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Upload File (PDF / Doc)',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    color: _sourceMode == DocumentSourceMode.file
                                        ? Colors.white
                                        : (isDark ? AppColors.onSurfaceDark : AppColors.onSurface),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: InkWell(
                          onTap: _isUploading
                              ? null
                              : () => setState(() => _sourceMode = DocumentSourceMode.link),
                          borderRadius: BorderRadius.horizontal(right: Radius.circular(AppRadius.md)),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _sourceMode == DocumentSourceMode.link
                                  ? AppColors.primary
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(AppRadius.md),
                            ),
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.link_rounded,
                                  size: 18,
                                  color: _sourceMode == DocumentSourceMode.link
                                      ? Colors.white
                                      : (isDark ? AppColors.onSurfaceDark : AppColors.onSurface),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Paste Link / URL',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    color: _sourceMode == DocumentSourceMode.link
                                        ? Colors.white
                                        : (isDark ? AppColors.onSurfaceDark : AppColors.onSurface),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // File Picker Zone (if file mode)
                if (_sourceMode == DocumentSourceMode.file) ...[
                  InkWell(
                    onTap: _isUploading ? null : _pickFile,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.surfaceContainerDark : AppColors.surfaceContainer,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(
                          color: _pickedFile != null
                              ? AppColors.primary
                              : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                          width: _pickedFile != null ? 1.5 : 1,
                        ),
                      ),
                      child: _pickedFile == null
                          ? Column(
                              children: [
                                const Icon(Icons.cloud_upload_outlined, size: 38, color: AppColors.primary),
                                const SizedBox(height: AppSpacing.sm),
                                Text(
                                  'Click to select PDF or Doc file',
                                  style: AppTypography.bodyMedium.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? AppColors.onSurfaceDark : AppColors.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'PDF, DOCX, XLSX, PNG, JPG (up to 25MB)',
                                  style: AppTypography.caption.copyWith(
                                    color: isDark ? AppColors.onSurfaceVariantDark : AppColors.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            )
                          : Row(
                              children: [
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(AppRadius.sm),
                                  ),
                                  child: const Icon(Icons.insert_drive_file_rounded, color: AppColors.primary),
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _pickedFile!.name,
                                        style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _pickedFile!.size.fileSizeFormatted,
                                        style: AppTypography.caption.copyWith(
                                          color: isDark ? AppColors.onSurfaceVariantDark : AppColors.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                TextButton(
                                  onPressed: _isUploading ? null : _pickFile,
                                  child: const Text('Change'),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ] else ...[
                  // Link input field
                  TextFormField(
                    controller: _urlController,
                    enabled: !_isUploading,
                    keyboardType: TextInputType.url,
                    decoration: const InputDecoration(
                      labelText: 'Document Link / URL *',
                      hintText: 'https://docs.google.com/... or Google Drive / Figma link',
                      prefixIcon: Icon(Icons.link_rounded, size: 20),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please provide a valid document URL';
                      }
                      if (!value.contains('.') || value.trim().length < 5) {
                        return 'Please enter a valid web link';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Format selection for Link
                  DropdownButtonFormField<String>(
                    value: _linkFormatType,
                    decoration: const InputDecoration(
                      labelText: 'Link Content Type',
                      prefixIcon: Icon(Icons.category_rounded, size: 20),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'pdf', child: Text('PDF (Cloud Document)')),
                      DropdownMenuItem(value: 'doc', child: Text('Google Doc / Word')),
                      DropdownMenuItem(value: 'xls', child: Text('Google Sheet / Excel')),
                      DropdownMenuItem(value: 'link', child: Text('Design Link (Figma / Web)')),
                      DropdownMenuItem(value: 'other', child: Text('General Web Link')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _linkFormatType = val);
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],

                // Document Display Name Field
                TextFormField(
                  controller: _nameController,
                  enabled: !_isUploading,
                  decoration: const InputDecoration(
                    labelText: 'Document Title *',
                    hintText: 'e.g. Master Services Agreement / Project Spec',
                    prefixIcon: Icon(Icons.title_rounded, size: 20),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please provide a document title';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.lg),

                // Association Selector: Project, Lead, Client, or Other Doc
                Text(
                  'Attach Option (Project, Lead, Client, or Other Doc):',
                  style: AppTypography.bodySmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.onSurfaceDark : AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: 'project',
                      label: Text('Project'),
                      icon: Icon(Icons.folder_outlined, size: 16),
                    ),
                    ButtonSegment(
                      value: 'lead',
                      label: Text('Lead'),
                      icon: Icon(Icons.person_outline_rounded, size: 16),
                    ),
                    ButtonSegment(
                      value: 'client',
                      label: Text('Client'),
                      icon: Icon(Icons.business_outlined, size: 16),
                    ),
                    ButtonSegment(
                      value: 'general',
                      label: Text('Other Doc'),
                      icon: Icon(Icons.description_outlined, size: 16),
                    ),
                  ],
                  selected: {_entityType},
                  onSelectionChanged: _isUploading
                      ? null
                      : (newSet) {
                          setState(() {
                            _entityType = newSet.first;
                            _selectedEntityId = null;
                          });
                        },
                ),
                const SizedBox(height: AppSpacing.md),

                // Dynamic Dropdown for selected option
                if (_entityType != 'general') ...[
                  _buildEntityDropdown(isDark),
                  const SizedBox(height: AppSpacing.md),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline_rounded, size: 16, color: AppColors.secondary),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: Text(
                            'Saved as "Other Doc" (General company document accessible across all teams)',
                            style: AppTypography.caption.copyWith(color: AppColors.secondary),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],

                // Error Message
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 18),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: AppTypography.caption.copyWith(color: AppColors.error),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],

                // Upload Progress Bar
                if (_isUploading && _sourceMode == DocumentSourceMode.file) ...[
                  LinearProgressIndicator(value: _uploadProgress > 0 ? _uploadProgress : null),
                  const SizedBox(height: AppSpacing.xs),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'Uploading... ${(_uploadProgress * 100).toStringAsFixed(0)}%',
                      style: AppTypography.caption.copyWith(color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],

                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: _isUploading ? null : () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    FilledButton.icon(
                      onPressed: _isUploading ? null : _handleSubmit,
                      icon: _isUploading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Icon(
                              _sourceMode == DocumentSourceMode.file
                                  ? Icons.cloud_upload_rounded
                                  : Icons.save_rounded,
                              size: 18,
                            ),
                      label: Text(
                        _isUploading
                            ? 'Saving...'
                            : (_sourceMode == DocumentSourceMode.file ? 'Upload File' : 'Save Document Link'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEntityDropdown(bool isDark) {
    if (_entityType == 'project') {
      final projectsAsync = ref.watch(projectsStreamProvider);
      return projectsAsync.when(
        loading: () => const LinearProgressIndicator(),
        error: (e, _) => Text('Error loading projects: $e', style: const TextStyle(color: AppColors.error)),
        data: (projects) {
          return DropdownButtonFormField<String>(
            value: _selectedEntityId,
            decoration: const InputDecoration(
              labelText: 'Select Project *',
              prefixIcon: Icon(Icons.folder_rounded, size: 20),
            ),
            items: projects.map((p) {
              return DropdownMenuItem<String>(
                value: p.id,
                child: Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis),
              );
            }).toList(),
            validator: (val) => val == null ? 'Please select a project' : null,
            onChanged: _isUploading ? null : (val) => setState(() => _selectedEntityId = val),
          );
        },
      );
    } else if (_entityType == 'lead') {
      final leadsAsync = ref.watch(leadsStreamProvider);
      return leadsAsync.when(
        loading: () => const LinearProgressIndicator(),
        error: (e, _) => Text('Error loading leads: $e', style: const TextStyle(color: AppColors.error)),
        data: (leads) {
          return DropdownButtonFormField<String>(
            value: _selectedEntityId,
            decoration: const InputDecoration(
              labelText: 'Select Lead *',
              prefixIcon: Icon(Icons.person_search_rounded, size: 20),
            ),
            items: leads.map((l) {
              final contact = l.contactPerson.isNotEmpty ? l.contactPerson : l.companyName;
              final company = l.companyName.isNotEmpty ? l.companyName : 'Individual';
              return DropdownMenuItem<String>(
                value: l.id,
                child: Text('$contact ($company)', maxLines: 1, overflow: TextOverflow.ellipsis),
              );
            }).toList(),
            validator: (val) => val == null ? 'Please select a lead' : null,
            onChanged: _isUploading ? null : (val) => setState(() => _selectedEntityId = val),
          );
        },
      );
    } else if (_entityType == 'client') {
      final clientsAsync = ref.watch(clientsStreamProvider);
      return clientsAsync.when(
        loading: () => const LinearProgressIndicator(),
        error: (e, _) => Text('Error loading clients: $e', style: const TextStyle(color: AppColors.error)),
        data: (clients) {
          return DropdownButtonFormField<String>(
            value: _selectedEntityId,
            decoration: const InputDecoration(
              labelText: 'Select Client *',
              prefixIcon: Icon(Icons.business_rounded, size: 20),
            ),
            items: clients.map((c) {
              return DropdownMenuItem<String>(
                value: c.id,
                child: Text(c.companyName, maxLines: 1, overflow: TextOverflow.ellipsis),
              );
            }).toList(),
            validator: (val) => val == null ? 'Please select a client' : null,
            onChanged: _isUploading ? null : (val) => setState(() => _selectedEntityId = val),
          );
        },
      );
    }
    return const SizedBox.shrink();
  }
}
