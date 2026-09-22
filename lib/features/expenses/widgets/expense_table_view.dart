// lib/features/expenses/widgets/expense_table_view.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../models/expense_model.dart';

class ExpenseTableView extends StatelessWidget {
  final List<ExpenseModel> expenses;
  final Function(ExpenseModel) onExpenseTap;
  final Function(ExpenseModel)? onVoidTap;

  const ExpenseTableView({
    super.key,
    required this.expenses,
    required this.onExpenseTap,
    this.onVoidTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inrFormat =
        NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);
    final dateFormat = DateFormat('dd MMM yyyy');

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.border,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 1000),
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(
                isDark ? AppColors.cardSurfaceDark : AppColors.cardSurface,
              ),
              horizontalMargin: AppSpacing.lg,
              columnSpacing: AppSpacing.lg,
              columns: const [
                DataColumn(label: Text('Date', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Payment', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Project', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Paid From', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Used By', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Category', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(
                  label: Text('Amount', style: TextStyle(fontWeight: FontWeight.bold)),
                  numeric: true,
                ),
                DataColumn(label: Text('Payment Method', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
              ],
              rows: expenses.map((expense) {
                final isVoided = expense.isVoided;

                return DataRow(
                  onSelectChanged: (_) => onExpenseTap(expense),
                  cells: [
                    // 1. Date
                    DataCell(
                      Text(
                        dateFormat.format(expense.expenseDate),
                        style: AppTypography.bodySmall.copyWith(
                          color: isDark
                              ? AppColors.onSurfaceVariantDark
                              : AppColors.onSurfaceVariant,
                        ),
                      ),
                    ),

                    // 2. Payment Name
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            expense.paymentName,
                            style: AppTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.w700,
                              decoration: isVoided
                                  ? TextDecoration.lineThrough
                                  : TextDecoration.none,
                              color: isVoided
                                  ? AppColors.error
                                  : (isDark
                                      ? AppColors.onSurfaceDark
                                      : AppColors.onSurface),
                            ),
                          ),
                          if (isVoided) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: AppColors.error.withValues(alpha: 0.12),
                                borderRadius:
                                    BorderRadius.circular(AppRadius.xs),
                              ),
                              child: Text(
                                'VOID',
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.error,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // 3. Project
                    DataCell(
                      expense.hasProject
                          ? InkWell(
                              onTap: () {
                                context.push('${AppRoutes.projects}/${expense.projectId}');
                              },
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.folder_outlined,
                                      size: 14, color: AppColors.primary),
                                  const SizedBox(width: 4),
                                  Text(
                                    expense.projectName ?? '',
                                    style: AppTypography.bodySmall.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            )
                          : Text(
                              '—',
                              style: AppTypography.bodySmall.copyWith(
                                color: isDark
                                    ? AppColors.onSurfaceVariantDark
                                    : AppColors.onSurfaceVariant,
                              ),
                            ),
                    ),

                    // 4. Paid From
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircleAvatar(
                            radius: 10,
                            backgroundColor:
                                const Color(0xFF0284C7).withValues(alpha: 0.15),
                            child: Text(
                              expense.paidFromAccountName.isNotEmpty
                                  ? expense.paidFromAccountName[0].toUpperCase()
                                  : 'P',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0284C7),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            expense.paidFromAccountName,
                            style: AppTypography.bodySmall.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 5. Used By
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircleAvatar(
                            radius: 10,
                            backgroundColor:
                                const Color(0xFF10B981).withValues(alpha: 0.15),
                            child: Text(
                              expense.usedByAccountName.isNotEmpty
                                  ? expense.usedByAccountName[0].toUpperCase()
                                  : 'U',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF10B981),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            expense.usedByAccountName,
                            style: AppTypography.bodySmall.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 6. Category
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: Text(
                          expense.category.displayName,
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    // 7. Amount
                    DataCell(
                      Text(
                        inrFormat.format(expense.amount),
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w800,
                          color: isVoided
                              ? AppColors.error
                              : (isDark
                                  ? AppColors.onSurfaceDark
                                  : AppColors.onSurface),
                          decoration: isVoided
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                        ),
                      ),
                    ),

                    // 8. Payment Method
                    DataCell(
                      Text(
                        expense.paymentMethod.displayName,
                        style: AppTypography.bodySmall.copyWith(
                          color: isDark
                              ? AppColors.onSurfaceVariantDark
                              : AppColors.onSurfaceVariant,
                        ),
                      ),
                    ),

                    // 9. Actions
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.visibility_outlined, size: 18),
                            tooltip: 'View Details',
                            onPressed: () => onExpenseTap(expense),
                          ),
                          if (!isVoided && onVoidTap != null)
                            IconButton(
                              icon: const Icon(Icons.block_rounded,
                                  size: 18, color: AppColors.error),
                              tooltip: 'Void Expense',
                              onPressed: () => onVoidTap!(expense),
                            ),
                        ],
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}
