// lib/features/expenses/repositories/expense_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_constants.dart';
import '../../auth/repositories/auth_repository.dart';
import '../models/expense_account_model.dart';
import '../models/expense_account_summary_model.dart';
import '../models/expense_activity_model.dart';
import '../models/expense_dashboard_summary_model.dart';
import '../models/expense_filter_model.dart';
import '../models/expense_model.dart';
import '../models/money_transaction_model.dart';

class InsufficientBalanceException implements Exception {
  final String accountName;
  final double currentBalance;
  final double requestedAmount;

  const InsufficientBalanceException({
    required this.accountName,
    required this.currentBalance,
    required this.requestedAmount,
  });

  @override
  String toString() =>
      'Insufficient Balance: $accountName currently has ₹${currentBalance.toStringAsFixed(2)}, but you are trying to spend ₹${requestedAmount.toStringAsFixed(2)}.';
}

class ExpensePaginatedResult {
  final List<ExpenseModel> expenses;
  final DocumentSnapshot? lastDocument;
  final bool hasMore;

  const ExpensePaginatedResult({
    required this.expenses,
    this.lastDocument,
    required this.hasMore,
  });
}

class ProjectExpenseSummaryData {
  final double totalSpent;
  final Map<String, double> personBreakdown;
  final int count;

  const ProjectExpenseSummaryData({
    this.totalSpent = 0.0,
    this.personBreakdown = const {},
    this.count = 0,
  });
}

class ExpenseRepository {
  final FirebaseFirestore _db;
  final String currentUserId;
  final String currentUserName;
  final UserRole currentUserRole;
  final Uuid _uuid = const Uuid();

  ExpenseRepository({
    required FirebaseFirestore db,
    this.currentUserId = '',
    this.currentUserName = 'Admin',
    this.currentUserRole = UserRole.admin,
  }) : _db = db;

  CollectionReference<Map<String, dynamic>> get _expenses =>
      _db.collection(AppCollections.expenses);

  CollectionReference<Map<String, dynamic>> get _transactions =>
      _db.collection(AppCollections.moneyTransactions);

  CollectionReference<Map<String, dynamic>> get _accounts =>
      _db.collection(AppCollections.expenseAccounts);

  CollectionReference<Map<String, dynamic>> get _accountSummaries =>
      _db.collection(AppCollections.expenseAccountSummaries);

  DocumentReference<Map<String, dynamic>> get _dashboardSummary =>
      _db.collection(AppCollections.expenseDashboardSummaries).doc('global');

  CollectionReference<Map<String, dynamic>> _activities(String expenseId) =>
      _expenses.doc(expenseId).collection(AppCollections.expenseActivities);

  // ─── INITIALIZATION / SEEDING ──────────────────────────────────────────────

  /// Automatically seeds initial accounts (Mugesh, Deepika) if not present
  Future<void> initializeDefaultAccounts() async {
    try {
      final snapshot = await _accounts.limit(1).get();
      if (snapshot.docs.isEmpty) {
        final now = DateTime.now();
        final defaults = ['Mugesh', 'Deepika'];

        final batch = _db.batch();
        for (final name in defaults) {
          final docRef = _accounts.doc();
          batch.set(docRef, {
            'id': docRef.id,
            'name': name,
            'isActive': true,
            'createdAt': Timestamp.fromDate(now),
            'updatedAt': Timestamp.fromDate(now),
          });

          final summaryRef = _accountSummaries.doc(docRef.id);
          batch.set(summaryRef, {
            'accountId': docRef.id,
            'accountName': name,
            'totalCredits': 0.0,
            'totalDebits': 0.0,
            'currentBalance': 0.0,
            'updatedAt': Timestamp.fromDate(now),
          });
        }

        // Initialize global summary if missing
        final globalDoc = await _dashboardSummary.get();
        if (!globalDoc.exists) {
          batch.set(_dashboardSummary, {
            'totalMoney': 0.0,
            'totalSpent': 0.0,
            'availableBalance': 0.0,
            'thisMonthSpent': 0.0,
            'updatedAt': Timestamp.fromDate(now),
          });
        }

        await batch.commit();
      }
    } catch (_) {
      // Ignore if cannot seed or permissions fail
    }
  }

