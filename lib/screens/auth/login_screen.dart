import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_colors.dart';
import '../../services/auth_service.dart';
import '../../services/theme_provider.dart';
import 'register_screen.dart';
import '../dashboard/dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  final ThemeProvider themeProvider;

  const LoginScreen({super.key, required this.themeProvider});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _auth = AuthService();

  bool _loading = false;
  bool _obscurePassword = true;
  bool _resetSent = false;

  late AnimationController _shakeController;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      HapticFeedback.mediumImpact();
      _shakeController.forward(from: 0);
      return;
    }

    setState(() => _loading = true);
    HapticFeedback.lightImpact();

    try {
      await _auth.signIn(
        email: _emailCtrl.text,
        password: _passwordCtrl.text,
      );
      if (!mounted) return;
      HapticFeedback.heavyImpact();

      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) =>
              DashboardScreen(themeProvider: widget.themeProvider),
          transitionsBuilder: (_, anim, __, child) => FadeTransition(
            opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
            child: child,
          ),
          transitionDuration: const Duration(milliseconds: 400),
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      _shakeController.forward(from: 0);
      _showError(AuthService.getErrorMessage(e));
    } catch (e) {
      if (!mounted) return;
      _showError('An unexpected error occurred.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _forgotPassword() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      _showError('Enter your email address first.');
      _emailFocus.requestFocus();
      return;
    }

    try {
      await _auth.resetPassword(email);
      if (!mounted) return;
      setState(() => _resetSent = true);
      HapticFeedback.lightImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded,
                  color: Colors.white, size: 20),
              const SizedBox(width: 10),
              const Expanded(
                child: Text('Password reset email sent!'),
              ),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          duration: const Duration(seconds: 4),
        ),
      );
      // Reset after 5 seconds
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted) setState(() => _resetSent = false);
      });
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      _showError(AuthService.getErrorMessage(e));
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded,
                color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(msg)),
          ],
        ),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

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
        backgroundColor: isDark ? AppColors.darkBackground : Colors.white,
        body: Stack(
          children: [
            // ── Background decorations ──
            Positioned(
              top: -size.width * 0.35,
              right: -size.width * 0.25,
              child: Container(
                width: size.width * 0.7,
                height: size.width * 0.7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: isDark ? 0.08 : 0.06),
                      AppColors.primary.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -size.width * 0.3,
              left: -size.width * 0.2,
              child: Container(
                width: size.width * 0.6,
                height: size.width * 0.6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.accent.withValues(alpha: isDark ? 0.06 : 0.04),
                      AppColors.accent.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),

            // ── Main content ──
            SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: size.height -
                        MediaQuery.of(context).padding.top -
                        MediaQuery.of(context).padding.bottom,
                  ),
                  child: Column(
                    children: [
                      SizedBox(height: bottomInset > 0 ? 30 : size.height * 0.08),

                      // ── Logo ──
                      _buildLogo(isDark),

                      const SizedBox(height: 36),

                      // ── Welcome text ──
                      _buildHeader(isDark),

                      SizedBox(height: bottomInset > 0 ? 28 : 44),

                      // ── Form Card ──
                      AnimatedBuilder(
                        animation: _shakeController,
                        builder: (context, child) {
                          final shake = _shakeController.isAnimating
                              ? (4 *
                                  (0.5 - (_shakeController.value - 0.5).abs()) *
                                  (_shakeController.value < 0.25
                                      ? 1
                                      : _shakeController.value < 0.5
                                          ? -1
                                          : _shakeController.value < 0.75
                                              ? 1
                                              : -1))
                              : 0.0;
                          return Transform.translate(
                            offset: Offset(shake * 8, 0),
                            child: child,
                          );
                        },
                        child: _buildFormCard(isDark),
                      ),

                      const SizedBox(height: 28),

                      // ── Register link ──
                      _buildRegisterLink(isDark),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo(bool isDark) {
    return Column(
      children: [
        Container(
          width: 84,
          height: 84,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0D47A1), Color(0xFF1976D2), Color(0xFF42A5F5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: isDark ? 0.4 : 0.25),
                blurRadius: 28,
                offset: const Offset(0, 10),
                spreadRadius: -2,
              ),
              BoxShadow(
                color: AppColors.primary.withValues(alpha: isDark ? 0.2 : 0.1),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Subtle inner glow
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.15),
                      Colors.white.withValues(alpha: 0.0),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
              const Icon(
                Icons.egg_outlined,
                size: 40,
                color: Colors.white,
              ),
            ],
          ),
        )
            .animate()
            .scale(
              begin: const Offset(0.5, 0.5),
              end: const Offset(1.0, 1.0),
              duration: 600.ms,
              curve: Curves.easeOutBack,
            )
            .fadeIn(duration: 400.ms),
      ],
    );
  }

  Widget _buildHeader(bool isDark) {
    return Column(
      children: [
        Text(
          'Welcome Back',
          style: GoogleFonts.inter(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            letterSpacing: -0.5,
            height: 1.2,
          ),
        ).animate(delay: 150.ms).fadeIn(duration: 500.ms).slideY(
              begin: 0.15,
              end: 0,
              curve: Curves.easeOut,
            ),
        const SizedBox(height: 8),
        Text(
          'Sign in to monitor your incubator',
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
            height: 1.4,
          ),
        ).animate(delay: 250.ms).fadeIn(duration: 500.ms).slideY(
              begin: 0.15,
              end: 0,
              curve: Curves.easeOut,
            ),
      ],
    );
  }

  Widget _buildFormCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 28, 22, 22),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkCardBg
            : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
        border: isDark
            ? Border.all(color: Colors.white.withValues(alpha: 0.06))
            : Border.all(color: Colors.grey.shade100),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Email field ──
            Text(
              'Email',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _emailCtrl,
              focusNode: _emailFocus,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'you@example.com',
                hintStyle: GoogleFonts.inter(
                  fontSize: 15,
                  color: isDark ? AppColors.darkTextHint : AppColors.textHint,
                ),
                prefixIcon: Padding(
                  padding: const EdgeInsets.only(left: 16, right: 12),
                  child: Icon(
                    Icons.email_rounded,
                    size: 20,
                    color: isDark
                        ? AppColors.darkTextHint
                        : AppColors.textHint,
                  ),
                ),
                prefixIconConstraints: const BoxConstraints(
                  minWidth: 48,
                  minHeight: 48,
                ),
                filled: true,
                fillColor: isDark
                    ? AppColors.darkElevated
                    : AppColors.background,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.04)
                        : Colors.grey.shade200,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: AppColors.primary.withValues(alpha: 0.6),
                    width: 1.5,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.danger),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide:
                      const BorderSide(color: AppColors.danger, width: 1.5),
                ),
                errorStyle: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onFieldSubmitted: (_) => _passwordFocus.requestFocus(),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Email is required';
                if (!RegExp(r'^[\w\-.]+@([\w\-]+\.)+[\w\-]{2,4}$')
                    .hasMatch(v.trim())) {
                  return 'Enter a valid email';
                }
                return null;
              },
            )
                .animate(delay: 300.ms)
                .fadeIn(duration: 400.ms)
                .slideY(begin: 0.08, end: 0),

            const SizedBox(height: 20),

            // ── Password field ──
            Text(
              'Password',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _passwordCtrl,
              focusNode: _passwordFocus,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: '••••••••',
                hintStyle: GoogleFonts.inter(
                  fontSize: 15,
                  color: isDark ? AppColors.darkTextHint : AppColors.textHint,
                ),
                prefixIcon: Padding(
                  padding: const EdgeInsets.only(left: 16, right: 12),
                  child: Icon(
                    Icons.lock_rounded,
                    size: 20,
                    color: isDark
                        ? AppColors.darkTextHint
                        : AppColors.textHint,
                  ),
                ),
                prefixIconConstraints: const BoxConstraints(
                  minWidth: 48,
                  minHeight: 48,
                ),
                suffixIcon: Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: IconButton(
                    icon: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_rounded
                            : Icons.visibility_rounded,
                        key: ValueKey(_obscurePassword),
                        color: isDark
                            ? AppColors.darkTextHint
                            : AppColors.textHint,
                        size: 20,
                      ),
                    ),
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                  ),
                ),
                filled: true,
                fillColor: isDark
                    ? AppColors.darkElevated
                    : AppColors.background,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.04)
                        : Colors.grey.shade200,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: AppColors.primary.withValues(alpha: 0.6),
                    width: 1.5,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.danger),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide:
                      const BorderSide(color: AppColors.danger, width: 1.5),
                ),
                errorStyle: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onFieldSubmitted: (_) => _login(),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Password is required';
                if (v.length < 6) return 'Minimum 6 characters';
                return null;
              },
            )
                .animate(delay: 400.ms)
                .fadeIn(duration: 400.ms)
                .slideY(begin: 0.08, end: 0),

            const SizedBox(height: 8),

            // ── Forgot password ──
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _resetSent ? null : _forgotPassword,
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  _resetSent ? 'Reset email sent ✓' : 'Forgot Password?',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _resetSent
                        ? AppColors.success
                        : isDark
                            ? AppColors.accentLight
                            : AppColors.primary,
                  ),
                ),
              ),
            ).animate(delay: 500.ms).fadeIn(duration: 400.ms),

            const SizedBox(height: 22),

            // ── Sign In button ──
            SizedBox(
              width: double.infinity,
              height: 54,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  gradient: _loading
                      ? LinearGradient(
                          colors: [
                            AppColors.primary.withValues(alpha: 0.6),
                            AppColors.primaryLight.withValues(alpha: 0.6),
                          ],
                        )
                      : const LinearGradient(
                          colors: [
                            Color(0xFF0D47A1),
                            Color(0xFF1565C0),
                            Color(0xFF1976D2),
                          ],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                  boxShadow: _loading
                      ? []
                      : [
                          BoxShadow(
                            color: AppColors.primary
                                .withValues(alpha: isDark ? 0.35 : 0.25),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                            spreadRadius: -2,
                          ),
                        ],
                ),
                child: ElevatedButton(
                  onPressed: _loading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    elevation: 0,
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: _loading
                        ? const SizedBox(
                            key: ValueKey('loader'),
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor:
                                  AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                        : Row(
                            key: const ValueKey('text'),
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Sign In',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.2,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.arrow_forward_rounded,
                                size: 20,
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            )
                .animate(delay: 600.ms)
                .fadeIn(duration: 400.ms)
                .slideY(begin: 0.15, end: 0),
          ],
        ),
      ),
    ).animate(delay: 250.ms).fadeIn(duration: 500.ms).slideY(
          begin: 0.05,
          end: 0,
          curve: Curves.easeOut,
        );
  }

  Widget _buildRegisterLink(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Don't have an account? ",
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
          ),
        ),
        GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (_, __, ___) =>
                    RegisterScreen(themeProvider: widget.themeProvider),
                transitionsBuilder: (_, anim, __, child) => SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(1, 0),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: anim,
                    curve: Curves.easeOutCubic,
                  )),
                  child: child,
                ),
                transitionDuration: const Duration(milliseconds: 350),
              ),
            );
          },
          child: Text(
            'Sign Up',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.accentLight : AppColors.primary,
            ),
          ),
        ),
      ],
    ).animate(delay: 700.ms).fadeIn(duration: 400.ms);
  }
}
