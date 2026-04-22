import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import '../../utils/app_theme.dart';
import '../../utils/chart_theme.dart';

class WebAnalyticsScreen extends StatelessWidget {
  const WebAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildChartCard(
                    'Monthly Maintenance Costs',
                    _buildBarChart(),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildChartCard(
                    'Response Time Trends',
                    _buildLineChart(),
                  ),
                ),
              ],
            ),
          ],
        ),
      );

  Widget _buildChartCard(String title, Widget chart) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.darkTextColor,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(height: 300, child: chart),
          ],
        ),
      );

  Widget _buildBarChart() => SfCartesianChart(
        primaryXAxis: ChartThemeUtil.categoryXAxis(),
        primaryYAxis: ChartThemeUtil.yAxisZero(),
        tooltipBehavior: ChartThemeUtil.tooltip('point.x: QAR point.y'),
        series: <CartesianSeries<_CatPoint, String>>[
          ColumnSeries<_CatPoint, String>(
            dataSource: const [
              _CatPoint('Jan', 15),
              _CatPoint('Feb', 30),
              _CatPoint('Mar', 45),
              _CatPoint('Apr', 60),
              _CatPoint('May', 75),
              _CatPoint('Jun', 90),
            ],
            xValueMapper: (_CatPoint p, _) => p.label,
            yValueMapper: (_CatPoint p, _) => p.value,
            color: AppTheme.accentBlue,
            borderRadius: BorderRadius.circular(6),
            dataLabelSettings: const DataLabelSettings(isVisible: true),
          ),
        ],
      );

  Widget _buildLineChart() => SfCartesianChart(
        primaryXAxis: ChartThemeUtil.categoryXAxis(),
        primaryYAxis: ChartThemeUtil.yAxisZero(),
        tooltipBehavior: ChartThemeUtil.tooltip('point.x: point.y'),
        series: <CartesianSeries<_CatPoint, String>>[
          SplineSeries<_CatPoint, String>(
            dataSource: const [
              _CatPoint('W1', 3),
              _CatPoint('W2', 1),
              _CatPoint('W3', 4),
              _CatPoint('W4', 2),
              _CatPoint('W5', 5),
              _CatPoint('W6', 3),
            ],
            xValueMapper: (_CatPoint p, _) => p.label,
            yValueMapper: (_CatPoint p, _) => p.value,
            color: AppTheme.accentGreen,
            width: 3,
            markerSettings: const MarkerSettings(isVisible: true),
          ),
        ],
      );
}

class _CatPoint {
  const _CatPoint(this.label, this.value);
  final String label;
  final double value;
}
