import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../utils/app_typography.dart';
import '../utils/navigation.dart';
import '../widgets/pizza_clipper.dart';
import '../widgets/mario_button.dart';

/// Welcome/onboarding screen with ClipPath header.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bg,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Clipped Header (Clipper requirement)
            ClippedHeader(
              height: 320,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.only(top: 16, bottom: 42),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('🍕', style: TextStyle(fontSize: 60)),
                      const SizedBox(height: 8),
                      Text(
                        'MARIO',
                        style: AppTypography.displayLarge.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 4,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Premium Pizza Delivery',
                        style: AppTypography.bodyLarge.copyWith(
                          color: AppColors.white.withValues(alpha: 0.9),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.white.withValues(alpha: 0.35)),
                        ),
                        child: const Text(
                          '🇮🇹 Autentica Pizzeria Italiana',
                          style: TextStyle(
                            color: AppColors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Bottom content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                children: [
                  Text(
                    'Handcrafted Pizza\nDelivered Hot & Fresh',
                    style: AppTypography.headlineLarge.copyWith(
                      color: context.text,
                      height: 1.3,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'From classic Margherita to gourmet Truffle Mushroom — your perfect pizza is just a tap away.',
                    style: AppTypography.bodyMedium.copyWith(
                      color: context.textSecondary,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),
                  MarioButton(
                    label: 'Get Started',
                    onPressed: () => Navigation.goToSignIn(context),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => Navigation.goToSignUp(context),
                    child: Text(
                      'Create an Account',
                      style: AppTypography.labelLarge.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigation.goToHome(context),
                    child: Text(
                      'Continue as Guest →',
                      style: AppTypography.bodySmall.copyWith(color: context.textSecondary),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
