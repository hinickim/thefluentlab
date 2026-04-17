import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FeedbackPanelWidget extends StatefulWidget {
  final Map<String, dynamic> feedbackData;
  final VoidCallback onNext;
  final VoidCallback onRetry;
  final String sentenceText;

  const FeedbackPanelWidget({
    super.key,
    required this.feedbackData,
    required this.onNext,
    required this.onRetry,
    required this.sentenceText,
  });

  @override
  State<FeedbackPanelWidget> createState() => _FeedbackPanelWidgetState();
}

class _FeedbackPanelWidgetState extends State<FeedbackPanelWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _entranceController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  // Animated score values
  double _pronunciationDisplay = 0;
  double _intonationDisplay = 0;
  double _fluencyDisplay = 0;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _fadeAnim = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutQuart,
    );
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _entranceController,
            curve: Curves.easeOutQuart,
          ),
        );

    _entranceController.forward().then((_) {
      _animateScores();
    });
  }

  void _animateScores() {
    final target1 = (widget.feedbackData['pronunciationScore'] as int)
        .toDouble();
    final target2 = (widget.feedbackData['intonationScore'] as int).toDouble();
    final target3 = (widget.feedbackData['fluencyScore'] as int).toDouble();

    const duration = Duration(milliseconds: 800);
    final start = DateTime.now();

    void update() {
      if (!mounted) return;
      final elapsed =
          DateTime.now().difference(start).inMilliseconds /
          duration.inMilliseconds;
      final t = elapsed.clamp(0.0, 1.0);
      final curve = Curves.easeOutCubic.transform(t);

      setState(() {
        _pronunciationDisplay = target1 * curve;
        _intonationDisplay = target2 * curve;
        _fluencyDisplay = target3 * curve;
      });

      if (t < 1.0) {
        WidgetsBinding.instance.addPostFrameCallback((_) => update());
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => update());
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final overall = (widget.feedbackData['overallScore'] as int);
    final tip = widget.feedbackData['tip'] as String;

    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Overall score banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _getScoreColor(overall).withAlpha(31),
                    _getScoreColor(overall).withAlpha(10),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _getScoreColor(overall).withAlpha(64),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _getScoreColor(overall).withAlpha(38),
                    ),
                    child: Center(
                      child: Text(
                        '$overall',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: _getScoreColor(overall),
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getScoreLabel(overall),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: _getScoreColor(overall),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Overall speech score',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: const Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _getScoreIcon(overall),
                    color: _getScoreColor(overall),
                    size: 28,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            // 3-metric row
            Row(
              children: [
                Expanded(
                  child: _ScoreMetricCard(
                    label: 'Pronunciation',
                    score: _pronunciationDisplay,
                    targetScore:
                        widget.feedbackData['pronunciationScore'] as int,
                    icon: Icons.record_voice_over_rounded,
                    color: const Color(0xFF4A90D9),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ScoreMetricCard(
                    label: 'Intonation',
                    score: _intonationDisplay,
                    targetScore: widget.feedbackData['intonationScore'] as int,
                    icon: Icons.graphic_eq_rounded,
                    color: const Color(0xFF1B4FD8),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ScoreMetricCard(
                    label: 'Fluency',
                    score: _fluencyDisplay,
                    targetScore: widget.feedbackData['fluencyScore'] as int,
                    icon: Icons.water_rounded,
                    color: const Color(0xFF2D7A4F),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Improvement tip
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFFB45309).withAlpha(51),
                  width: 1,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.tips_and_updates_rounded,
                    color: Color(0xFFB45309),
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Coach Tip',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFB45309),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          tip,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF92400E),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: widget.onRetry,
                    icon: const Icon(Icons.replay_rounded, size: 18),
                    label: const Text('Try Again'),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                        color: Color(0xFF4A90D9),
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      foregroundColor: const Color(0xFF4A90D9),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      textStyle: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed: widget.onNext,
                    icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                    label: const Text('Next Sentence'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF4A90D9),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      textStyle: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 90) return const Color(0xFF2D7A4F);
    if (score >= 75) return const Color(0xFF4A90D9);
    if (score >= 60) return const Color(0xFFB45309);
    return const Color(0xFFB91C1C);
  }

  String _getScoreLabel(int score) {
    if (score >= 90) return 'Excellent!';
    if (score >= 75) return 'Good job!';
    if (score >= 60) return 'Keep practicing';
    return 'Needs improvement';
  }

  IconData _getScoreIcon(int score) {
    if (score >= 90) return Icons.emoji_events_rounded;
    if (score >= 75) return Icons.thumb_up_rounded;
    if (score >= 60) return Icons.trending_up_rounded;
    return Icons.fitness_center_rounded;
  }
}

class _ScoreMetricCard extends StatelessWidget {
  final String label;
  final double score;
  final int targetScore;
  final IconData icon;
  final Color color;

  const _ScoreMetricCard({
    required this.label,
    required this.score,
    required this.targetScore,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border(left: BorderSide(color: color, width: 3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(height: 6),
          Text(
            '${score.toInt()}',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: color,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: score / 100,
              backgroundColor: color.withAlpha(31),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 3,
            ),
          ),
        ],
      ),
    );
  }
}
