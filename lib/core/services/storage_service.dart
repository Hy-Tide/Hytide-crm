// lib/core/services/storage_service.dart
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:mime/mime.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Reference get root => _storage.ref();

  Reference _ref(String path) => _storage.ref().child(path);

  Future<String> uploadFile({
    required String path,
    required dynamic file, // File (mobile) or Uint8List (web)
    String? contentType,
    void Function(double progress)? onProgress,
  }) async {
    final ref = _ref(path);
    UploadTask task;

    if (kIsWeb && file is Uint8List) {
      final metadata = SettableMetadata(contentType: contentType);
      task = ref.putData(file, metadata);
    } else if (file is File) {
      final mimeType = lookupMimeType(file.path);
      final metadata = SettableMetadata(contentType: contentType ?? mimeType);
      task = ref.putFile(file, metadata);
    } else {
      throw ArgumentError('Unsupported file type');
    }

    if (onProgress != null) {
      task.snapshotEvents.listen((snapshot) {
        if (snapshot.totalBytes > 0) {
          onProgress(snapshot.bytesTransferred / snapshot.totalBytes);
        }
      });
    }

    final snapshot = await task;
    return await snapshot.ref.getDownloadURL();
  }

  Future<void> deleteFile(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
    } catch (e) {
      // Ignore if file doesn't exist
    }
  }

  String getDocumentPath({
    required String entityType, // lead, client, project
    required String entityId,
    required String fileName,
  }) {
    return 'documents/$entityType/$entityId/$fileName';
  }

  String getProfilePhotoPath(String userId, String fileName) {
    return 'profiles/$userId/$fileName';
  }
}
