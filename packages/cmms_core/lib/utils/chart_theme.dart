import 'package:syncfusion_flutter_charts/charts.dart';

class ChartThemeUtil {
  static Legend legendRight() => const Legend(
        isVisible: true,
        position: LegendPosition.right,
        overflowMode: LegendItemOverflowMode.wrap,
      );

  static Legend legendBottom() => const Legend(
        isVisible: true,
        position: LegendPosition.bottom,
        overflowMode: LegendItemOverflowMode.wrap,
      );

  static TooltipBehavior tooltip(String format) =>
      TooltipBehavior(enable: true, format: format);

  static DateTimeAxis dateTimeXAxis() =>
      const DateTimeAxis(majorGridLines: MajorGridLines(width: 0));

  static CategoryAxis categoryXAxis() =>
      const CategoryAxis(majorGridLines: MajorGridLines(width: 0));

  static NumericAxis yAxisZero() =>
      const NumericAxis(minimum: 0, majorGridLines: MajorGridLines(width: 0));
}







