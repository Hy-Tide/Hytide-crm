// test/features/expenses/expense_model_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:hytide/core/constants/app_constants.dart';
import 'package:hytide/features/expenses/models/expense_account_model.dart';
import 'package:hytide/features/expenses/models/expense_account_summary_model.dart';
import 'package:hytide/features/expenses/models/expense_dashboard_summary_model.dart';
import 'package:hytide/features/expenses/models/expense_model.dart';
import 'package:hytide/features/expenses/models/money_transaction_model.dart';
import 'package:hytide/features/expenses/repositories/expense_repository.dart';

void main() {
  group('Expense & Money Tracking Module Unit Tests', () {
    test('ExpenseModel preserves fields, generates search tokens and toMap', () {
      final now = DateTime(2026, 9, 14, 10, 30);
      final expense = ExpenseModel(
        id: 'exp_001',
        paymentName: 'AWS Hosting',
        amount: 1500.00,
        currency: 'INR',
        projectId: 'prj_100',
        projectName: 'Hytide E-commerce App',
        projectNumber: 'PRJ-2026-0008',
        paidFromAccountId: 'acc_mugesh',
        paidFromAccountName: 'Mugesh',
        usedByAccountId: 'acc_deepika',
        usedByAccountName: 'Deepika',
        category: ExpenseCategory.hosting,
        paymentMethod: ExpensePaymentMethod.upi,
        expenseDate: now,
        description: 'Monthly AWS hosting payment',
        balanceAfterTransaction: 37500.00,
        createdBy: 'user_1',
        createdByName: 'Admin',
        createdAt: now,
        updatedAt: now,
      );

      expect(expense.paymentName, equals('AWS Hosting'));
      expect(expense.amount, equals(1500.00));
      expect(expense.paidFromAccountName, equals('Mugesh'));
      expect(expense.usedByAccountName, equals('Deepika'));
      expect(expense.balanceAfterTransaction, equals(37500.00));
      expect(expense.hasProject, isTrue);

      final map = expense.toMap();
      expect(map['paymentName'], equals('AWS Hosting'));
      expect(map['amount'], equals(1500.00));
      expect(map['category'], equals('Hosting'));
      expect(map['paymentMethod'], equals('UPI'));
      expect(map['balanceAfterTransaction'], equals(37500.00));
      expect(map['isVoided'], isFalse);

      final tokens = ExpenseModel.generateSearchTokens(
        paymentName: 'AWS Hosting',
        projectName: 'Hytide E-commerce App',
        paidFrom: 'Mugesh',
        usedBy: 'Deepika',
      );
      expect(tokens, contains('aws'));
      expect(tokens, contains('hosting'));
      expect(tokens, contains('mugesh'));
      expect(tokens, contains('deepika'));
    });

    test('MoneyTransactionModel correctly identifies credit vs debit', () {
      final now = DateTime(2026, 9, 14, 11, 0);

      final creditTx = MoneyTransactionModel(
        id: 'tx_c1',
        accountId: 'acc_mugesh',
        accountName: 'Mugesh',
        type: MoneyTransactionType.credit,
        amount: 50000.00,
        title: 'Project Payment Received',
        transactionDate: now,
        runningBalance: 50000.00,
        createdBy: 'user_1',
        createdAt: now,
        updatedAt: now,
      );

      expect(creditTx.isCredit, isTrue);
      expect(creditTx.isDebit, isFalse);
      expect(creditTx.runningBalance, equals(50000.00));

      final debitTx = MoneyTransactionModel(
        id: 'tx_d1',
        accountId: 'acc_mugesh',
        accountName: 'Mugesh',
        type: MoneyTransactionType.debit,
        amount: 12500.00,
        title: 'AWS Hosting',
        transactionDate: now,
        runningBalance: 37500.00,
        createdBy: 'user_1',
        createdAt: now,
        updatedAt: now,
      );

      expect(debitTx.isCredit, isFalse);
      expect(debitTx.isDebit, isTrue);
      expect(debitTx.runningBalance, equals(37500.00));
    });

    test('ExpenseAccountSummaryModel accurately tracks balance', () {
      final now = DateTime(2026, 9, 14);
      final summary = ExpenseAccountSummaryModel(
        accountId: 'acc_mugesh',
        accountName: 'Mugesh',
        totalCredits: 50000.00,
        totalDebits: 12500.00,
        currentBalance: 37500.00,
        updatedAt: now,
      );

      expect(summary.currentBalance, equals(37500.00));
      expect(summary.totalCredits - summary.totalDebits, equals(37500.00));

      final updated = summary.copyWith(
        totalDebits: summary.totalDebits + 1500.00,
        currentBalance: summary.currentBalance - 1500.00,
      );
      expect(updated.totalDebits, equals(14000.00));
      expect(updated.currentBalance, equals(36000.00));
    });

    test('ExpenseDashboardSummaryModel computes available working capital', () {
      final now = DateTime(2026, 9, 14);
      final dashboard = ExpenseDashboardSummaryModel(
        totalMoney: 80000.00,
        totalSpent: 20500.00,
        availableBalance: 59500.00,
        thisMonthSpent: 12500.00,
        updatedAt: now,
      );

      expect(dashboard.totalMoney, equals(80000.00));
      expect(dashboard.totalSpent, equals(20500.00));
      expect(dashboard.availableBalance, equals(59500.00));
      expect(dashboard.thisMonthSpent, equals(12500.00));
      expect(dashboard.totalMoney - dashboard.totalSpent, equals(59500.00));
    });

    test('InsufficientBalanceException formats message clearly', () {
      const ex = InsufficientBalanceException(
        accountName: 'Mugesh',
        currentBalance: 2000.00,
        requestedAmount: 3500.00,
      );

      final msg = ex.toString();
      expect(msg, contains('Mugesh'));
      expect(msg, contains('2000.00'));
      expect(msg, contains('3500.00'));
    });

    test('ExpenseCategory and ExpensePaymentMethod enum parsing', () {
      expect(ExpenseCategory.fromString('Hosting'), equals(ExpenseCategory.hosting));
      expect(ExpenseCategory.fromString('Travel'), equals(ExpenseCategory.travel));
      expect(ExpenseCategory.fromString('Unknown'), equals(ExpenseCategory.other));

      expect(ExpensePaymentMethod.fromString('UPI'), equals(ExpensePaymentMethod.upi));
      expect(ExpensePaymentMethod.fromString('Bank Transfer'), equals(ExpensePaymentMethod.bankTransfer));
      expect(ExpensePaymentMethod.fromString('Cash'), equals(ExpensePaymentMethod.cash));
    });

    test('ExpenseAccountModel instantiation and copyWith', () {
      final now = DateTime(2026, 9, 14);
      final account = ExpenseAccountModel(
        id: 'acc_deepika',
        name: 'Deepika',
        isActive: true,
        createdAt: now,
        updatedAt: now,
      );

      expect(account.id, equals('acc_deepika'));
      expect(account.name, equals('Deepika'));
      expect(account.isActive, isTrue);

      final updated = account.copyWith(name: 'Deepika S');
      expect(updated.name, equals('Deepika S'));
    });
  });
}