  // ─── ATOMIC EXPENSE CREATION ───────────────────────────────────────────────

  Future<String> createExpense({
    required String paymentName,
    required double amount,
    String? projectId,
    String? projectName,
    String? projectNumber,
    required String paidFromAccountId,
    required String paidFromAccountName,
    required String usedByAccountId,
    required String usedByAccountName,
    required ExpenseCategory category,
    required ExpensePaymentMethod paymentMethod,
    required DateTime expenseDate,
    String description = '',
    bool adminOverride = false,
  }) async {
    if (amount <= 0) {
      throw ArgumentError('Expense amount must be greater than 0');
    }

    final expenseId = _expenses.doc().id;
    final transactionId = _transactions.doc().id;
    final activityId = _uuid.v4();
    final now = DateTime.now();

    await _db.runTransaction((tx) async {
      // 1. Read account summary to check balance
      final accountSummaryRef = _accountSummaries.doc(paidFromAccountId);
      final accountSummaryDoc = await tx.get(accountSummaryRef);

      double currentBalance = 0.0;
      double totalDebits = 0.0;
      double totalCredits = 0.0;

      if (accountSummaryDoc.exists) {
        final data = accountSummaryDoc.data()!;
        totalCredits = (data['totalCredits'] as num?)?.toDouble() ?? 0.0;
        totalDebits = (data['totalDebits'] as num?)?.toDouble() ?? 0.0;
        currentBalance = (data['currentBalance'] as num?)?.toDouble() ?? (totalCredits - totalDebits);
      }

      // Check balance
      if (amount > currentBalance && !adminOverride) {
        throw InsufficientBalanceException(
          accountName: paidFromAccountName,
          currentBalance: currentBalance,
          requestedAmount: amount,
        );
      }

      final newBalance = currentBalance - amount;

      // 2. Read global summary
      final globalDoc = await tx.get(_dashboardSummary);
      double globalMoney = 0.0;
      double globalSpent = 0.0;
      double globalAvailable = 0.0;
      double thisMonthSpent = 0.0;

      if (globalDoc.exists) {
        final gData = globalDoc.data()!;
        globalMoney = (gData['totalMoney'] as num?)?.toDouble() ?? 0.0;
        globalSpent = (gData['totalSpent'] as num?)?.toDouble() ?? 0.0;
        globalAvailable = (gData['availableBalance'] as num?)?.toDouble() ?? 0.0;
        thisMonthSpent = (gData['thisMonthSpent'] as num?)?.toDouble() ?? 0.0;
      }

      final isCurrentMonth =
          expenseDate.year == now.year && expenseDate.month == now.month;

      // 3. Create expense document
      final searchTokens = ExpenseModel.generateSearchTokens(
        paymentName: paymentName,
        projectName: projectName,
        projectNumber: projectNumber,
        paidFrom: paidFromAccountName,
        usedBy: usedByAccountName,
        description: description,
        category: category.displayName,
      );

      final expenseRef = _expenses.doc(expenseId);
      tx.set(expenseRef, {
        'id': expenseId,
        'paymentName': paymentName,
        'amount': amount,
        'currency': 'INR',
        if (projectId != null && projectId.isNotEmpty) 'projectId': projectId,
        if (projectName != null && projectName.isNotEmpty)
          'projectName': projectName,
        if (projectNumber != null && projectNumber.isNotEmpty)
          'projectNumber': projectNumber,
        'paidFromAccountId': paidFromAccountId,
        'paidFromAccountName': paidFromAccountName,
        'usedByAccountId': usedByAccountId,
        'usedByAccountName': usedByAccountName,
        'category': category.displayName,
        'paymentMethod': paymentMethod.displayName,
        'expenseDate': Timestamp.fromDate(expenseDate),
        'description': description,
        'balanceAfterTransaction': newBalance,
        'createdBy': currentUserId,
        'createdByName': currentUserName,
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
        'isVoided': false,
        'searchTokens': searchTokens,
      });

      // 4. Create debit transaction record
      final txRef = _transactions.doc(transactionId);
      tx.set(txRef, {
        'id': transactionId,
        'accountId': paidFromAccountId,
        'accountName': paidFromAccountName,
        'type': 'debit',
        'amount': amount,
        'expenseId': expenseId,
        if (projectId != null && projectId.isNotEmpty) 'projectId': projectId,
        if (projectName != null && projectName.isNotEmpty)
          'projectName': projectName,
        'title': paymentName,
        'description': description.isNotEmpty
            ? description
            : 'Expense paid for ${projectName ?? category.displayName} ($paymentName)',
        'category': category.displayName,
        'paymentMethod': paymentMethod.displayName,
        'transactionDate': Timestamp.fromDate(expenseDate),
        'runningBalance': newBalance,
        'createdBy': currentUserId,
        'createdByName': currentUserName,
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
        'isVoided': false,
      });

      // 5. Update account summary
      tx.set(
        accountSummaryRef,
        {
          'accountId': paidFromAccountId,
          'accountName': paidFromAccountName,
          'totalCredits': totalCredits,
          'totalDebits': totalDebits + amount,
          'currentBalance': newBalance,
          'updatedAt': Timestamp.fromDate(now),
        },
        SetOptions(merge: true),
      );

      // 6. Update global dashboard summary
      tx.set(
        _dashboardSummary,
        {
          'totalMoney': globalMoney,
          'totalSpent': globalSpent + amount,
          'availableBalance': globalAvailable - amount,
          'thisMonthSpent':
              isCurrentMonth ? (thisMonthSpent + amount) : thisMonthSpent,
          'updatedAt': Timestamp.fromDate(now),
        },
        SetOptions(merge: true),
      );

      // 7. Write audit activity
      final activityRef = _activities(expenseId).doc(activityId);
      tx.set(activityRef, {
        'id': activityId,
        'expenseId': expenseId,
        'type': ExpenseActivityType.created.name,
        'description':
            'Expense created for ₹${amount.toStringAsFixed(2)} ($paymentName). Paid by $paidFromAccountName, used by $usedByAccountName.',
        'createdBy': currentUserId,
        'createdByName': currentUserName,
        'createdAt': Timestamp.fromDate(now),
      });
    });

    return expenseId;
  }

