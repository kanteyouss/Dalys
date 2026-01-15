import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../data/models/health_data.dart';
import 'package:intl/intl.dart';

class HealthChart extends StatelessWidget {
  final List<HealthData> data;
  final String title;
  final String parameter; // 'spo2', 'breathingRate', 'pef'
  final Color color;
  final double? minY;
  final double? maxY;
  const HealthChart({
    super.key,
    required this.data,
    required this.title,
    required this.parameter,
    required this.color,
    this.minY,
    this.maxY,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return Card(
        child: Container(
          height: 200,
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.timeline_outlined,
                  size: 48,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 8),
                Text(
                  'Aucune donnée disponible',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 4,
                  height: 24,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                _buildLegend(context),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                _buildChartData(context),
              ),
            ),
            const SizedBox(height: 8),
            _buildStatistics(context),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          _getParameterUnit(),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildStatistics(BuildContext context) {
    final values = _getParameterValues();
    if (values.isEmpty) return const SizedBox.shrink();

    final average = values.reduce((a, b) => a + b) / values.length;
    final min = values.reduce((a, b) => a < b ? a : b);
    final max = values.reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(context, 'Moy.', average.toStringAsFixed(1)),
          ),
          Container(
            width: 1,
            height: 20,
            color: Colors.grey.shade300,
          ),
          Expanded(
            child: _buildStatItem(context, 'Min', min.toStringAsFixed(1)),
          ),
          Container(
            width: 1,
            height: 20,
            color: Colors.grey.shade300,
          ),
          Expanded(
            child: _buildStatItem(context, 'Max', max.toStringAsFixed(1)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey.shade600,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  LineChartData _buildChartData(BuildContext context) {
    final spots = <FlSpot>[];
    final limitedData = data.length > 20 ? data.sublist(data.length - 20) : data;

    for (int i = 0; i < limitedData.length; i++) {
      final value = _getValueForParameter(limitedData[i]);
      spots.add(FlSpot(i.toDouble(), value));
    }

    // Compute dynamic Y bounds if not provided
    double computedMinY;
    double computedMaxY;
    if (spots.isEmpty) {
      computedMinY = 0.0;
      computedMaxY = 1.0;
    } else {
      computedMinY = spots.first.y;
      computedMaxY = spots.first.y;
      for (final s in spots) {
        computedMinY = math.min(computedMinY, s.y);
        computedMaxY = math.max(computedMaxY, s.y);
      }
      // Add padding
      final range = (computedMaxY - computedMinY);
      final pad = range == 0 ? (computedMaxY.abs() * 0.1 + 1.0) : range * 0.12;
      computedMinY = (computedMinY - pad);
      computedMaxY = (computedMaxY + pad);
    }

    final resolvedMinY = minY ?? computedMinY;
    final resolvedMaxY = maxY ?? computedMaxY;

    // Determine sensible intervals
    final yIntervalAuto = ((resolvedMaxY - resolvedMinY) / 4.0).abs();
    final yInterval = math.max(_getGridInterval(), yIntervalAuto > 0 ? yIntervalAuto : _getGridInterval());

    // X axis interval: show up to 4 ticks
    final bottomInterval = limitedData.length > 1 ? math.max(1, ((limitedData.length - 1) / 4).ceil()).toDouble() : 1.0;

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: yInterval,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: Colors.grey.shade300,
            strokeWidth: 1,
          );
        },
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 40,
            interval: bottomInterval,
            getTitlesWidget: (double value, TitleMeta meta) {
              if (limitedData.isEmpty) return const SizedBox.shrink();
              final idx = value.round().clamp(0, limitedData.length - 1);
              final date = limitedData[idx].date;
              final label = '${date.day}/${date.month}';
              return SideTitleWidget(
                axisSide: meta.axisSide,
                child: Transform.rotate(
                  angle: -math.pi / 6,
                  child: Text(
                    label,
                    style: const TextStyle(fontSize: 10),
                  ),
                ),
              );
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: yInterval,
            reservedSize: 54,
            getTitlesWidget: (double value, TitleMeta meta) {
              return Text(
                _formatYAxisLabel(value),
                style: const TextStyle(fontSize: 10),
              );
            },
          ),
        ),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border.all(color: Colors.grey.shade300),
      ),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          gradient: LinearGradient(
            colors: [color, color.withValues(alpha: 0.8)],
          ),
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) {
              return FlDotCirclePainter(
                radius: 3,
                color: color,
                strokeWidth: 2,
                strokeColor: Colors.white,
              );
            },
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [
                color.withValues(alpha: 0.3),
                color.withValues(alpha: 0.1),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ],
      minY: resolvedMinY,
      maxY: resolvedMaxY,
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (touchedSpot) => Colors.blueGrey.shade900,
          getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
            return touchedBarSpots.map((barSpot) {
              final flSpot = barSpot;
              final index = flSpot.x.toInt();
              if (index < 0 || index >= limitedData.length) return null;
              
              final dataPoint = limitedData[index];
              final dateStr = DateFormat('dd/MM HH:mm').format(dataPoint.date);
              
              return LineTooltipItem(
                '$dateStr\n',
                const TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
                children: [
                  TextSpan(
                    text: _formatYAxisLabel(flSpot.y),
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                ],
              );
            }).toList();
          },
        ),
        handleBuiltInTouches: true,
      ),
    );
  }

  double _getValueForParameter(HealthData healthData) {
    switch (parameter) {
      case 'spo2':
        return healthData.spo2.toDouble();
      case 'breathingRate':
        return healthData.breathingRate.toDouble();
      case 'pef':
        return healthData.pef;
      default:
        return 0.0;
    }
  }

  List<double> _getParameterValues() {
    return data.map((e) => _getValueForParameter(e)).toList();
  }

  String _getParameterUnit() {
    switch (parameter) {
      case 'spo2':
        return '%';
      case 'breathingRate':
        return 'bpm';
      case 'pef':
        return 'L/min';
      default:
        return '';
    }
  }

  double _getGridInterval() {
    switch (parameter) {
      case 'spo2':
        return 2.0; // Intervalles de 2%
      case 'breathingRate':
        return 2.0; // Intervalles de 2 bpm
      case 'pef':
        return 50.0; // Intervalles de 50 L/min
      default:
        return 1.0;
    }
  }

  String _formatYAxisLabel(double value) {
    switch (parameter) {
      case 'spo2':
        return '${value.toInt()}%';
      case 'breathingRate':
        return '${value.toInt()}';
      case 'pef':
        return '${value.toInt()}';
      default:
        return value.toStringAsFixed(0);
    }
  }
}