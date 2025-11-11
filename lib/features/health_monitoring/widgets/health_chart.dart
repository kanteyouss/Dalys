import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../data/models/health_data.dart';

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
                _buildChartData(),
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

  LineChartData _buildChartData() {
    final spots = <FlSpot>[];
    final limitedData = data.length > 20 ? data.sublist(data.length - 20) : data;

    for (int i = 0; i < limitedData.length; i++) {
      final value = _getValueForParameter(limitedData[i]);
      spots.add(FlSpot(i.toDouble(), value));
    }

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: _getGridInterval(),
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
            reservedSize: 30,
            interval: (limitedData.length / 4).ceil().toDouble(),
            getTitlesWidget: (double value, TitleMeta meta) {
              if (value.toInt() >= limitedData.length) return const SizedBox.shrink();
              final index = value.toInt();
              final date = limitedData[index].date;
              return SideTitleWidget(
                axisSide: meta.axisSide,
                child: Text(
                  '${date.day}/${date.month}',
                  style: const TextStyle(fontSize: 10),
                ),
              );
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: _getGridInterval(),
            reservedSize: 50,
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
      minY: minY,
      maxY: maxY,
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