  // ─── ATOMIC ADD MONEY / FUND ENTRY ─────────────────────────────────────────

  Future<String> addMoney({
    required String accountId,
    required String accountName,
    required double amount,
    required String sourceOrReason,
    String? projectId,
    String? projectName,
    required DateTime transactionDate,
    String note = '',
    String? paymentMethod,
  }) async {
    if (amount <= 0) {
      throw ArgumentError('Amount added must be greater than 0');
    }

    final transactionId = _transactions.doc().id;
    final now = DateTime.now();

    await _db.runTransaction((tx) async {
      // 1. Read account summary
      final accountSummaryRef = _accountSummaries.doc(accountId);
      final accountSummaryDoc = await tx.get(accountSummaryRef);

      double currentBalance = 0.0;
      double totalDebits = 0.0;
      double totalCredits = 0.0;

      if (accountSummaryDoc.exists) {
        final data = accountSummaryDoc.data()!;
        totalCredits = (data['totalCredits'] as num?)?.toDouble() ?? 0.0;
        totalDebits = (data['totalDebits'] as num?)?.toDouble() ?? 0.0;
        currentBalance = (data['currentBalance'] as num?)?.toDouble() ?? (totalCredits - totalDebits);
      }

      final newBalance = currentBalance + amount;

      // 2. Read global summary
      final globalDoc = await tx.get(_dashboardSummary);
      double globalMoney = 0.0;
      double globalSpent = 0.0;
      double globalAvailable = 0.0;

      if (globalDoc.exists) {
        final gData = globalDoc.data()!;
        globalMoney = (gData['totalMoney'] as num?)?.toDouble() ?? 0.0;
        globalSpent = (gData['totalSpent'] as num?)?.toDouble() ?? 0.0;
        globalAvailable = (gData['availableBalance'] as num?)?.toDouble() ?? 0.0;
      }

      // 3. Create credit transaction record
      final txRef = _transactions.doc(transactionId);
      tx.set(txRef, {
        'id': transactionId,
        'accountId': accountId,
        'accountName': accountName,
        'type': 'credit',
        'amount': amount,
        if (projectId != null && projectId.isNotEmpty) 'projectId': projectId,
        if (projectName != null && projectName.isNotEmpty)
          'projectName': projectName,
        'title': sourceOrReason,
        'description': note.isNotEmpty ? note : 'Funds added to $accountName account ($sourceOrReason)',
        if (paymentMethod != null) 'paymentMethod': paymentMethod,
        'transactionDate': Timestamp.fromDate(transactionDate),
        'runningBalance': newBalance,
        'createdBy': currentUserId,
        'createdByName': currentUserName,
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
        'isVoided': false,
      });

      // 4. Update account summary
      tx.set(
        accountSummaryRef,
        {
          'accountId': accountId,
          'accountName': accountName,
          'totalCredits': totalCredits + amount,
          'totalDebits': totalDebits,
          'currentBalance': newBalance,
          'updatedAt': Timestamp.fromDate(now),
        },
        SetOptions(merge: true),
      );

      // 5. Update global summary
      tx.set(
        _dashboardSummary,
        {
          'totalMoney': globalMoney + amount,
          'totalSpent': globalSpent,
          'availableBalance': globalAvailable + amount,
          'updatedAt': Timestamp.fromDate(now),
        },
        SetOptions(merge: true),
      );
    });

    return transactionId;
  }

