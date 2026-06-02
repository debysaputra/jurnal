import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final double blur;
  final Color? tint;
  final VoidCallback? onTap;
  final List<BoxShadow>? shadows;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.borderRadius = 24,
    this.blur = 16,
    this.tint,
    this.onTap,
    this.shadows,
  });

  @override
  Widget build(BuildContext context) {
    // Latar gelap: tanpa tint = permukaan kaca halus; dengan tint = aksen warna lembut.
    final color = tint == null
        ? Colors.white.withValues(alpha: 0.055)
        : tint!.withValues(alpha: 0.16);
    final radius = BorderRadius.circular(borderRadius);
    return Container(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: shadows ??
            [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Material(
            color: color,
            child: InkWell(
              onTap: onTap,
              child: Container(
                padding: padding,
                decoration: BoxDecoration(
                  borderRadius: radius,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.10),
                    width: 1,
                  ),
                ),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class GradientBackground extends StatelessWidget {
  final Widget child;
  const GradientBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const _Blobs(),
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
            child: Container(color: AppColors.surface.withValues(alpha: 0.35)),
          ),
        ),
        child,
      ],
    );
  }
}

class _Blobs extends StatelessWidget {
  const _Blobs();
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return SizedBox.expand(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.gradientStart,
              AppColors.gradientMid,
              AppColors.gradientEnd,
            ],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -80,
              left: -60,
              child: _blob(240, AppColors.primary.withValues(alpha: 0.28)),
            ),
            Positioned(
              top: size.height * 0.25,
              right: -80,
              child: _blob(260, AppColors.sky.withValues(alpha: 0.18)),
            ),
            Positioned(
              bottom: -100,
              left: -40,
              child: _blob(300, AppColors.pink.withValues(alpha: 0.16)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _blob(double s, Color c) => Container(
        width: s,
        height: s,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: c,
        ),
      );
}
