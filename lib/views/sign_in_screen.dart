import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/prefs_service.dart';
import '../utils/app_colors.dart';
import '../utils/app_typography.dart';
import '../utils/navigation.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../widgets/pizza_clipper.dart';
import '../widgets/mario_text_field.dart';
import '../widgets/mario_button.dart';
import '../utils/app_snackbar.dart';

/// Sign In screen.
/// Requirement: Login.
class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final prefs = context.read<PrefsService>();
      final remembered = prefs.getRememberedEmail();
      if (remembered != null && remembered.isNotEmpty) {
        _emailController.text = remembered;
        context.read<AuthViewModel>().onSignInEmailChanged(remembered);
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _fillDemo(AuthViewModel authVM) {
    _emailController.text = 'mario@pizza.com';
    _passwordController.text = 'pizza123';
    authVM.onSignInEmailChanged('mario@pizza.com');
    authVM.onSignInPasswordChanged('pizza123');
  }

  void _fillUserM(AuthViewModel authVM) {
    _emailController.text = 'm@gmail.com';
    _passwordController.text = '123456';
    authVM.onSignInEmailChanged('m@gmail.com');
    authVM.onSignInPasswordChanged('123456');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bg,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Clipped Header (Clipper requirement)
            ClippedHeader(
              height: 200,
              child: SafeArea(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('🍕', style: TextStyle(fontSize: 44)),
                      const SizedBox(height: 6),
                      Text(
                        'Welcome Back',
                        style: AppTypography.headlineLarge.copyWith(color: AppColors.white, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Form
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Consumer<AuthViewModel>(
                builder: (context, authVM, _) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Sign In', style: AppTypography.displaySmall.copyWith(color: context.text)),
                      const SizedBox(height: 6),
                      Text(
                        'Enter your credentials to continue',
                        style: AppTypography.bodyMedium.copyWith(color: context.textSecondary),
                      ),
                      const SizedBox(height: 24),

                      MarioTextField(
                        controller: _emailController,
                        hint: 'Email address',
                        keyboardType: TextInputType.emailAddress,
                        prefixIcon: const Icon(Icons.email_outlined),
                        onChanged: authVM.onSignInEmailChanged,
                      ),
                      const SizedBox(height: 14),

                      MarioTextField(
                        controller: _passwordController,
                        hint: 'Password',
                        obscureText: true,
                        prefixIcon: const Icon(Icons.lock_outlined),
                        onChanged: authVM.onSignInPasswordChanged,
                      ),

                      if (authVM.signInError != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline, color: AppColors.primary, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  authVM.signInError!,
                                  style: AppTypography.bodySmall.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 24),

                      MarioButton(
                        label: 'Sign In',
                        isLoading: authVM.signInStatus == AuthFormStatus.loading,
                        onPressed: authVM.isSignInValid
                            ? () async {
                                await authVM.signIn();
                                if (context.mounted && authVM.isAuthenticated) {
                                  showMarioSnackBar(context, 'Welcome back, ${authVM.displayName}! 🍕');
                                  Navigation.goToHome(context);
                                }
                              }
                            : null,
                      ),

                      const SizedBox(height: 12),

                      // Quick Demo / Test Fill Buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.person_rounded, color: AppColors.primary, size: 16),
                              label: const Text('m@gmail.com', overflow: TextOverflow.ellipsis),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: context.text,
                                side: BorderSide(color: context.border),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              onPressed: () => _fillUserM(authVM),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.flash_on_rounded, color: AppColors.goldenCheese, size: 16),
                              label: const Text('mario@pizza.com', overflow: TextOverflow.ellipsis),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: context.text,
                                side: BorderSide(color: context.border),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              onPressed: () => _fillDemo(authVM),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      Center(
                        child: TextButton(
                          onPressed: () => Navigation.goToSignUp(context),
                          child: RichText(
                            text: TextSpan(
                              text: 'Don\'t have an account? ',
                              style: AppTypography.bodyMedium.copyWith(color: context.textSecondary),
                              children: [
                                TextSpan(
                                  text: 'Sign Up',
                                  style: AppTypography.bodyMedium.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      Center(
                        child: TextButton(
                          onPressed: () => Navigation.goToHome(context),
                          child: Text(
                            'Continue as Guest →',
                            style: AppTypography.bodySmall.copyWith(color: context.textSecondary),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
