import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class DeviceControlCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isOn;
  final Color activeColor;
  final VoidCallback? onToggle;

  const DeviceControlCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isOn,
    required this.activeColor,
    this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.cardShadow,
        border: isOn
            ? Border.all(color: activeColor.withValues(alpha: 0.3), width: 1.5)
            : null,
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: isOn
                  ? activeColor.withValues(alpha: 0.12)
                  : AppColors.background,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              icon,
              color: isOn ? activeColor : AppColors.textHint,
              size: 22,
            ),
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
                        fontSize: 14,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isOn
                  ? activeColor.withValues(alpha: 0.1)
                  : AppColors.background,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              isOn ? 'ON' : 'OFF',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isOn ? activeColor : AppColors.textHint,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
