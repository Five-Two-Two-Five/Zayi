import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';
import '../theme/insta_theme.dart';
import 'package:intl/intl.dart';

class TrendChart extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> data;
  final String dateKey;
  final String valueKey;
  final Color color;

  const TrendChart({
    super.key,
    required this.title,
    required this.data,
    required this.dateKey,
    required this.valueKey,
    this.color = InstaPalette.accent,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        child: Text('No trend data for $title.',
            style: const TextStyle(color: InstaPalette.textSecondary)),
      );
    }

    final spots = data.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), (e.value[valueKey] as num).toDouble());
    }).toList();

    return Container(
      height: 220,
      padding: const EdgeInsets.fromLTRB(12, 16, 20, 12),
      decoration: BoxDecoration(
        color: InstaPalette.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: InstaPalette.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: Text(title.toUpperCase(),
                style: const TextStyle(
                    fontSize: 11,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w800,
                    color: InstaPalette.textSecondary)),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: LineChart(
              LineChartData(
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (touchedSpot) => InstaPalette.textPrimary,
                    getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                      return touchedBarSpots.map((barSpot) {
                        return LineTooltipItem(
                          '\$${barSpot.y.toStringAsFixed(2)}',
                          const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12),
                        );
                      }).toList();
                    },
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 100, // Adjust based on expected data scale
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: InstaPalette.border.withValues(alpha: 0.2),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles:
                      const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles:
                      const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles:
                      const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      interval: data.length > 5
                          ? (data.length / 5).floorToDouble()
                          : 1,
                      getTitlesWidget: (value, meta) {
                        int idx = value.toInt();
                        if (idx < 0 || idx >= data.length) {
                          return const SizedBox();
                        }
                        final dateStr = data[idx][dateKey];
                        final date = DateTime.tryParse(dateStr) ?? DateTime.now();
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(DateFormat('MM/dd').format(date),
                              style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w500,
                                  color:
                                      InstaPalette.textSecondary.withValues(alpha: 0.8))),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.35,
                    gradient: LinearGradient(
                      colors: [color, color.withValues(alpha: 0.7)],
                    ),
                    barWidth: 4,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) =>
                          FlDotCirclePainter(
                        radius: 3,
                        color: Colors.white,
                        strokeWidth: 2,
                        strokeColor: color,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          color.withValues(alpha: 0.2),
                          color.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ProfitTrendChart extends ConsumerWidget {
  const ProfitTrendChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trendAsync = ref.watch(profitTrendProvider);

    return trendAsync.when(
      data: (data) => TrendChart(
        title: 'Profit Trend (Last 30 Days)',
        data: data,
        dateKey: 'date',
        valueKey: 'daily_profit',
        color: Colors.green.shade400,
      ),
      loading: () => const SizedBox(
          height: 220, child: Center(child: CircularProgressIndicator())),
      error: (e, s) => Text('Error loading chart: $e'),
    );
  }
}

class ExpenseDistributionChart extends ConsumerWidget {
  const ExpenseDistributionChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final distAsync = ref.watch(expenseDistributionProvider);

    return distAsync.when(
      data: (data) {
        if (data.isEmpty) {
          return const SizedBox(
            height: 200,
            child: Center(
                child: Text('No expense data available.',
                    style: TextStyle(color: InstaPalette.textSecondary))),
          );
        }

        final List<Color> colors = [
          const Color(0xFF6366F1), // Indigo
          const Color(0xFFEF4444), // Red
          const Color(0xFF10B981), // Emerald
          const Color(0xFFF59E0B), // Amber
          const Color(0xFF8B5CF6), // Violet
          const Color(0xFF06B6D4), // Cyan
        ];

        final sections = data.asMap().entries.map((e) {
          final val = (e.value['total'] as num).toDouble();
          return PieChartSectionData(
            color: colors[e.key % colors.length],
            value: val,
            title: '',
            radius: 45,
            showTitle: false,
            badgeWidget: _Badge(e.value['expense_type'], val, colors[e.key % colors.length]),
            badgePositionPercentageOffset: 1.4,
          );
        }).toList();

        return Container(
          height: 320,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: InstaPalette.cardBackground,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: InstaPalette.border.withValues(alpha: 0.5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('EXPENSE DISTRIBUTION',
                  style: TextStyle(
                      fontSize: 11,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w800,
                      color: InstaPalette.textSecondary)),
              const SizedBox(height: 40),
              Expanded(
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 6,
                    centerSpaceRadius: 50,
                    sections: sections,
                  ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox(
          height: 200, child: Center(child: CircularProgressIndicator())),
      error: (e, s) => Text('Error: $e'),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  const _Badge(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: InstaPalette.cardBackground,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: color)),
          Text('\$${value.toStringAsFixed(0)}',
              style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: InstaPalette.textPrimary)),
        ],
      ),
    );
  }
}
