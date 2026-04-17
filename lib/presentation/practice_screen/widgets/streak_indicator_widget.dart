import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class StreakIndicatorWidget extends StatelessWidget {
  final int streak;

  const StreakIndicatorWidget({super.key, required this.streak});

  @override
  Widget build(BuildContext context) {
    String message;
    if (streak == 0) {
      message = 'Start your streak today!';
    } else if (streak < 3) {
      message = 'Great start — keep going!';
    } else if (streak < 7) {
      message = '${7 - streak} days to your first badge!';
    } else if (streak < 30) {
      message = 'Amazing consistency! 🔥';
    } else {
      message = 'Legendary streak! 🏆';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFFF6B35).withAlpha(31),
            const Color(0xFFFF9F1C).withAlpha(15),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFFF6B35).withAlpha(64),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.local_fire_department_rounded,
            color: Color(0xFFFF6B35),
            size: 20,
          ),
          const SizedBox(width: 6),
          Text(
            '$streak day streak',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: const Color(0xFFFF6B35),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 1,
            height: 14,
            color: const Color(0xFFFF6B35).withAlpha(77),
          ),
          const SizedBox(width: 8),
          Text(
            message,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: const Color(0xFFB45309),
            ),
          ),
        ],
      ),
    );
  }
}
