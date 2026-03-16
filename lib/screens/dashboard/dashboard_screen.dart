import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_colors.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../services/theme_provider.dart';
import '../../models/incubator_data.dart';
import '../../widgets/sensor_gauge_card.dart';
import '../../widgets/device_control_card.dart';
import '../../widgets/incubation_progress_card.dart';
import '../../widgets/history_chart_card.dart';
import '../../widgets/system_info_card.dart';
import '../../widgets/settings_sheet.dart';
import '../settings/settings_screen.dart';

class DashboardScreen extends StatefulWidget {
  final ThemeProvider themeProvider;

  const DashboardScreen({super.key, required this.themeProvider});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final AuthService _auth = AuthService();
  final DatabaseService _db = DatabaseService();

  IncubatorData _sensorData = IncubatorData();
  IncubatorSettings _settings = IncubatorSettings();
  List<HistoryEntry> _history = [];
  String _status = 'offline';

  late StreamSubscription _sensorSub;
  late StreamSubscription _settingsSub;
  late StreamSubscription _statusSub;
  late StreamSubscription _historySub;

  @override
  void initState() {
    super.initState();
    _listenToStreams();
  }

  void _listenToStreams() {
    _sensorSub = _db.sensorDataStream.listen((data) {
      if (mounted) setState(() => _sensorData = data);
    });

    _settingsSub = _db.settingsStream.listen((settings) {
      if (mounted) setState(() => _settings = settings);
    });

    _statusSub = _db.statusStream.listen((status) {
      if (mounted) setState(() => _status = status);
    });

    _historySub = _db.historyStream.listen((history) {
      if (mounted) setState(() => _history = history);
    });
  }

  @override
  void dispose() {
    _sensorSub.cancel();
    _settingsSub.cancel();
    _statusSub.cancel();
    _historySub.cancel();
    super.dispose();
  }

  void _openAppSettings() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => SettingsScreen(
          themeProvider: widget.themeProvider,
        ),
        transitionsBuilder: (_, animation, __, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  void _openSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SettingsSheet(settings: _settings),
    );
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  String get _userName {
    final name = _auth.currentUser?.displayName;
    if (name != null && name.isNotEmpty) return name.split(' ').first;
    return 'User';
  }

