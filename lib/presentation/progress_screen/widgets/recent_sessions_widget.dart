import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RecentSessionsWidget extends StatefulWidget {
  final List<Map<String, dynamic>> sessions;

  const RecentSessionsWidget({super.key, required this.sessions});

  @override
  State<RecentSessionsWidget> createState() => _RecentSessionsWidgetState();
}

class _RecentSessionsWidgetState extends State<RecentSessionsWidget>
    with TickerProviderStateMixin {
  late List<Map<String, dynamic>> _sessions;
  final List<AnimationController> _itemControllers = [];
  final List<Animation<double>> _itemFadeAnims = [];
  final List<Animation<Offset>> _itemSlideAnims = [];

  @override
  void initState() {
    super.initState();
    _sessions = List.from(widget.sessions);
    for (int i = 0; i < _sessions.length; i++) {
      final ctrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 350),
      );
      _itemControllers.add(ctrl);
      _itemFadeAnims.add(CurvedAnimation(parent: ctrl, curve: Curves.easeOut));
      _itemSlideAnims.add(
        Tween<Offset>(
          begin: const Offset(0.04, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: ctrl, curve: Curves.easeOutCubic)),
      );
      Future.delayed(Duration(milliseconds: 60 * i), () {
        if (mounted) ctrl.forward();
      });
    }
  }

  @override
  void dispose() {
    for (final c in _itemControllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
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
              Text(
                'Recent Sessions',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1035),
                ),
              ),
              const Spacer(),
              Text(
                'Last 7 days',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: const Color(0xFF9CA3AF),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (_sessions.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Column(
                  children: [
                    const Icon(
                      Icons.mic_none_rounded,
                      color: Color(0xFFD1D5DB),
                      size: 40,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No sessions yet this week',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: const Color(0xFF9CA3AF),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _sessions.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                if (index >= _itemFadeAnims.length) {
                  return _SessionItem(session: _sessions[index]);
                }
                return FadeTransition(
                  opacity: _itemFadeAnims[index],
                  child: SlideTransition(
                    position: _itemSlideAnims[index],
                    child: Dismissible(
                      key: Key(_sessions[index]['id'] as String),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFEBEB),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.delete_outline_rounded,
                          color: Color(0xFFB91C1C),
                          size: 22,
                        ),
                      ),
                      confirmDismiss: (direction) async {
                        return await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            title: Text(
                              'Remove Session?',
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            content: Text(
                              'This session record will be removed from your history.',
                              style: GoogleFonts.plusJakartaSans(fontSize: 13),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(ctx).pop(false),
                                child: const Text('Cancel'),
                              ),
                              FilledButton(
                                onPressed: () => Navigator.of(ctx).pop(true),
                                style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xFFB91C1C),
                                ),
                                child: const Text('Remove'),
                              ),
                            ],
                          ),
                        );
                      },
                      onDismissed: (_) {
                        setState(() {
                          _sessions.removeAt(index);
                          if (index < _itemControllers.length) {
                            _itemControllers[index].dispose();
                            _itemControllers.removeAt(index);
                            _itemFadeAnims.removeAt(index);
                            _itemSlideAnims.removeAt(index);
                          }
                        });
                      },
                      child: _SessionItem(session: _sessions[index]),
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

class _SessionItem extends StatelessWidget {
  final Map<String, dynamic> session;

  const _SessionItem({required this.session});

  @override
  Widget build(BuildContext context) {
    final score = session['overallScore'] as int;
    final dayLabel = session['dayLabel'] as String;
    final date = session['date'] as String;
    final sentences = session['sentencesPracticed'] as int;
    final duration = session['duration'] as String;
    final streakEarned = session['streakEarned'] as bool;
    final category = session['topCategory'] as String;

    final scoreColor = score >= 80
        ? const Color(0xFF2D7A4F)
        : score >= 65
        ? const Color(0xFF6C3CE1)
        : const Color(0xFFB45309);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F7FE),
        borderRadius: BorderRadius.circular(14),
        border: Border(left: BorderSide(color: scoreColor, width: 3)),
      ),
      child: Row(
        children: [
          // Date column
          SizedBox(
            width: 44,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  dayLabel,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A1035),
                  ),
                ),
                Text(
                  date.substring(0, 5),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    color: const Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 1,
            height: 36,
            color: const Color(0xFFE5E7EB),
            margin: const EdgeInsets.symmetric(horizontal: 12),
          ),
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '$sentences sentences',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1A1035),
                      ),
                    ),
                    const SizedBox(width: 6),
                    if (streakEarned)
                      const Icon(
                        Icons.local_fire_department_rounded,
                        color: Color(0xFFFF6B35),
                        size: 14,
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      duration,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: const Color(0xFF9CA3AF),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      width: 3,
                      height: 3,
                      decoration: const BoxDecoration(
                        color: Color(0xFFD1D5DB),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      category,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: const Color(0xFF9CA3AF),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Score
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: scoreColor.withAlpha(26),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$score',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: scoreColor,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                Text(
                  '%',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: scoreColor.withAlpha(179),
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
