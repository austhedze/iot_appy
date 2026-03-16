import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../services/auth_service.dart';
import '../../services/theme_provider.dart';
import '../../theme/app_colors.dart';
import '../auth/login_screen.dart';

class SettingsScreen extends StatelessWidget {
  final ThemeProvider themeProvider;

  const SettingsScreen({super.key, required this.themeProvider});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final auth = AuthService();
    final user = auth.currentUser;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarColor:
            isDark ? AppColors.darkBackground : Colors.white,
        systemNavigationBarIconBrightness:
            isDark ? Brightness.light : Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            // ── Custom App Bar ──
            SliverToBoxAdapter(
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 20, 0),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 20,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.textPrimary,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: isDark
                              ? AppColors.darkCardBg
                              : AppColors.surface,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(13),
                          ),
                          fixedSize: const Size(44, 44),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Settings',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ).animate().fadeIn(duration: 300.ms),
                ),
              ),
            ),

            // ── Profile Card ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: _buildProfileCard(context, user, isDark)
                    .animate(delay: 100.ms)
                    .fadeIn(duration: 400.ms)
                    .slideY(begin: 0.08, end: 0),
              ),
            ),

            // ── Appearance Section ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
                child: _buildSectionHeader(context, 'Appearance', Icons.palette_outlined)
                    .animate(delay: 200.ms)
                    .fadeIn(duration: 400.ms),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: _buildThemeCard(context, isDark)
                    .animate(delay: 250.ms)
                    .fadeIn(duration: 400.ms)
                    .slideY(begin: 0.08, end: 0),
              ),
            ),

            // ── About Section ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
                child: _buildSectionHeader(context, 'About', Icons.info_outline_rounded)
                    .animate(delay: 300.ms)
                    .fadeIn(duration: 400.ms),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: _buildAboutCard(context, isDark)
                    .animate(delay: 350.ms)
                    .fadeIn(duration: 400.ms)
                    .slideY(begin: 0.08, end: 0),
              ),
            ),

            // ── Sign Out ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 32, 20, 0),
                child: _buildSignOutButton(context, auth, isDark)
                    .animate(delay: 400.ms)
                    .fadeIn(duration: 400.ms)
                    .slideY(begin: 0.08, end: 0),
              ),
            ),

            // ── Bottom Spacing ──
            const SliverToBoxAdapter(
              child: SizedBox(height: 40),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard(
      BuildContext context, dynamic user, bool isDark) {
    final name = user?.displayName ?? 'User';
    final email = user?.email ?? '';
    final initials = name.isNotEmpty
        ? name.split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join().toUpperCase()
        : 'U';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBg : AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: isDark ? null : AppColors.cardShadow,
        border: isDark
            ? Border.all(color: Colors.white.withValues(alpha: 0.06))
            : null,
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  email,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 13,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          title.toUpperCase(),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: AppColors.primary,
                fontSize: 11,
              ),
        ),
      ],
    );
  }

  Widget _buildThemeCard(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBg : AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: isDark ? null : AppColors.cardShadow,
        border: isDark
            ? Border.all(color: Colors.white.withValues(alpha: 0.06))
            : null,
      ),
      child: Column(
        children: [
          _buildSettingsTile(
            context,
            icon: isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
            iconBgColor: isDark
                ? const Color(0xFF3B3176)
                : const Color(0xFFFFF3E0),
            iconColor: isDark
                ? const Color(0xFFBB86FC)
                : const Color(0xFFFF9800),
            title: 'Dark Mode',
            subtitle: isDark ? 'On' : 'Off',
            trailing: Switch.adaptive(
              value: isDark,
              activeColor: AppColors.primaryLight,
              onChanged: (_) => themeProvider.toggleTheme(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutCard(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBg : AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: isDark ? null : AppColors.cardShadow,
        border: isDark
            ? Border.all(color: Colors.white.withValues(alpha: 0.06))
            : null,
      ),
      child: Column(
        children: [
          _buildSettingsTile(
            context,
            icon: Icons.info_outline_rounded,
            iconBgColor: isDark
                ? AppColors.info.withValues(alpha: 0.15)
                : AppColors.info.withValues(alpha: 0.1),
            iconColor: AppColors.info,
            title: 'Version',
            subtitle: '1.0.0',
          ),
          Divider(
            height: 1,
            indent: 62,
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.grey.shade100,
          ),
          _buildSettingsTile(
            context,
            icon: Icons.egg_outlined,
            iconBgColor: isDark
                ? AppColors.warning.withValues(alpha: 0.15)
                : AppColors.warning.withValues(alpha: 0.1),
            iconColor: AppColors.warning,
            title: 'IoT Incubator',
            subtitle: 'Smart egg incubation monitor',
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontSize: 12,
                          ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSignOutButton(
      BuildContext context, AuthService auth, bool isDark) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton.icon(
        onPressed: () => _confirmSignOut(context, auth),
        icon: const Icon(Icons.logout_rounded, size: 20),
        label: const Text(
          'Sign Out',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.danger,
          side: BorderSide(
            color: AppColors.danger.withValues(alpha: isDark ? 0.4 : 0.3),
            width: 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor:
              AppColors.danger.withValues(alpha: isDark ? 0.08 : 0.04),
        ),
      ),
    );
  }

  Future<void> _confirmSignOut(BuildContext context, AuthService auth) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Sign Out',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
        ),
        content: Text(
          'Are you sure you want to sign out of IoT Incubator?',
          style: TextStyle(
            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
            height: 1.4,
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        actions: [
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  style: TextButton.styleFrom(
                    minimumSize: const Size(0, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.danger,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 48),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Sign Out',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await auth.signOut();
      if (!context.mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => LoginScreen(themeProvider: themeProvider),
        ),
        (route) => false,
      );
    }
  }
}