  // ─── SAFE EXPENSE VOID / ARCHIVE ───────────────────────────────────────────

  Future<void> voidExpense({
    required String expenseId,
    required String reason,
  }) async {
    final now = DateTime.now();
    final activityId = _uuid.v4();

    await _db.runTransaction((tx) async {
      final expenseRef = _expenses.doc(expenseId);
      final expenseDoc = await tx.get(expenseRef);

      if (!expenseDoc.exists) {
        throw ArgumentError('Expense not found');
      }

      final expenseData = expenseDoc.data()!;
      if (expenseData['isVoided'] == true) {
        return; // Already voided
      }

      final amount = (expenseData['amount'] as num?)?.toDouble() ?? 0.0;
      final paidFromAccountId = expenseData['paidFromAccountId'] as String? ?? '';
      final paidFromAccountName = expenseData['paidFromAccountName'] as String? ?? '';
      final paymentName = expenseData['paymentName'] as String? ?? '';

      // Read account summary
      final accountSummaryRef = _accountSummaries.doc(paidFromAccountId);
      final accountSummaryDoc = await tx.get(accountSummaryRef);

      if (accountSummaryDoc.exists) {
        final aData = accountSummaryDoc.data()!;
        final currentDebits = (aData['totalDebits'] as num?)?.toDouble() ?? 0.0;
        final currentBalance = (aData['currentBalance'] as num?)?.toDouble() ?? 0.0;
        final restoredBalance = currentBalance + amount;

        tx.update(accountSummaryRef, {
          'totalDebits': (currentDebits - amount).clamp(0.0, double.infinity),
          'currentBalance': restoredBalance,
          'updatedAt': Timestamp.fromDate(now),
        });
      }

      // Read global summary
      final globalDoc = await tx.get(_dashboardSummary);
      if (globalDoc.exists) {
        final gData = globalDoc.data()!;
        final gSpent = (gData['totalSpent'] as num?)?.toDouble() ?? 0.0;
        final gAvail = (gData['availableBalance'] as num?)?.toDouble() ?? 0.0;

        tx.update(_dashboardSummary, {
          'totalSpent': (gSpent - amount).clamp(0.0, double.infinity),
          'availableBalance': gAvail + amount,
          'updatedAt': Timestamp.fromDate(now),
        });
      }

      // Update expense to voided
      tx.update(expenseRef, {
        'isVoided': true,
        'voidReason': reason,
        'voidedAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
      });

      // Mark transaction voided
      final txQuery = await _transactions
          .where('expenseId', isEqualTo: expenseId)
          .limit(1)
          .get();
      for (final doc in txQuery.docs) {
        tx.update(doc.reference, {
          'isVoided': true,
          'description': '${doc.data()['description'] ?? ''} [VOIDED: $reason]',
          'updatedAt': Timestamp.fromDate(now),
        });
      }

      // Log activity
      final activityRef = _activities(expenseId).doc(activityId);
      tx.set(activityRef, {
        'id': activityId,
        'expenseId': expenseId,
        'type': ExpenseActivityType.voided.name,
        'description':
            'Expense "$paymentName" voided by $currentUserName. Reason: $reason. ₹${amount.toStringAsFixed(2)} restored to $paidFromAccountName.',
        'createdBy': currentUserId,
        'createdByName': currentUserName,
        'createdAt': Timestamp.fromDate(now),
      });
    });
  }

