import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../services/database_service.dart';
import '../../models/incubator_data.dart';

class SettingsSheet extends StatefulWidget {
  final IncubatorSettings settings;

  const SettingsSheet({super.key, required this.settings});

  @override
  State<SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<SettingsSheet> {
  final _db = DatabaseService();
  late double _targetTemp;
  late double _targetHumidity;
  late int _incubationDay;
  late bool _eggTurning;

  @override
  void initState() {
    super.initState();
    _targetTemp = widget.settings.targetTemp;
    _targetHumidity = widget.settings.targetHumidity;
    _incubationDay = widget.settings.incubationDay;
    _eggTurning = widget.settings.eggTurning;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Handle bar ──
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            Text(
              'Incubator Settings',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Adjust parameters remotely',
              style: Theme.of(context).textTheme.bodyMedium,
            ),

            const SizedBox(height: 28),

            // ── Target Temperature ──
            _buildSliderTile(
              context,
              icon: Icons.thermostat,
              iconColor: const Color(0xFFFF6B35),
              label: 'Target Temperature',
              value: '${_targetTemp.toStringAsFixed(1)}°C',
              slider: Slider(
                value: _targetTemp,
                min: 30,
                max: 42,
                divisions: 24,
                activeColor: const Color(0xFFFF6B35),
                onChanged: (v) => setState(() => _targetTemp = v),
                onChangeEnd: (v) => _db.setTargetTemp(v),
              ),
            ),

            const SizedBox(height: 16),

            // ── Target Humidity ──
            _buildSliderTile(
              context,
              icon: Icons.water_drop,
              iconColor: AppColors.accent,
              label: 'Target Humidity',
              value: '${_targetHumidity.toStringAsFixed(0)}%',
              slider: Slider(
                value: _targetHumidity,
                min: 30,
                max: 90,
                divisions: 60,
                activeColor: AppColors.accent,
                onChanged: (v) => setState(() => _targetHumidity = v),
                onChangeEnd: (v) => _db.setTargetHumidity(v),
              ),
            ),

            const SizedBox(height: 16),

            // ── Incubation Day ──
            _buildSliderTile(
              context,
              icon: Icons.calendar_today,
              iconColor: AppColors.info,
              label: 'Incubation Day',
              value: 'Day $_incubationDay / 21',
              slider: Slider(
                value: _incubationDay.toDouble(),
                min: 1,
                max: 21,
                divisions: 20,
                activeColor: AppColors.info,
                onChanged: (v) => setState(() => _incubationDay = v.round()),
                onChangeEnd: (v) => _db.setIncubationDay(v.round()),
              ),
            ),

            const SizedBox(height: 20),

            // ── Egg Turning Toggle ──
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkElevated : AppColors.background,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _eggTurning
                          ? AppColors.success.withValues(alpha: 0.12)
                          : AppColors.danger.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.sync,
                      color: _eggTurning ? AppColors.success : AppColors.danger,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Egg Turning',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                        ),
                        Text(
                          _eggTurning ? 'Active - Every 4 hours' : 'Disabled',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _eggTurning,
                    activeColor: AppColors.success,
                    onChanged: (v) {
                      setState(() => _eggTurning = v);
                      _db.setEggTurning(v);
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSliderTile(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required Slider slider,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? AppColors.darkElevated
            : AppColors.background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: iconColor),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: iconColor,
                ),
              ),
            ],
          ),
          slider,
        ],
      ),
    );
  }
}
