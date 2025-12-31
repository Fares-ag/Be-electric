import 'package:flutter/material.dart';
import '../../../utils/app_theme.dart';

class TrendAnalysisWidget extends StatelessWidget {
  const TrendAnalysisWidget({
    required this.trends,
    super.key,
  });
  final Map<String, List<double>> trends;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Trend Analysis',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          _buildTrendCard(
            context,
            'MTTR Trend',
            trends['mttrTrend'] ?? [],
            Icons.build,
            'Mean Time To Repair (hours)',
            AppTheme.primaryColor,
          ),
          const SizedBox(height: 16),
          _buildTrendCard(
            context,
            'MTBF Trend',
            trends['mtbfTrend'] ?? [],
            Icons.schedule,
            'Mean Time Between Failures (hours)',
            AppTheme.accentGreen,
          ),
          const SizedBox(height: 16),
          _buildTrendCard(
            context,
            'Cost Trend',
            trends['costTrend'] ?? [],
            Icons.attach_money,
            r'Maintenance Cost ($)',
            Colors.orange,
          ),
          const SizedBox(height: 16),
          _buildTrendCard(
            context,
            'Efficiency Trend',
            trends['efficiencyTrend'] ?? [],
            Icons.trending_up,
            'Efficiency (%)',
            AppTheme.accentGreen,
          ),
        ],
      );

  Widget _buildTrendCard(
    BuildContext context,
    String title,
    List<double> data,
    IconData icon,
    String unit,
    Color color,
  ) {
    if (data.isEmpty) {
      return Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'No trend data available',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textColor.withOpacity(0.7),
                    ),
              ),
            ],
          ),
        ),
      );
    }

    final trendDirection = _calculateTrendDirection(data);
    final averageValue = data.reduce((a, b) => a + b) / data.length;
    final latestValue = data.last;
    final change = data.length > 1 ? latestValue - data[data.length - 2] : 0.0;
    final changePercent = data.length > 1 && data[data.length - 2] != 0
        ? (change / data[data.length - 2]) * 100
        : 0.0;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                _buildTrendIndicator(context, trendDirection),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildTrendStat(
                    context,
                    'Current',
                    _formatValue(latestValue, unit),
                    color,
                  ),
                ),
                Expanded(
                  child: _buildTrendStat(
                    context,
                    'Average',
                    _formatValue(averageValue, unit),
                    AppTheme.textColor,
                  ),
                ),
                Expanded(
                  child: _buildTrendStat(
                    context,
                    'Change',
                    '${changePercent >= 0 ? '+' : ''}${changePercent.toStringAsFixed(1)}%',
                    changePercent >= 0
                        ? AppTheme.accentRed
                        : AppTheme.accentGreen,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSimpleChart(context, data, color),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendIndicator(BuildContext context, TrendDirection direction) {
    IconData icon;
    Color color;
    String label;

    switch (direction) {
      case TrendDirection.increasing:
        icon = Icons.trending_up;
        color = AppTheme.accentRed;
        label = 'Rising';
        break;
      case TrendDirection.decreasing:
        icon = Icons.trending_down;
        color = AppTheme.accentGreen;
        label = 'Falling';
        break;
      case TrendDirection.stable:
        icon = Icons.trending_flat;
        color = Colors.blue;
        label = 'Stable';
        break;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }

  Widget _buildTrendStat(
    BuildContext context,
    String label,
    String value,
    Color color,
  ) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textColor.withOpacity(0.7),
                ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      );

  Widget _buildSimpleChart(
    BuildContext context,
    List<double> data,
    Color color,
  ) {
    if (data.length < 2) {
      return Container(
        height: 60,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Text('Insufficient data for chart'),
        ),
      );
    }

    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: CustomPaint(
        painter: SimpleLineChartPainter(data, color),
        size: Size.infinite,
      ),
    );
  }

  TrendDirection _calculateTrendDirection(List<double> data) {
    if (data.length < 2) return TrendDirection.stable;

    final firstHalf = data.take(data.length ~/ 2).toList();
    final secondHalf = data.skip(data.length ~/ 2).toList();

    final firstAvg = firstHalf.reduce((a, b) => a + b) / firstHalf.length;
    final secondAvg = secondHalf.reduce((a, b) => a + b) / secondHalf.length;

    final change = secondAvg - firstAvg;
    final threshold = firstAvg * 0.05; // 5% threshold

    if (change > threshold) return TrendDirection.increasing;
    if (change < -threshold) return TrendDirection.decreasing;
    return TrendDirection.stable;
  }

  String _formatValue(double value, String unit) {
    if (unit.contains('hours')) {
      return '${value.toStringAsFixed(1)}h';
    } else if (unit.contains(r'$') ||
        unit.toLowerCase().contains('qar') ||
        unit.toLowerCase().contains('cost')) {
      return 'QAR ${value.toStringAsFixed(0)}';
    } else if (unit.contains('%')) {
      return '${value.toStringAsFixed(1)}%';
    } else {
      return value.toStringAsFixed(1);
    }
  }
}

enum TrendDirection { increasing, decreasing, stable }

class SimpleLineChartPainter extends CustomPainter {
  SimpleLineChartPainter(this.data, this.color);
  final List<double> data;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final minValue = data.reduce((a, b) => a < b ? a : b);
    final maxValue = data.reduce((a, b) => a > b ? a : b);
    final range = maxValue - minValue;

    if (range == 0) return;

    final path = Path();
    final stepX = size.width / (data.length - 1);

    for (var i = 0; i < data.length; i++) {
      final x = i * stepX;
      final normalizedValue = (data[i] - minValue) / range;
      final y = size.height - (normalizedValue * size.height);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);

    // Draw data points
    final pointPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    for (var i = 0; i < data.length; i++) {
      final x = i * stepX;
      final normalizedValue = (data[i] - minValue) / range;
      final y = size.height - (normalizedValue * size.height);

      canvas.drawCircle(Offset(x, y), 3, pointPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
