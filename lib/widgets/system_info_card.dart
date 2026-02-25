import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class SystemInfoCard extends StatelessWidget {
  final String uptime;
  final int wifiRSSI;
  final int freeHeap;
  final String status;

  const SystemInfoCard({
    super.key,
    required this.uptime,
    required this.wifiRSSI,
    required this.freeHeap,
    required this.status,
  });

  String get _wifiStrength {
    if (wifiRSSI >= -50) return 'Excellent';
    if (wifiRSSI >= -60) return 'Good';
    if (wifiRSSI >= -70) return 'Fair';
    if (wifiRSSI >= -80) return 'Weak';
    return 'Very Weak';
  }

  Color get _wifiColor {
    if (wifiRSSI >= -50) return AppColors.success;
    if (wifiRSSI >= -60) return AppColors.success;
    if (wifiRSSI >= -70) return AppColors.warning;
    return AppColors.danger;
  }

  IconData get _wifiIcon {
    if (wifiRSSI >= -50) return Icons.wifi;
    if (wifiRSSI >= -60) return Icons.wifi;
    if (wifiRSSI >= -70) return Icons.wifi_2_bar;
    return Icons.wifi_1_bar;
  }

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
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.developer_board,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'System Info',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: status == 'online'
                      ? AppColors.success.withValues(alpha: 0.1)
                      : AppColors.danger.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: status == 'online'
                            ? AppColors.success
                            : AppColors.danger,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      status == 'online' ? 'Online' : 'Offline',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: status == 'online'
                            ? AppColors.success
                            : AppColors.danger,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // ── Info Grid ──
          Row(
            children: [
              _infoTile(
                context,
                icon: Icons.timer_outlined,
                label: 'Uptime',
                value: uptime.isEmpty ? '--' : uptime,
              ),
              const SizedBox(width: 12),
              _infoTile(
                context,
                icon: _wifiIcon,
                label: 'WiFi',
                value: wifiRSSI != 0 ? '${wifiRSSI}dBm' : '--',
                subtitle: _wifiStrength,
                color: _wifiColor,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _infoTile(
                context,
                icon: Icons.memory,
                label: 'Free Memory',
                value: freeHeap > 0
                    ? '${(freeHeap / 1024).toStringAsFixed(0)} KB'
                    : '--',
              ),
              const SizedBox(width: 12),
              _infoTile(
                context,
                icon: Icons.speed,
                label: 'ESP32 Status',
                value: status == 'online' ? 'Running' : 'Disconnected',
                color: status == 'online'
                    ? AppColors.success
                    : AppColors.danger,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    String? subtitle,
    Color? color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(13),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color ?? AppColors.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(fontSize: 10),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      color: color,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 9,
                        color: color ?? AppColors.textHint,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
