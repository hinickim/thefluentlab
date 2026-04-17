import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SessionProgressWidget extends StatelessWidget {
  final int completedCount;
  final int total;
  final bool compact;

  const SessionProgressWidget({
    super.key,
    required this.completedCount,
    required this.total,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F4FF),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$completedCount/$total',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF4A90D9),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 16),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          Row(
            children: [
              Text(
                'Session Progress',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0D2B45),
                ),
              ),
              const Spacer(),
              Text(
                '$completedCount of $total practices',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF6B7280),
                ),
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.star_rounded,
                color: Color(0xFFF59E0B),
                size: 16,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: List.generate(total, (index) {
              final isDone = index < completedCount;
              final isCurrent = index == completedCount;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: index < total - 1 ? 6 : 0),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    height: 8,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: isDone
                          ? const Color(0xFF4A90D9)
                          : isCurrent
                          ? const Color(0xFF4A90D9).withAlpha(77)
                          : const Color(0xFFE8F4FF),
                      boxShadow: isDone
                          ? [
                              BoxShadow(
                                color: const Color(0xFF4A90D9).withAlpha(77),
                                blurRadius: 4,
                              ),
                            ]
                          : null,
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          Text(
            completedCount >= total
                ? '🎉 Session complete! Streak star earned!'
                : 'Complete ${total - completedCount} more to earn a streak ⭐',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }
}
