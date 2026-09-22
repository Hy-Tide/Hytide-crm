// lib/features/quotations/services/quotation_number_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/timezone_helper.dart';

class QuotationNumberService {
  final FirebaseFirestore _db;

  QuotationNumberService({required FirebaseFirestore db}) : _db = db;

  DocumentReference<Map<String, dynamic>> get _counterRef =>
      _db.collection(AppCollections.counters).doc('quotations');

  /// Atomically generate the next sequential quotation number: QT-YYYY-XXXX
  Future<String> generateNextQuotationNumber() async {
    final currentYear = TimezoneHelper.now().year;

    return await _db.runTransaction<String>((transaction) async {
      final snapshot = await transaction.get(_counterRef);

      int year = currentYear;
      int nextNumber = 1;

      if (snapshot.exists && snapshot.data() != null) {
        final data = snapshot.data()!;
        final recordedYear = (data['year'] as num?)?.toInt() ?? currentYear;
        final recordedNumber = (data['nextNumber'] as num?)?.toInt() ?? 1;

        if (recordedYear == currentYear) {
          year = currentYear;
          nextNumber = recordedNumber;
        } else {
          // New year rollover -> reset sequence to 1
          year = currentYear;
          nextNumber = 1;
        }
      }

      // Write next sequence for future callers
      transaction.set(
        _counterRef,
        {
          'year': year,
          'nextNumber': nextNumber + 1,
          'updatedAt': Timestamp.now(),
        },
        SetOptions(merge: true),
      );

      final paddedNumber = nextNumber.toString().padLeft(4, '0');
      return 'QT-$year-$paddedNumber';
    });
  }

  /// Formats revision suffix: e.g. QT-2026-0001 -> QT-2026-0001-R2
  static String formatRevisionNumber(String baseNumber, int revisionNumber) {
    // Strip existing revision suffix if present
    final cleanBase = baseNumber.replaceAll(RegExp(r'-R\d+$'), '');
    if (revisionNumber <= 1) return cleanBase;
    return '$cleanBase-R$revisionNumber';
  }
}
