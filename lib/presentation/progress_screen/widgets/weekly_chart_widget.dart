import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';

class WeeklyChartWidget extends StatefulWidget {
  final List<Map<String, dynamic>> weeklyScores;

  const WeeklyChartWidget({super.key, required this.weeklyScores});

  @override
  State<WeeklyChartWidget> createState() => _WeeklyChartWidgetState();
}

class _WeeklyChartWidgetState extends State<WeeklyChartWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _chartEntranceController;
  late Animation<double> _chartAnimation;
  int? _touchedIndex;

  @override
  void initState() {
    super.initState();
    _chartEntranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _chartAnimation = CurvedAnimation(
      parent: _chartEntranceController,
      curve: Curves.easeOutCubic,
    );
    _chartEntranceController.forward();
  }

  @override
  void dispose() {
    _chartEntranceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scores = widget.weeklyScores;
    final validScores = scores
        .where((s) => (s['score'] as double) > 0)
        .map((s) => s['score'] as double)
        .toList();
    final avgScore = validScores.isEmpty
        ? 0.0
        : validScores.reduce((a, b) => a + b) / validScores.length;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '7-Day Accuracy',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1A1035),
                    ),
                  ),
                  Text(
                    'Updated Mar 28, 2026',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: const Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEDE7FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.trending_up_rounded,
                      color: Color(0xFF6C3CE1),
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Avg ${avgScore.toStringAsFixed(0)}%',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF6C3CE1),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          AnimatedBuilder(
            animation: _chartAnimation,
            builder: (context, child) {
              return SizedBox(
                height: 180,
                child: LineChart(
                  LineChartData(
                    minY: 40,
                    maxY: 100,
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: 20,
                      getDrawingHorizontalLine: (_) => FlLine(
                        color: const Color(0xFFF4F1FF),
                        strokeWidth: 1,
                        dashArray: [4, 4],
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: 20,
                          reservedSize: 32,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              '${value.toInt()}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                color: const Color(0xFF9CA3AF),
                              ),
                            );
                          },
                        ),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 28,
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            if (index < 0 || index >= scores.length) {
                              return const SizedBox.shrink();
                            }
                            return Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                scores[index]['day'] as String,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: _touchedIndex == index
                                      ? FontWeight.w700
                                      : FontWeight.w400,
                                  color: _touchedIndex == index
                                      ? const Color(0xFF6C3CE1)
                                      : const Color(0xFF9CA3AF),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    lineTouchData: LineTouchData(
                      touchCallback: (event, response) {
                        setState(() {
                          if (response?.lineBarSpots != null &&
                              response!.lineBarSpots!.isNotEmpty) {
                            _touchedIndex = response.lineBarSpots!.first.x
                                .toInt();
                          } else {
                            _touchedIndex = null;
                          }
                        });
                      },
                      touchTooltipData: LineTouchTooltipData(
                        tooltipRoundedRadius: 10,
                        tooltipBgColor: const Color(0xFF1A1035),
                        getTooltipItems: (touchedBarSpots) {
                          return touchedBarSpots.map((spot) {
                            final index = spot.x.toInt();
                            final score = spot.y.toInt();
                            final day = index < scores.length
                                ? scores[index]['day'] as String
                                : '';
                            return LineTooltipItem(
                              '$day\n$score%',
                              GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            );
                          }).toList();
                        },
                      ),
                    ),
                    lineBarsData: [
                      LineChartBarData(
                        spots: List.generate(scores.length, (i) {
                          final score = scores[i]['score'] as double;
                          final animatedScore = score > 0
                              ? 40 + (score - 40) * _chartAnimation.value
                              : 0.0;
                          return FlSpot(
                            i.toDouble(),
                            score > 0 ? animatedScore : double.nan,
                          );
                        }),
                        isCurved: true,
                        curveSmoothness: 0.3,
                        color: const Color(0xFF6C3CE1),
                        barWidth: 2.5,
                        isStrokeCapRound: true,
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, barData, index) {
                            final isTouched = _touchedIndex == index;
                            return FlDotCirclePainter(
                              radius: isTouched ? 6 : 3.5,
                              color: Colors.white,
                              strokeWidth: isTouched ? 3 : 2,
                              strokeColor: const Color(0xFF6C3CE1),
                            );
                          },
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF6C3CE1).withAlpha(64),
                              const Color(0xFF6C3CE1).withAlpha(0),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}