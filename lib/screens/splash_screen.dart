import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../services/auth_service.dart';
import 'auth/login_screen.dart';
import 'dashboard/dashboard_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  final AuthService _auth = AuthService();
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    // White splash → dark status bar icons
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _navigate();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(milliseconds: 2800));
    if (!mounted) return;

    final user = _auth.currentUser;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) =>
            user != null ? const DashboardScreen() : const LoginScreen(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SizedBox.expand(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // ── Subtle background pattern ──
            Positioned.fill(
              child: CustomPaint(
                painter: _SubtleGridPainter(),
              ).animate().fadeIn(duration: 1200.ms, curve: Curves.easeOut),
            ),

            // ── Main content ──
            Column(
              children: [
                const Spacer(flex: 4),

                // ── Branded Logo Mark ──
                _buildLogoMark()
                    .animate()
                    .scale(
                      begin: const Offset(0.6, 0.6),
                      end: const Offset(1.0, 1.0),
                      duration: 700.ms,
                      curve: Curves.easeOutBack,
                    )
                    .fadeIn(duration: 500.ms),

                const SizedBox(height: 32),

                // ── App Name ──
                Text(
                      'IoT Incubator',
                      style: GoogleFonts.inter(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    )
                    .animate(delay: 350.ms)
                    .fadeIn(duration: 500.ms)
                    .slideY(begin: 0.15, end: 0, curve: Curves.easeOut),

                const SizedBox(height: 8),

                // ── Tagline ──
                Text(
                      'Smart Poultry Monitoring',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textSecondary,
                        letterSpacing: 0.3,
                      ),
                    )
                    .animate(delay: 550.ms)
                    .fadeIn(duration: 500.ms)
                    .slideY(begin: 0.15, end: 0, curve: Curves.easeOut),

                const Spacer(flex: 3),

                // ── Loading indicator ──
                _buildLoadingIndicator()
                    .animate(delay: 900.ms)
                    .fadeIn(duration: 500.ms),

                const SizedBox(height: 12),

                // ── Version tag ──
                Text(
                  'v1.0.0',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textHint.withValues(alpha: 0.6),
                  ),
                ).animate(delay: 1000.ms).fadeIn(duration: 400.ms),

                SizedBox(height: size.height * 0.06),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Branded logo: gradient circle with layered icon elements
  Widget _buildLogoMark() {
    return SizedBox(
      width: 120,
      height: 120,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer glow ring (animated pulse)
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              final scale = 1.0 + (_pulseController.value * 0.06);
              final opacity = 0.12 - (_pulseController.value * 0.06);
              return Transform.scale(
                scale: scale,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primary.withValues(
                        alpha: opacity.clamp(0.0, 1.0),
                      ),
                      width: 2,
                    ),
                  ),
                ),
              );
            },
          ),

          // Main logo circle with gradient
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF0D47A1), Color(0xFF1976D2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.30),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  blurRadius: 48,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Subtle inner highlight
                Positioned(
                  top: 8,
                  left: 12,
                  child: Container(
                    width: 32,
                    height: 16,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0.20),
                          Colors.white.withValues(alpha: 0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),

                // Primary icon — egg
                const Positioned(
                  top: 18,
                  child: Icon(Icons.egg_rounded, size: 36, color: Colors.white),
                ),

                // Secondary accent — wifi/IoT connectivity indicator
                Positioned(
                  bottom: 16,
                  right: 20,
                  child: Icon(
                    Icons.sensors_rounded,
                    size: 20,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),

          // Small accent badge (bottom-right)
          Positioned(
            bottom: 6,
            right: 6,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(color: Colors.white, width: 2.5),
                gradient: const LinearGradient(
                  colors: [Color(0xFF00BCD4), Color(0xFF0097A7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accent.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.thermostat_rounded,
                size: 14,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Minimal loading bar
  Widget _buildLoadingIndicator() {
    return SizedBox(
      width: 140,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(2),
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 2000),
          curve: Curves.easeInOut,
          builder: (context, value, _) {
            return LinearProgressIndicator(
              value: value,
              minHeight: 3,
              backgroundColor: AppColors.primary.withValues(alpha: 0.08),
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.primary,
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Paints a very subtle dot grid behind the splash content
class _SubtleGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE8ECF1).withValues(alpha: 0.5)
      ..strokeCap = StrokeCap.round;

    const spacing = 32.0;
    const radius = 1.0;

    for (double x = spacing; x < size.width; x += spacing) {
      for (double y = spacing; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
