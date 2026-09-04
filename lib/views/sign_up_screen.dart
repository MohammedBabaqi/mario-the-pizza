import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/app_colors.dart';
import '../utils/app_typography.dart';
import '../utils/navigation.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../widgets/pizza_clipper.dart';
import '../widgets/mario_text_field.dart';
import '../widgets/mario_button.dart';
import '../utils/app_snackbar.dart';

/// Sign Up screen.
/// Requirement: SignUp.
class SignUpScreen extends StatelessWidget {
  const SignUpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bg,
      body: SingleChildScrollView(
        child: Column(
          children: [
            ClippedHeader(
              height: 200,
              child: SafeArea(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('🎉', style: TextStyle(fontSize: 44)),
                      const SizedBox(height: 8),
                      Text('Join MARIO', style: AppTypography.headlineLarge.copyWith(color: AppColors.white, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(24),
              child: Consumer<AuthViewModel>(
                builder: (context, authVM, _) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Create Account', style: AppTypography.displaySmall.copyWith(color: context.text)),
                      const SizedBox(height: 8),
                      Text(
                        'Sign up to start ordering delicious pizza',
                        style: AppTypography.bodyMedium.copyWith(color: context.textSecondary),
                      ),
                      const SizedBox(height: 28),

                      MarioTextField(
                        hint: 'Full Name',
                        prefixIcon: const Icon(Icons.person_outlined),
                        onChanged: authVM.onSignUpDisplayNameChanged,
                      ),
                      const SizedBox(height: 14),

                      MarioTextField(
                        hint: 'Email address',
                        keyboardType: TextInputType.emailAddress,
                        prefixIcon: const Icon(Icons.email_outlined),
                        onChanged: authVM.onSignUpEmailChanged,
                      ),
                      const SizedBox(height: 14),

                      MarioTextField(
                        hint: 'Password (min 6 characters)',
                        obscureText: true,
                        prefixIcon: const Icon(Icons.lock_outlined),
                        onChanged: authVM.onSignUpPasswordChanged,
                      ),
                      const SizedBox(height: 14),

                      MarioTextField(
                        hint: 'Confirm Password',
                        obscureText: true,
                        prefixIcon: const Icon(Icons.lock_outlined),
                        onChanged: authVM.onSignUpConfirmPasswordChanged,
                      ),

                      if (authVM.signUpError != null) ...[
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
                                  authVM.signUpError!,
                                  style: AppTypography.bodySmall.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 28),

                      MarioButton(
                        label: 'Create Account',
                        isLoading: authVM.signUpStatus == AuthFormStatus.loading,
                        onPressed: authVM.isSignUpValid
                            ? () async {
                                await authVM.signUp();
                                if (context.mounted && authVM.isAuthenticated) {
                                  showMarioSnackBar(context, 'Account created! Welcome, ${authVM.displayName}! 🍕');
                                  Navigation.goToHome(context);
                                }
                              }
                            : null,
                      ),

                      const SizedBox(height: 20),

                      Center(
                        child: TextButton(
                          onPressed: () => Navigation.goToSignIn(context),
                          child: RichText(
                            text: TextSpan(
                              text: 'Already have an account? ',
                              style: AppTypography.bodyMedium.copyWith(color: context.textSecondary),
                              children: [
                                TextSpan(
                                  text: 'Sign In',
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
