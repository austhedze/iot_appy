import 'package:flutter/material.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import '../../theme/app_colors.dart';

class IncubationProgressCard extends StatelessWidget {
  final int currentDay;
  final int totalDays;
  final int eggTurnCount;
  final bool eggTurningEnabled;

  const IncubationProgressCard({
    super.key,
    required this.currentDay,
    this.totalDays = 21,
    required this.eggTurnCount,
    required this.eggTurningEnabled,
  });

  String get _phaseLabel {
    if (currentDay <= 7) return 'Early Development';
    if (currentDay <= 14) return 'Mid Development';
    if (currentDay <= 18) return 'Late Development';
    return 'Lockdown / Hatching';
  }

  Color get _phaseColor {
    if (currentDay <= 7) return AppColors.info;
    if (currentDay <= 14) return AppColors.accent;
    if (currentDay <= 18) return AppColors.warning;
    return AppColors.success;
  }

  @override
  Widget build(BuildContext context) {
    final progress = (currentDay / totalDays).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: AppColors.successGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.egg_alt, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                'Incubation Progress',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ── Day counter ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Day $currentDay',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: _phaseColor,
                    ),
              ),
              Text(
                ' / $totalDays',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.textHint,
                      fontWeight: FontWeight.w400,
                    ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _phaseColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _phaseLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _phaseColor,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ── Progress bar ──
          LinearPercentIndicator(
            padding: EdgeInsets.zero,
            lineHeight: 10,
            percent: progress,
            barRadius: const Radius.circular(8),
            progressColor: _phaseColor,
            backgroundColor: _phaseColor.withValues(alpha: 0.1),
            animation: true,
            animationDuration: 800,
          ),

          const SizedBox(height: 18),

          // ── Stats row ──
          Row(
            children: [
              _buildStat(
                context,
                icon: Icons.rotate_right,
                label: 'Egg Turns',
                value: '$eggTurnCount',
              ),
              const SizedBox(width: 20),
              _buildStat(
                context,
                icon: Icons.sync,
                label: 'Auto Turn',
                value: eggTurningEnabled ? 'Active' : 'Stopped',
                color: eggTurningEnabled ? AppColors.success : AppColors.danger,
              ),
              const SizedBox(width: 20),
              _buildStat(
                context,
                icon: Icons.calendar_today,
                label: 'Remaining',
                value: '${(totalDays - currentDay).clamp(0, totalDays)} days',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStat(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    Color? color,
  }) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 18, color: color ?? AppColors.textHint),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: color,
                ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10),
          ),
        ],
      ),
    );
  }
}
