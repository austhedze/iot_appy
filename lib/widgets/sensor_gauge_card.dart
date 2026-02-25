import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../../theme/app_colors.dart';

class SensorGaugeCard extends StatelessWidget {
  final String title;
  final String value;
  final String unit;
  final double percent;
  final double target;
  final IconData icon;
  final LinearGradient gradient;
  final Color progressColor;

  const SensorGaugeCard({
    super.key,
    required this.title,
    required this.value,
    required this.unit,
    required this.percent,
    required this.target,
    required this.icon,
    required this.gradient,
    required this.progressColor,
  });

  @override
  Widget build(BuildContext context) {
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
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Center(
            child: CircularPercentIndicator(
              radius: 52,
              lineWidth: 8,
              percent: percent.clamp(0.0, 1.0),
              center: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    value,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 22,
                        ),
                  ),
                  Text(
                    unit,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontSize: 11,
                        ),
                  ),
                ],
              ),
              progressColor: progressColor,
              backgroundColor: progressColor.withValues(alpha: 0.12),
              circularStrokeCap: CircularStrokeCap.round,
              animation: true,
              animationDuration: 800,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.track_changes, size: 14, color: AppColors.textHint),
              const SizedBox(width: 4),
              Text(
                'Target: ${target.toStringAsFixed(1)}$unit',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 11,
                      color: AppColors.textHint,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
