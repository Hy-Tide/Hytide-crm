// lib/features/expenses/providers/expense_providers.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/expense_account_model.dart';
import '../models/expense_account_summary_model.dart';
import '../models/expense_activity_model.dart';
import '../models/expense_dashboard_summary_model.dart';
import '../models/expense_filter_model.dart';
import '../models/expense_model.dart';
import '../models/money_transaction_model.dart';
import '../repositories/expense_repository.dart';

export '../repositories/expense_repository.dart' show expenseRepositoryProvider;

final expenseFilterProvider = StateProvider<ExpenseFilter>((ref) {
  return const ExpenseFilter();
});

final expenseSearchQueryProvider = StateProvider<String>((ref) => '');

final expenseRefreshTriggerProvider = StateProvider<int>((ref) => 0);

final expenseAccountsProvider =
    StreamProvider<List<ExpenseAccountModel>>((ref) {
  final repo = ref.watch(expenseRepositoryProvider);
  return repo.streamAccounts();
});

final expenseAccountSummariesProvider =
    StreamProvider<List<ExpenseAccountSummaryModel>>((ref) {
  final repo = ref.watch(expenseRepositoryProvider);
  return repo.streamAccountSummaries();
});

final expenseAccountSummaryFamily =
    StreamProvider.family<ExpenseAccountSummaryModel?, String>((ref, accountId) {
  final repo = ref.watch(expenseRepositoryProvider);
  return repo.streamAccountSummary(accountId);
});

final expenseDashboardSummaryProvider =
    StreamProvider<ExpenseDashboardSummaryModel?>((ref) {
  final repo = ref.watch(expenseRepositoryProvider);
  return repo.streamDashboardSummary();
});

final expenseDetailStreamProvider =
    StreamProvider.family<ExpenseModel?, String>((ref, expenseId) {
  final repo = ref.watch(expenseRepositoryProvider);
  return repo.streamExpenseById(expenseId);
});

final expenseActivitiesStreamProvider =
    StreamProvider.family<List<ExpenseActivityModel>, String>((ref, expenseId) {
  final repo = ref.watch(expenseRepositoryProvider);
  return repo.streamExpenseActivities(expenseId);
});

final accountTransactionsProvider =
    StreamProvider.family<List<MoneyTransactionModel>, String>(
        (ref, accountId) {
  final repo = ref.watch(expenseRepositoryProvider);
  return repo.streamTransactionsForAccount(accountId);
});

final projectExpensesStreamProvider =
    StreamProvider.family<List<ExpenseModel>, String>((ref, projectId) {
  final repo = ref.watch(expenseRepositoryProvider);
  return repo.streamProjectExpenses(projectId);
});

final projectExpenseSummaryProvider =
    FutureProvider.family<ProjectExpenseSummaryData, String>((ref, projectId) {
  final repo = ref.watch(expenseRepositoryProvider);
  return repo.getProjectExpenseSummary(projectId);
});

final paginatedExpensesProvider = FutureProvider.family<ExpensePaginatedResult,
    DocumentSnapshot?>((ref, startAfter) async {
  final repo = ref.watch(expenseRepositoryProvider);
  final filter = ref.watch(expenseFilterProvider);
  final searchQuery = ref.watch(expenseSearchQueryProvider);
  ref.watch(expenseRefreshTriggerProvider);

  return await repo.getExpensesPaginated(
    filter: filter,
    searchQuery: searchQuery,
    limit: 20,
    startAfter: startAfter,
  );
});
