import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BadgesGridWidget extends StatefulWidget {
  final List<Map<String, dynamic>> badges;

  const BadgesGridWidget({super.key, required this.badges});

  @override
  State<BadgesGridWidget> createState() => _BadgesGridWidgetState();
}

class _BadgesGridWidgetState extends State<BadgesGridWidget>
    with TickerProviderStateMixin {
  final List<AnimationController> _controllers = [];
  final List<Animation<double>> _scaleAnims = [];
  final List<Animation<double>> _fadeAnims = [];

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < widget.badges.length; i++) {
      final ctrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 400),
      );
      _controllers.add(ctrl);
      _scaleAnims.add(
        Tween<double>(
          begin: 0.7,
          end: 1.0,
        ).animate(CurvedAnimation(parent: ctrl, curve: Curves.easeOutBack)),
      );
      _fadeAnims.add(CurvedAnimation(parent: ctrl, curve: Curves.easeOut));
      // Stagger entrance
      Future.delayed(Duration(milliseconds: 80 * i), () {
        if (mounted) ctrl.forward();
      });
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final earnedBadges = widget.badges
        .where((b) => b['earned'] as bool)
        .toList();
    final lockedBadges = widget.badges
        .where((b) => !(b['earned'] as bool))
        .toList();

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
                'Badges',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0D2B45),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFDEF0FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${earnedBadges.length} / ${widget.badges.length}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF4A90D9),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Earned badges
          if (earnedBadges.isNotEmpty) ...[
            Text(
              'EARNED',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF9CA3AF),
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 10),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.8,
              ),
              itemCount: earnedBadges.length,
              itemBuilder: (context, index) {
                final badge = earnedBadges[index];
                final globalIndex = widget.badges.indexOf(badge);
                if (globalIndex >= _scaleAnims.length) {
                  return _BadgeTile(badge: badge, isEarned: true);
                }
                return AnimatedBuilder(
                  animation: _scaleAnims[globalIndex],
                  builder: (context, child) {
                    return FadeTransition(
                      opacity: _fadeAnims[globalIndex],
                      child: ScaleTransition(
                        scale: _scaleAnims[globalIndex],
                        child: _BadgeTile(badge: badge, isEarned: true),
                      ),
                    );
                  },
                );
              },
            ),
          ],
          if (lockedBadges.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'LOCKED',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF9CA3AF),
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 10),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.8,
              ),
              itemCount: lockedBadges.length,
              itemBuilder: (context, index) {
                final badge = lockedBadges[index];
                final globalIndex = widget.badges.indexOf(badge);
                if (globalIndex >= _scaleAnims.length) {
                  return _BadgeTile(badge: badge, isEarned: false);
                }
                return AnimatedBuilder(
                  animation: _scaleAnims[globalIndex],
                  builder: (context, child) {
                    return FadeTransition(
                      opacity: _fadeAnims[globalIndex],
                      child: ScaleTransition(
                        scale: _scaleAnims[globalIndex],
                        child: _BadgeTile(badge: badge, isEarned: false),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _BadgeTile extends StatelessWidget {
  final Map<String, dynamic> badge;
  final bool isEarned;

  const _BadgeTile({required this.badge, required this.isEarned});

  @override
  Widget build(BuildContext context) {
    final color = _getBadgeColor(badge['color'] as String);
    final name = badge['name'] as String;
    final earnedDate = badge['earnedDate'] as String?;

    return GestureDetector(
      onTap: () => _showBadgeDetail(context),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: isEarned
                  ? LinearGradient(
                      colors: [color, color.withAlpha(179)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: isEarned ? null : const Color(0xFFF4F4F5),
              borderRadius: BorderRadius.circular(16),
              boxShadow: isEarned
                  ? [
                      BoxShadow(
                        color: color.withAlpha(89),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  _getBadgeIcon(badge['icon'] as String),
                  color: isEarned ? Colors.white : const Color(0xFFD1D5DB),
                  size: 26,
                ),
                if (!isEarned)
                  Positioned(
                    bottom: 4,
                    right: 4,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: const BoxDecoration(
                        color: Color(0xFF9CA3AF),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.lock_rounded,
                        color: Colors.white,
                        size: 8,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 5),
          Text(
            name,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: isEarned
                  ? const Color(0xFF0D2B45)
                  : const Color(0xFF9CA3AF),
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  void _showBadgeDetail(BuildContext context) {
    final color = _getBadgeColor(badge['color'] as String);
    final earnedDate = badge['earnedDate'] as String?;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: isEarned
                    ? LinearGradient(
                        colors: [color, color.withAlpha(179)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isEarned ? null : const Color(0xFFF4F4F5),
                borderRadius: BorderRadius.circular(20),
                boxShadow: isEarned
                    ? [
                        BoxShadow(
                          color: color.withAlpha(102),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                _getBadgeIcon(badge['icon'] as String),
                color: isEarned ? Colors.white : const Color(0xFFD1D5DB),
                size: 36,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              badge['name'] as String,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0D2B45),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              badge['description'] as String,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: const Color(0xFF6B7280),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            if (isEarned && earnedDate != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCF5E7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      color: Color(0xFF2D7A4F),
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Earned on $earnedDate',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF2D7A4F),
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F4F5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.lock_rounded,
                      color: Color(0xFF9CA3AF),
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Not yet earned',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF9CA3AF),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Color _getBadgeColor(String colorName) {
    switch (colorName) {
      case 'purple':
        return const Color(0xFF4A90D9);
      case 'orange':
        return const Color(0xFFFF6B35);
      case 'gold':
        return const Color(0xFFF59E0B);
      case 'green':
        return const Color(0xFF2D7A4F);
      case 'blue':
        return const Color(0xFF1B4FD8);
      case 'indigo':
        return const Color(0xFF4338CA);
      case 'cyan':
        return const Color(0xFF0891B2);
      case 'rose':
        return const Color(0xFFE11D48);
      default:
        return const Color(0xFF4A90D9);
    }
  }

  IconData _getBadgeIcon(String iconName) {
    switch (iconName) {
      case 'mic':
        return Icons.mic_rounded;
      case 'fire':
        return Icons.local_fire_department_rounded;
      case 'star':
        return Icons.star_rounded;
      case 'trophy':
        return Icons.emoji_events_rounded;
      case 'calendar':
        return Icons.calendar_month_rounded;
      case 'voice':
        return Icons.record_voice_over_rounded;
      case 'diamond':
        return Icons.diamond_rounded;
      case 'perfect':
        return Icons.auto_awesome_rounded;
      default:
        return Icons.star_rounded;
    }
  }
}
