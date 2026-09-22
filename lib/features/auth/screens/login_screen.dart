// lib/features/auth/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/error_handler.dart';
import '../../../core/widgets/app_logo.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/primary_button.dart';
import '../repositories/auth_repository.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ref.read(authRepositoryProvider).signIn(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
      if (mounted) {
        context.go(AppRoutes.dashboard);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = ErrorHandler.getMessage(e);
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width >= 960;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: isDesktop ? _buildDesktopLayout() : _buildMobileLayout(),
    );
  }

  // === Desktop Split Layout ===
  Widget _buildDesktopLayout() {
    return Row(
      children: [
        // Left Branding Panel
        Expanded(
          flex: 5,
          child: Container(
            color: AppColors.sidebarBg,
            padding: const EdgeInsets.symmetric(horizontal: 64, vertical: 48),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top Brand
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const AppLogo.horizontal(height: 38, transparent: true),
                    AppSpacing.gapW12,
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        'CRM',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.primaryLight,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ],
                ),

                // Center Value Statement & Preview Element
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: AppRadius.badge,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.primaryLight,
                              shape: BoxShape.circle,
                            ),
                          ),
                          AppSpacing.gapW8,
                          Text(
                            'Internal Admin Portal',
                            style: AppTypography.labelSmall.copyWith(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    AppSpacing.gapH24,
                    Text(
                      'Unified Lead & Sales Pipeline Management',
                      style: AppTypography.displayLarge.copyWith(
                        color: Colors.white,
                        fontSize: 36,
                        height: 1.25,
                      ),
                    ),
                    AppSpacing.gapH16,
                    Text(
                      'Manage leads, track customer follow-ups, deliver quotations, and monitor revenue operations in one secure admin workspace.',
                      style: AppTypography.bodyLarge.copyWith(color: AppColors.sidebarItemText),
                    ),
                    AppSpacing.gapH32,

                    // Minimal visual card element
                    Container(
                      padding: AppSpacing.p20,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: AppRadius.card,
                        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.security_rounded, color: AppColors.primaryLight, size: 22),
                          ),
                          AppSpacing.gapW16,
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Restricted Access',
                                  style: AppTypography.titleMedium.copyWith(color: Colors.white),
                                ),
                                Text(
                                  'Only authenticated administrators with verified roles can sign in.',
                                  style: AppTypography.bodySmall.copyWith(color: AppColors.sidebarItemText),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Bottom Footer
                Text(
                  '© 2026 Hytide Technologies. All rights reserved.',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.sidebarItemText.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Right Login Form Panel
        Expanded(
          flex: 6,
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(48),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: _buildLoginForm(isDesktop: true),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // === Mobile Layout ===
  Widget _buildMobileLayout() {
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Mobile Header
                const AppLogo.horizontal(height: 48, transparent: true),
                AppSpacing.gapH8,
                Text(
                  AppAssets.brandTagline,
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textMuted,
                    letterSpacing: 0.3,
                  ),
                ),
                AppSpacing.gapH4,
                Text(
                  'Admin Portal Sign In',
                  style: AppTypography.bodyMedium.copyWith(color: AppColors.onSurfaceVariant),
                ),
                AppSpacing.gapH32,

                // Form card
                Container(
                  padding: AppSpacing.p24,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: AppRadius.card,
                    border: Border.all(color: AppColors.surfaceBorder),
                    boxShadow: AppShadows.card,
                  ),
                  child: _buildLoginForm(isDesktop: false),
                ),

                AppSpacing.gapH32,
                Text(
                  '© 2026 Hytide Technologies',
                  style: AppTypography.labelSmall.copyWith(color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // === Login Form Widget ===
  Widget _buildLoginForm({required bool isDesktop}) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isDesktop) ...[
            Text(
              'Sign In',
              style: AppTypography.headlineLarge,
            ),
            AppSpacing.gapH8,
            Text(
              'Enter your administrator credentials to access your dashboard.',
              style: AppTypography.bodyMedium.copyWith(color: AppColors.onSurfaceVariant),
            ),
            AppSpacing.gapH24,
          ],

          // Error Banner
          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.errorContainer,
                borderRadius: AppRadius.button,
                border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 20),
                  AppSpacing.gapW12,
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.error,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            AppSpacing.gapH16,
          ],

          // Email Field
          AppTextField(
            controller: _emailController,
            label: 'Email address',
            hint: 'admin@hytide.com',
            keyboardType: TextInputType.emailAddress,
            prefixIcon: const Icon(Icons.mail_outline_rounded, size: 20, color: AppColors.onSurfaceVariant),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Email is required';
              if (!v.contains('@') || !v.contains('.')) return 'Enter a valid email';
              return null;
            },
            textInputAction: TextInputAction.next,
          ),

          AppSpacing.gapH20,

          // Password Field
          AppTextField(
            controller: _passwordController,
            label: 'Password',
            hint: '••••••••',
            obscureText: _obscurePassword,
            prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20, color: AppColors.onSurfaceVariant),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                size: 20,
                color: AppColors.onSurfaceVariant,
              ),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Password is required';
              if (v.length < 6) return 'Password must be at least 6 characters';
              return null;
            },
            onFieldSubmitted: (_) => _handleLogin(),
            textInputAction: TextInputAction.done,
          ),

          AppSpacing.gapH24,

          // Sign In Action
          PrimaryButton(
            label: 'Sign In to Admin Portal',
            isFullWidth: true,
            isLoading: _isLoading,
            onPressed: _handleLogin,
          ),
        ],
      ),
    );
  }
}
