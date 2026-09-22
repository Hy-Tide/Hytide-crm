// lib/core/routing/app_router.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/repositories/auth_repository.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/leads/screens/lead_detail_screen.dart';
import '../../features/leads/screens/lead_form_screen.dart';
import '../../features/leads/screens/leads_screen.dart';
import '../../features/followups/screens/followups_screen.dart';
import '../../features/followups/screens/followup_form_screen.dart';
import '../../features/followups/screens/followup_detail_screen.dart';
import '../../features/notifications/screens/notification_center_screen.dart';
import '../../features/clients/screens/clients_screen.dart';
import '../../features/clients/screens/client_form_screen.dart';
import '../../features/clients/screens/client_detail_screen.dart';
import '../../features/quotations/screens/quotations_screen.dart';
import '../../features/quotations/screens/quotation_form_screen.dart';
import '../../features/quotations/screens/quotation_detail_screen.dart';
import '../../features/projects/screens/projects_screen.dart';
import '../../features/projects/screens/project_form_screen.dart';
import '../../features/projects/screens/project_detail_screen.dart';
import '../../features/documents/screens/documents_screen.dart';
import '../../features/reports/screens/reports_screen.dart';
import '../../features/users/screens/users_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/expenses/screens/expenses_screen.dart';
import '../../features/expenses/screens/expense_form_screen.dart';
import '../../features/expenses/screens/expense_detail_screen.dart';
import '../../features/expenses/screens/expense_account_detail_screen.dart';
import '../platform/widgets/android_more_screen.dart';
import '../constants/app_assets.dart';
import '../constants/app_constants.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../widgets/app_logo.dart';
import '../widgets/app_scaffold.dart';

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF001029),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppLogo.horizontal(height: 52, transparent: true),
            AppSpacing.gapH16,
            Text(
              AppAssets.brandTagline,
              style: AppTypography.labelMedium.copyWith(
                color: const Color(0xFF94A3B8),
                letterSpacing: 1.0,
              ),
            ),
            AppSpacing.gapH48,
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryLight),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Page<dynamic> _noTransitionPage(Widget child) {
  return NoTransitionPage(child: child);
}