  @override
  Widget build(BuildContext context) {
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
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            // Force re-listen
            _sensorSub.cancel();
            _settingsSub.cancel();
            _statusSub.cancel();
            _historySub.cancel();
            _listenToStreams();
            await Future.delayed(const Duration(milliseconds: 500));
          },
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              // ── App Bar ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$_greeting 👋',
                              style: Theme.of(
                                context,
                              ).textTheme.bodyMedium?.copyWith(fontSize: 13),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _userName,
                              style: Theme.of(context).textTheme.headlineMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                      _iconButton(
                        icon: Icons.tune_rounded,
                        onTap: _openSettings,
                      ),
                      const SizedBox(width: 10),
                      _iconButton(
                        icon: Icons.settings_rounded,
                        onTap: _openAppSettings,
                      ),
                    ],
                  ).animate().fadeIn(duration: 400.ms),
                ),
              ),

              // ── Status Banner ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: _buildStatusBanner()
                      .animate(delay: 100.ms)
                      .fadeIn(duration: 400.ms)
                      .slideY(begin: 0.1, end: 0),
                ),
              ),

              // ── Sensor Gauges ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child:
                      Row(
                            children: [
                              Expanded(
                                child: SensorGaugeCard(
                                  title: 'Temperature',
                                  value: _sensorData.temperature
                                      .toStringAsFixed(1),
                                  unit: '°C',
                                  percent: (_sensorData.temperature / 50),
                                  target: _settings.targetTemp,
                                  icon: Icons.thermostat,
                                  gradient: AppColors.warmGradient,
                                  progressColor: _getTempColor(),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: SensorGaugeCard(
                                  title: 'Humidity',
                                  value: _sensorData.humidity.toStringAsFixed(
                                    1,
                                  ),
                                  unit: '%',
                                  percent: (_sensorData.humidity / 100),
                                  target: _settings.targetHumidity,
                                  icon: Icons.water_drop,
                                  gradient: AppColors.humidityGradient,
                                  progressColor: _getHumidityColor(),
                                ),
                              ),
                            ],
                          )
                          .animate(delay: 200.ms)
                          .fadeIn(duration: 400.ms)
                          .slideY(begin: 0.1, end: 0),
                ),
              ),

              // ── Incubation Progress ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                  child:
                      IncubationProgressCard(
                            currentDay: _sensorData.incubationDay,
                            eggTurnCount: _sensorData.eggTurnCount,
                            eggTurningEnabled: _sensorData.eggTurningEnabled,
                          )
                          .animate(delay: 300.ms)
                          .fadeIn(duration: 400.ms)
                          .slideY(begin: 0.1, end: 0),
                ),
              ),

              // ── Device Status Header ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 10),
                  child: Text(
                    'Device Status',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ).animate(delay: 400.ms).fadeIn(duration: 400.ms),
                ),
              ),

              // ── Device Control Cards ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      DeviceControlCard(
                            title: 'Heater (Bulb)',
                            subtitle: _sensorData.heaterOn
                                ? 'Warming up eggs'
                                : 'Standby',
                            icon: Icons.whatshot,
                            isOn: _sensorData.heaterOn,
                            activeColor: const Color(0xFFFF6B35),
                          )
                          .animate(delay: 450.ms)
                          .fadeIn(duration: 400.ms)
                          .slideX(begin: -0.05, end: 0),
                      const SizedBox(height: 10),
                      DeviceControlCard(
                            title: 'Cooling Fan',
                            subtitle: _sensorData.fanOn
                                ? 'Active cooling'
                                : 'Idle',
                            icon: Icons.air,
                            isOn: _sensorData.fanOn,
                            activeColor: AppColors.info,
                          )
                          .animate(delay: 500.ms)
                          .fadeIn(duration: 400.ms)
                          .slideX(begin: -0.05, end: 0),
                      const SizedBox(height: 10),
                      DeviceControlCard(
                            title: 'Atomizer (Humidifier)',
                            subtitle: _sensorData.atomizerOn
                                ? 'Increasing humidity'
                                : 'Idle',
                            icon: Icons.opacity,
                            isOn: _sensorData.atomizerOn,
                            activeColor: AppColors.accent,
                          )
                          .animate(delay: 550.ms)
                          .fadeIn(duration: 400.ms)
                          .slideX(begin: -0.05, end: 0),
                    ],
                  ),
                ),
              ),

              // ── History Chart ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: HistoryChartCard(history: _history)
                      .animate(delay: 600.ms)
                      .fadeIn(duration: 400.ms)
                      .slideY(begin: 0.1, end: 0),
                ),
              ),

              // ── System Info ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 30),
                  child:
                      SystemInfoCard(
                            uptime: _sensorData.uptime,
                            wifiRSSI: _sensorData.wifiRSSI,
                            freeHeap: _sensorData.freeHeap,
                            status: _status,
                          )
                          .animate(delay: 700.ms)
                          .fadeIn(duration: 400.ms)
                          .slideY(begin: 0.1, end: 0),
                ),
              ),
            ],
          ),
        ),
      ),
    ));
  }

  Widget _buildStatusBanner() {
    final isOnline = _status == 'online';
    final tempOk =
        (_sensorData.temperature - _settings.targetTemp).abs() <=
        _settings.tempTolerance + 0.5;
    final humOk =
        (_sensorData.humidity - _settings.targetHumidity).abs() <=
        _settings.humidityTolerance + 5;

    String message;
    Color bannerColor;
    IconData bannerIcon;

    if (!isOnline) {
      message = 'Incubator is offline. Check ESP32 connection.';
      bannerColor = AppColors.danger;
      bannerIcon = Icons.cloud_off;
    } else if (!tempOk || !humOk) {
      message = 'Parameters outside optimal range. Auto-adjusting...';
      bannerColor = AppColors.warning;
      bannerIcon = Icons.warning_amber_rounded;
    } else {
      message = 'All systems nominal. Incubation running smoothly.';
      bannerColor = AppColors.success;
      bannerIcon = Icons.check_circle_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: bannerColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: bannerColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(bannerIcon, color: bannerColor, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: bannerColor,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconButton({
    required IconData icon,
    required VoidCallback onTap,
    Color? color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveColor = color ?? (isDark ? AppColors.accentLight : AppColors.primary);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.darkCardBg
              : effectiveColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(13),
          border: isDark
              ? Border.all(color: Colors.white.withValues(alpha: 0.06))
              : null,
        ),
        child: Icon(icon, color: effectiveColor, size: 20),
      ),
    );
  }

  Color _getTempColor() {
    final diff = (_sensorData.temperature - _settings.targetTemp).abs();
    if (diff <= _settings.tempTolerance) return AppColors.success;
    if (diff <= _settings.tempTolerance * 2) return AppColors.warning;
    return AppColors.danger;
  }

  Color _getHumidityColor() {
    final diff = (_sensorData.humidity - _settings.targetHumidity).abs();
    if (diff <= _settings.humidityTolerance) return AppColors.success;
    if (diff <= _settings.humidityTolerance * 2) return AppColors.warning;
    return AppColors.danger;
  }
}
