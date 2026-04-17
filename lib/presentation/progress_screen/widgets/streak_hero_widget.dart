import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class StreakHeroWidget extends StatefulWidget {
  final int currentStreak;
  final int longestStreak;
  final int totalSessions;
  final double weeklyAvgScore;

  const StreakHeroWidget({
    super.key,
    required this.currentStreak,
    required this.longestStreak,
    required this.totalSessions,
    required this.weeklyAvgScore,
  });

  @override
  State<StreakHeroWidget> createState() => _StreakHeroWidgetState();
}

class _StreakHeroWidgetState extends State<StreakHeroWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _flameController;
  late Animation<double> _flameScale;
  double _displayedStreak = 0;

  @override
  void initState() {
    super.initState();
    _flameController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _flameScale = Tween<double>(begin: 0.85, end: 1.05).animate(
      CurvedAnimation(parent: _flameController, curve: Curves.easeInOut),
    );
    _flameController.repeat(reverse: true);

    // Animate streak counter
    _animateStreakCounter();
  }

  void _animateStreakCounter() {
    final target = widget.currentStreak.toDouble();
    const duration = Duration(milliseconds: 1000);
    final start = DateTime.now();

    void update() {
      if (!mounted) return;
      final elapsed =
          DateTime.now().difference(start).inMilliseconds /
          duration.inMilliseconds;
      final t = elapsed.clamp(0.0, 1.0);
      final curve = Curves.easeOutCubic.transform(t);

      setState(() => _displayedStreak = target * curve);

      if (t < 1.0) {
        WidgetsBinding.instance.addPostFrameCallback((_) => update());
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => update());
  }

  @override
  void dispose() {
    _flameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4A90D9), Color(0xFF9BDDFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4A90D9).withAlpha(89),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Streak count
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current Streak',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        AnimatedBuilder(
                          animation: _flameScale,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _flameScale.value,
                              child: const Icon(
                                Icons.local_fire_department_rounded,
                                color: Color(0xFFFF9F1C),
                                size: 36,
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${_displayedStreak.toInt()}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 48,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            height: 1.0,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                        const SizedBox(width: 4),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            'days',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.white70,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Streak stars row
                    Row(
                      children: List.generate(7, (index) {
                        final isEarned = index < widget.currentStreak;
                        return Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Icon(
                            isEarned
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            color: isEarned
                                ? const Color(0xFFF59E0B)
                                : Colors.white30,
                            size: 18,
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${7 - widget.currentStreak} more days to first milestone!',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: Colors.white60,
                      ),
                    ),
                  ],
                ),
              ),
              // Today status
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(38),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      color: Color(0xFF86EFAC),
                      size: 28,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Today',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Complete',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Stats row
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(31),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _StatItem(
                    value: '${widget.longestStreak}',
                    label: 'Best Streak',
                    icon: Icons.emoji_events_rounded,
                  ),
                ),
                Container(width: 1, height: 32, color: Colors.white24),
                Expanded(
                  child: _StatItem(
                    value: '${widget.totalSessions}',
                    label: 'Sessions',
                    icon: Icons.mic_rounded,
                  ),
                ),
                Container(width: 1, height: 32, color: Colors.white24),
                Expanded(
                  child: _StatItem(
                    value: '${widget.weeklyAvgScore.toStringAsFixed(0)}%',
                    label: 'Weekly Avg',
                    icon: Icons.trending_up_rounded,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;

  const _StatItem({
    required this.value,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 16),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10,
            color: Colors.white60,
          ),
        ),
      ],
    );
  }
}