final routerProvider = Provider<GoRouter>((ref) {
  final authNotifier = ValueNotifier<bool>(false);
  ref.listen(authStateProvider, (previous, next) {
    authNotifier.value = !authNotifier.value;
  });

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: authNotifier,
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      final isLoggedIn = authState.asData?.value != null;
      final isLoading = authState.isLoading;
      final loc = state.uri.path;

      if (isLoading) return AppRoutes.splash;
      if (!isLoggedIn && loc != AppRoutes.login) return AppRoutes.login;
      if (isLoggedIn && (loc == AppRoutes.login || loc == AppRoutes.splash)) {
        return AppRoutes.dashboard;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const _SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),

      // Authenticated Admin Shell Routes
      ShellRoute(
        builder: (context, state, child) {
          return AppScaffold(child: child);
        },
        routes: [
          GoRoute(
            path: AppRoutes.dashboard,
            pageBuilder: (context, state) => _noTransitionPage(const DashboardScreen()),
          ),
          GoRoute(
            path: AppRoutes.leads,
            pageBuilder: (context, state) => _noTransitionPage(const LeadsScreen()),
            routes: [
              GoRoute(
                path: 'create',
                pageBuilder: (context, state) => _noTransitionPage(const LeadFormScreen()),
              ),
              GoRoute(
                path: ':id',
                pageBuilder: (context, state) {
                  final leadId = state.pathParameters['id'] ?? '';
                  return _noTransitionPage(LeadDetailScreen(leadId: leadId));
                },
                routes: [
                  GoRoute(
                    path: 'edit',
                    pageBuilder: (context, state) {
                      final leadId = state.pathParameters['id'] ?? '';
                      return _noTransitionPage(LeadFormScreen(leadId: leadId));
                    },
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.followups,
            pageBuilder: (context, state) => _noTransitionPage(const FollowUpsScreen()),
            routes: [
              GoRoute(
                path: 'create',
                pageBuilder: (context, state) {
                  final leadId = state.uri.queryParameters['leadId'];
                  final companyName = state.uri.queryParameters['companyName'];
                  final date = state.uri.queryParameters['date'];
                  return _noTransitionPage(
                    FollowUpFormScreen(
                      initialLeadId: leadId,
                      initialCompanyName: companyName,
                      initialDate: date,
                    ),
                  );
                },
              ),
              GoRoute(
                path: ':id',
                pageBuilder: (context, state) {
                  final followUpId = state.pathParameters['id'] ?? '';
                  return _noTransitionPage(
                    FollowUpDetailScreen(followUpId: followUpId),
                  );
                },
                routes: [
                  GoRoute(
                    path: 'edit',
                    pageBuilder: (context, state) {
                      final followUpId = state.pathParameters['id'] ?? '';
                      return _noTransitionPage(
                        FollowUpFormScreen(followUpId: followUpId),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.clients,
            pageBuilder: (context, state) => _noTransitionPage(
              const ClientsScreen(),
            ),
            routes: [
              GoRoute(
                path: 'new',
                pageBuilder: (context, state) => _noTransitionPage(
                  const ClientFormScreen(),
                ),
              ),
              GoRoute(
                path: ':id',
                pageBuilder: (context, state) => _noTransitionPage(
                  ClientDetailScreen(
                    clientId: state.pathParameters['id']!,
                  ),
                ),
                routes: [
                  GoRoute(
                    path: 'edit',
                    pageBuilder: (context, state) => _noTransitionPage(
                      ClientFormScreen(
                        clientId: state.pathParameters['id']!,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.projects,
            pageBuilder: (context, state) => _noTransitionPage(
              const ProjectsScreen(),
            ),
            routes: [
              GoRoute(
                path: 'new',
                pageBuilder: (context, state) {
                  final clientId = state.uri.queryParameters['clientId'];
                  return _noTransitionPage(
                    ProjectFormScreen(initialClientId: clientId),
                  );
                },
              ),
              GoRoute(
                path: ':id',
                pageBuilder: (context, state) => _noTransitionPage(
                  ProjectDetailScreen(
                    projectId: state.pathParameters['id']!,
                  ),
                ),
                routes: [
                  GoRoute(
                    path: 'edit',
                    pageBuilder: (context, state) => _noTransitionPage(
                      ProjectFormScreen(
                        projectId: state.pathParameters['id']!,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.quotations,
            pageBuilder: (context, state) => _noTransitionPage(
              const QuotationsScreen(),
            ),
            routes: [
              GoRoute(
                path: 'new',
                pageBuilder: (context, state) {
                  final clientId = state.uri.queryParameters['clientId'];
                  return _noTransitionPage(
                    QuotationFormScreen(
                      initialClientId: clientId,
                    ),
                  );
                },
              ),
              GoRoute(
                path: ':id',
                pageBuilder: (context, state) {
                  final quotationId = state.pathParameters['id'] ?? '';
                  return _noTransitionPage(
                    QuotationDetailScreen(quotationId: quotationId),
                  );
                },
                routes: [
                  GoRoute(
                    path: 'edit',
                    pageBuilder: (context, state) {
                      final quotationId = state.pathParameters['id'] ?? '';
                      return _noTransitionPage(
                        QuotationFormScreen(quotationId: quotationId),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.documents,
            pageBuilder: (context, state) => _noTransitionPage(
              const DocumentsScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.notifications,
            pageBuilder: (context, state) => _noTransitionPage(
              const NotificationCenterScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.reports,
            pageBuilder: (context, state) => _noTransitionPage(
              const ReportsScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.users,
            pageBuilder: (context, state) => _noTransitionPage(
              const UsersScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.settings,
            pageBuilder: (context, state) => _noTransitionPage(
              const SettingsScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.more,
            pageBuilder: (context, state) => _noTransitionPage(
              const AndroidMoreScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.expenses,
            pageBuilder: (context, state) => _noTransitionPage(
              const ExpensesScreen(),
            ),
            routes: [
              GoRoute(
                path: 'create',
                pageBuilder: (context, state) {
                  final projectId = state.uri.queryParameters['projectId'];
                  return _noTransitionPage(
                    ExpenseFormScreen(initialProjectId: projectId),
                  );
                },
              ),
              GoRoute(
                path: 'accounts/:id',
                pageBuilder: (context, state) {
                  final accountId = state.pathParameters['id'] ?? '';
                  return _noTransitionPage(
                    ExpenseAccountDetailScreen(accountId: accountId),
                  );
                },
              ),
              GoRoute(
                path: ':id',
                pageBuilder: (context, state) {
                  final expenseId = state.pathParameters['id'] ?? '';
                  return _noTransitionPage(
                    ExpenseDetailScreen(expenseId: expenseId),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
