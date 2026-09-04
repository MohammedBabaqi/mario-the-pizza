import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

/// Custom wave clipper for auth screens.
/// Requirement: Clipper.
class PizzaWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height * 0.88);

    final firstControlPoint = Offset(size.width * 0.25, size.height);
    final firstEndPoint = Offset(size.width * 0.5, size.height * 0.93);
    path.quadraticBezierTo(
      firstControlPoint.dx, firstControlPoint.dy,
      firstEndPoint.dx, firstEndPoint.dy,
    );

    final secondControlPoint = Offset(size.width * 0.75, size.height * 0.86);
    final secondEndPoint = Offset(size.width, size.height * 0.93);
    path.quadraticBezierTo(
      secondControlPoint.dx, secondControlPoint.dy,
      secondEndPoint.dx, secondEndPoint.dy,
    );

    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

/// Clipped header widget with gradient background.
class ClippedHeader extends StatelessWidget {
  final double height;
  final Widget? child;

  const ClippedHeader({super.key, this.height = 300, this.child});

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: PizzaWaveClipper(),
      child: Container(
        height: height,
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: AppColors.primaryGradient,
        ),
        child: child,
      ),
    );
  }
}