  // ─── STREAMS & QUERIES ─────────────────────────────────────────────────────

  Stream<List<ExpenseAccountModel>> streamAccounts() {
    return _accounts
        .orderBy('name')
        .snapshots()
        .map((s) => s.docs.map(ExpenseAccountModel.fromFirestore).toList());
  }

  Stream<List<ExpenseAccountSummaryModel>> streamAccountSummaries() {
    return _accountSummaries
        .snapshots()
        .map((s) => s.docs.map(ExpenseAccountSummaryModel.fromFirestore).toList());
  }

  Stream<ExpenseAccountSummaryModel?> streamAccountSummary(String accountId) {
    return _accountSummaries.doc(accountId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return ExpenseAccountSummaryModel.fromFirestore(doc);
    });
  }

  Stream<ExpenseDashboardSummaryModel?> streamDashboardSummary() {
    return _dashboardSummary.snapshots().map((doc) {
      if (!doc.exists) return null;
      return ExpenseDashboardSummaryModel.fromFirestore(doc);
    });
  }

  Stream<ExpenseModel?> streamExpenseById(String expenseId) {
    return _expenses.doc(expenseId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return ExpenseModel.fromFirestore(doc);
    });
  }

  Stream<List<ExpenseActivityModel>> streamExpenseActivities(String expenseId) {
    return _activities(expenseId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map(ExpenseActivityModel.fromFirestore).toList());
  }

  Stream<List<MoneyTransactionModel>> streamTransactionsForAccount(
    String accountId, {
    int limit = 50,
  }) {
    return _transactions
        .where('accountId', isEqualTo: accountId)
        .orderBy('transactionDate', descending: true)
        .limit(limit)
        .snapshots()
        .map((s) => s.docs.map(MoneyTransactionModel.fromFirestore).toList());
  }

  Stream<List<ExpenseModel>> streamProjectExpenses(String projectId) {
    return _expenses
        .where('projectId', isEqualTo: projectId)
        .where('isVoided', isEqualTo: false)
        .orderBy('expenseDate', descending: true)
        .snapshots()
        .map((s) => s.docs.map(ExpenseModel.fromFirestore).toList());
  }

  Future<ProjectExpenseSummaryData> getProjectExpenseSummary(String projectId) async {
    final snap = await _expenses
        .where('projectId', isEqualTo: projectId)
        .where('isVoided', isEqualTo: false)
        .get();

    double total = 0.0;
    final Map<String, double> breakdown = {};

    for (final doc in snap.docs) {
      final model = ExpenseModel.fromFirestore(doc);
      total += model.amount;
      breakdown[model.paidFromAccountName] =
          (breakdown[model.paidFromAccountName] ?? 0.0) + model.amount;
    }

    return ProjectExpenseSummaryData(
      totalSpent: total,
      personBreakdown: breakdown,
      count: snap.docs.length,
    );
  }

  // ─── PAGINATED EXPENSES WITH SEARCH & FILTER ───────────────────────────────

  Future<ExpensePaginatedResult> getExpensesPaginated({
    ExpenseFilter? filter,
    String? searchQuery,
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) async {
    Query<Map<String, dynamic>> query = _expenses;

    if (filter != null) {
      if (!filter.includeVoided) {
        query = query.where('isVoided', isEqualTo: false);
      }
      if (filter.projectId != null && filter.projectId!.isNotEmpty) {
        query = query.where('projectId', isEqualTo: filter.projectId);
      }
      if (filter.paidFromAccountId != null &&
          filter.paidFromAccountId!.isNotEmpty) {
        query = query.where('paidFromAccountId',
            isEqualTo: filter.paidFromAccountId);
      }
      if (filter.usedByAccountId != null &&
          filter.usedByAccountId!.isNotEmpty) {
        query =
            query.where('usedByAccountId', isEqualTo: filter.usedByAccountId);
      }
      if (filter.category != null) {
        query = query.where('category', isEqualTo: filter.category!.displayName);
      }
      if (filter.paymentMethod != null) {
        query = query.where('paymentMethod',
            isEqualTo: filter.paymentMethod!.displayName);
      }
      if (filter.startDate != null) {
        query = query.where('expenseDate',
            isGreaterThanOrEqualTo: Timestamp.fromDate(filter.startDate!));
      }
      if (filter.endDate != null) {
        query = query.where('expenseDate',
            isLessThanOrEqualTo: Timestamp.fromDate(filter.endDate!));
      }
    } else {
      query = query.where('isVoided', isEqualTo: false);
    }

    // Search query using searchTokens if provided
    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final token = searchQuery.trim().toLowerCase();
      query = query.where('searchTokens', arrayContains: token);
    }

    // Default order
    query = query.orderBy('expenseDate', descending: true);

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    query = query.limit(limit + 1);

    final snapshot = await query.get();
    final docs = snapshot.docs;
    final hasMore = docs.length > limit;
    final resultDocs = hasMore ? docs.sublist(0, limit) : docs;

    var expenses = resultDocs.map(ExpenseModel.fromFirestore).toList();

    // In-memory amount filter if applied
    if (filter != null) {
      if (filter.minAmount != null) {
        expenses = expenses.where((e) => e.amount >= filter.minAmount!).toList();
      }
      if (filter.maxAmount != null) {
        expenses = expenses.where((e) => e.amount <= filter.maxAmount!).toList();
      }
    }

    return ExpensePaginatedResult(
      expenses: expenses,
      lastDocument: resultDocs.isNotEmpty ? resultDocs.last : null,
      hasMore: hasMore,
    );
  }
}

final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  final db = FirebaseFirestore.instance;
  final user = ref.watch(currentUserModelProvider).valueOrNull;

  final repo = ExpenseRepository(
    db: db,
    currentUserId: user?.id ?? '',
    currentUserName: user?.displayName ?? 'Admin',
    currentUserRole: user?.role ?? UserRole.admin,
  );

  // Trigger account seed check
  repo.initializeDefaultAccounts();

  return repo;
});
