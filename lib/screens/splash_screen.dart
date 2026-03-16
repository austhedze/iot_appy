


import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:page_transition/page_transition.dart';
import '../theme/app_colors.dart';
import '../services/auth_service.dart';
import '../services/theme_provider.dart';
import 'auth/login_screen.dart';
import 'dashboard/dashboard_screen.dart';

class SplashScreen extends StatefulWidget {
  final ThemeProvider themeProvider;

  const SplashScreen({super.key, required this.themeProvider});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  final AuthService _auth = AuthService();
  late AnimationController _ringController;
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();

    final isDark = widget.themeProvider.isDark;
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: isDark ? AppColors.darkBackground : const Color(0xFFF4F7FB),
        systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      ),
    );

    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: false);

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _navigate();
  }

  @override
  void dispose() {
    _ringController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }
  Future<void> _navigate() async {
    await Future.delayed(const Duration(milliseconds: 3000));
    if (!mounted) return;

    final user = _auth.currentUser;

    Navigator.pushReplacement(
      context,
      PageTransition(
        child: user != null
            ? DashboardScreen(themeProvider: widget.themeProvider)
            : LoginScreen(themeProvider: widget.themeProvider),
        type: PageTransitionType.leftToRight,
        duration: const Duration(milliseconds: 1000),
        curve: Curves.linear,
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
  // final isDark = widget.themeProvider.isDark;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        systemNavigationBarColor:
            isDark ? AppColors.darkBackground : Colors.white,
        systemNavigationBarIconBrightness:
            isDark ? Brightness.light : Brightness.dark,
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      ),
      child: Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : const Color(0xFFF4F7FB),
      body: SizedBox.expand(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // ── Deep radial background glow ──
            Positioned.fill(
              child: CustomPaint(
                painter: _RadialGlowPainter(isDark: isDark),
              ),
            ),

            // ── Fine mesh grid overlay ──
            Positioned.fill(
              child: CustomPaint(
                painter: _MeshGridPainter(isDark: isDark),
              ).animate().fadeIn(duration: 1400.ms),
            ),

            // ── Main layout ──
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 5),

                // ── Icon mark ──
                _buildIconMark(isDark)
                    .animate()
                    .scale(
                      begin: const Offset(0.5, 0.5),
                      end: const Offset(1.0, 1.0),
                      duration: 800.ms,
                      curve: Curves.easeOutBack,
                    )
                    .fadeIn(duration: 600.ms),

                const SizedBox(height: 40),

                // ── Wordmark ──
                Text(
                  'IoT Incubator',
                  style: GoogleFonts.outfit(
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.darkTextPrimary : const Color(0xFF0D1B2E),
                    letterSpacing: 0.2,
                  ),
                )
                    .animate(delay: 400.ms)
                    .fadeIn(duration: 600.ms)
                    .slideY(begin: 0.2, end: 0, curve: Curves.easeOut),

                const SizedBox(height: 10),

                // ── Subtitle ──
                Text(
                  'Smart Poultry Monitoring',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: isDark ? AppColors.darkTextSecondary : const Color(0xFF5A7A9E),
                    letterSpacing: 1.6,
                  ),
                )
                    .animate(delay: 600.ms)
                    .fadeIn(duration: 600.ms)
                    .slideY(begin: 0.2, end: 0, curve: Curves.easeOut),

                const Spacer(flex: 4),

                // ── Progress indicator ──
                _buildProgressBar(isDark)
                    .animate(delay: 1000.ms)
                    .fadeIn(duration: 500.ms),

                const SizedBox(height: 20),

                // ── Version ──
                Text(
                  'Version 1.0.0',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: isDark ? AppColors.darkTextHint : const Color(0xFFADBDD0),
                    letterSpacing: 1.0,
                  ),
                ).animate(delay: 1100.ms).fadeIn(duration: 500.ms),

                SizedBox(height: size.height * 0.07),
              ],
            ),
          ],
        ),
      ),
    ));
  }

  Widget _buildIconMark(bool isDark) {
    final ringColor = isDark ? const Color(0xFF64B5F6) : const Color(0xFF1976D2);
    final haloColor = isDark ? const Color(0xFF42A5F5) : const Color(0xFF1565C0);

    return SizedBox(
      width: 140,
      height: 140,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // ── Outermost animated scan ring ──
          AnimatedBuilder(
            animation: _ringController,
            builder: (context, _) {
              final progress = _ringController.value;
              final opacity = (1.0 - progress).clamp(0.0, 1.0) * 0.25;
              final scale = 0.72 + (progress * 0.55);
              return Transform.scale(
                scale: scale,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: ringColor.withValues(alpha: opacity),
                      width: 1.5,
                    ),
                  ),
                ),
              );
            },
          ),

          // ── Static soft halo ring ──
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: haloColor.withValues(alpha: isDark ? 0.25 : 0.18),
                width: 1,
              ),
            ),
          ),

          // ── Icon container with gradient + gloss ──
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF1E88E5), const Color(0xFF1565C0)]
                    : [const Color(0xFF1565C0), const Color(0xFF0D47A1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: ringColor.withValues(alpha: isDark ? 0.55 : 0.45),
                  blurRadius: 32,
                  spreadRadius: 2,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: const Color(0xFF0D47A1).withValues(alpha: isDark ? 0.35 : 0.25),
                  blurRadius: 56,
                  spreadRadius: 8,
                  offset: const Offset(0, 20),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Inner gloss highlight
                Positioned(
                  top: 10,
                  left: 14,
                  child: Container(
                    width: 30,
                    height: 14,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0.18),
                          Colors.white.withValues(alpha: 0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),

                // ── THE ICON — sensors only, prominently sized ──
                AnimatedBuilder(
                  animation: _shimmerController,
                  builder: (context, _) {
                    final shimmer = 0.88 + (_shimmerController.value * 0.12);
                    return Icon(
                      Icons.sensors_rounded,
                      size: 46,
                      color: Colors.white.withValues(alpha: shimmer),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(bool isDark) {
    return SizedBox(
      width: 120,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 2200),
          curve: Curves.easeInOut,
          builder: (context, value, _) {
            return LinearProgressIndicator(
              value: value,
              minHeight: 2,
              backgroundColor: isDark ? const Color(0xFF2A2D3A) : const Color(0xFFDDE6F0),
              valueColor: AlwaysStoppedAnimation<Color>(
                isDark ? const Color(0xFF64B5F6) : const Color(0xFF2196F3),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _RadialGlowPainter extends CustomPainter {
  final bool isDark;
  _RadialGlowPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.42);

    final paint = Paint()
      ..shader = RadialGradient(
        colors: isDark
            ? [
                const Color(0xFF1565C0).withValues(alpha: 0.25),
                const Color(0xFF0F1117).withValues(alpha: 0.0),
              ]
            : [
                const Color(0xFFBDD5F0).withValues(alpha: 0.45),
                const Color(0xFFF4F7FB).withValues(alpha: 0.0),
              ],
        stops: const [0.0, 1.0],
      ).createShader(
        Rect.fromCircle(center: center, radius: size.width * 0.72),
      );

    canvas.drawCircle(center, size.width * 0.72, paint);
  }

  @override
  bool shouldRepaint(covariant _RadialGlowPainter oldDelegate) => oldDelegate.isDark != isDark;
}

class _MeshGridPainter extends CustomPainter {
  final bool isDark;
  _MeshGridPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isDark
          ? const Color(0xFF4A5568).withValues(alpha: 0.15)
          : const Color(0xFF90AFC8).withValues(alpha: 0.12)
      ..strokeWidth = 0.5;

    const spacing = 40.0;

    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _MeshGridPainter oldDelegate) => oldDelegate.isDark != isDark;
}