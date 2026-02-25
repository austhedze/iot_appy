import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../theme/app_colors.dart';
import '../../models/incubator_data.dart';

class HistoryChartCard extends StatelessWidget {
  final List<HistoryEntry> history;

  const HistoryChartCard({super.key, required this.history});

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
                  gradient: AppColors.coolGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.show_chart,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Sensor History',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // ── Legend ──
          Row(
            children: [
              _legendDot(const Color(0xFFFF6B35), 'Temperature'),
              const SizedBox(width: 16),
              _legendDot(const Color(0xFF00BCD4), 'Humidity'),
            ],
          ),

          const SizedBox(height: 16),

          // ── Chart ──
          SizedBox(
            height: 180,
            child: history.isEmpty ? _emptyChart(context) : _buildChart(),
          ),
        ],
      ),
    );
  }

  Widget _emptyChart(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.timeline, size: 36, color: AppColors.textHint),
          const SizedBox(height: 8),
          Text(
            'Waiting for sensor data...',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildChart() {
    final tempSpots = <FlSpot>[];
    final humSpots = <FlSpot>[];

    for (int i = 0; i < history.length; i++) {
      tempSpots.add(FlSpot(i.toDouble(), history[i].temp));
      humSpots.add(FlSpot(i.toDouble(), history[i].hum));
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 10,
          getDrawingHorizontalLine: (value) =>
              FlLine(color: Colors.grey.withValues(alpha: 0.1), strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              interval: 20,
              getTitlesWidget: (value, meta) => Text(
                value.toInt().toString(),
                style: const TextStyle(fontSize: 10, color: AppColors.textHint),
              ),
            ),
          ),
          bottomTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        minY: 0,
        maxY: 100,
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (spots) => spots.map((spot) {
              final isTemp = spot.barIndex == 0;
              return LineTooltipItem(
                '${spot.y.toStringAsFixed(1)}${isTemp ? '°C' : '%'}',
                TextStyle(
                  color: isTemp
                      ? const Color(0xFFFF6B35)
                      : const Color(0xFF00BCD4),
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              );
            }).toList(),
          ),
        ),
        lineBarsData: [
          // Temperature line
          LineChartBarData(
            spots: tempSpots,
            isCurved: true,
            curveSmoothness: 0.3,
            color: const Color(0xFFFF6B35),
            barWidth: 2.5,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: const Color(0xFFFF6B35).withValues(alpha: 0.08),
            ),
          ),
          // Humidity line
          LineChartBarData(
            spots: humSpots,
            isCurved: true,
            curveSmoothness: 0.3,
            color: const Color(0xFF00BCD4),
            barWidth: 2.5,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: const Color(0xFF00BCD4).withValues(alpha: 0.08),
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.textHint),
        ),
      ],
    );
  }
}
