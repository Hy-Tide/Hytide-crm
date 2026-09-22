// lib/features/settings/repositories/settings_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../models/company_settings_model.dart';

class SettingsRepository {
  final FirebaseFirestore _db;

  SettingsRepository({required FirebaseFirestore db}) : _db = db;

  DocumentReference<Map<String, dynamic>> get _companyDoc =>
      _db.collection(AppCollections.settings).doc('company');

  Stream<CompanySettingsModel> streamCompanySettings() {
    return _companyDoc.snapshots().map((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        return CompanySettingsModel.fromFirestore(snapshot);
      }
      return const CompanySettingsModel();
    });
  }

  Future<void> updateCompanySettings(CompanySettingsModel settings) async {
    await _companyDoc.set(settings.toMap(), SetOptions(merge: true));
  }
}

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository(db: FirebaseFirestore.instance);
});

final companySettingsStreamProvider = StreamProvider<CompanySettingsModel>((ref) {
  return ref.watch(settingsRepositoryProvider).streamCompanySettings();
});
