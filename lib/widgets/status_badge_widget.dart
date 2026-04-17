import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum BadgeStatus { excellent, good, needsWork, perfect, inProgress }

class StatusBadgeWidget extends StatelessWidget {
  final BadgeStatus status;
  final String? customLabel;

  const StatusBadgeWidget({super.key, required this.status, this.customLabel});

  @override
  Widget build(BuildContext context) {
    final config = _badgeConfig(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: config.backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        customLabel ?? config.label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: config.textColor,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  _BadgeConfig _badgeConfig(BadgeStatus s) {
    switch (s) {
      case BadgeStatus.perfect:
        return _BadgeConfig(
          'Perfect',
          const Color(0xFFDCF5E7),
          const Color(0xFF2D7A4F),
        );
      case BadgeStatus.excellent:
        return _BadgeConfig(
          'Excellent',
          const Color(0xFFEDE7FF),
          const Color(0xFF6C3CE1),
        );
      case BadgeStatus.good:
        return _BadgeConfig(
          'Good',
          const Color(0xFFFFF3E0),
          const Color(0xFFB45309),
        );
      case BadgeStatus.needsWork:
        return _BadgeConfig(
          'Needs Work',
          const Color(0xFFFFEBEB),
          const Color(0xFFB91C1C),
        );
      case BadgeStatus.inProgress:
        return _BadgeConfig(
          'In Progress',
          const Color(0xFFF4F1FF),
          const Color(0xFF6C3CE1),
        );
    }
  }
}

class _BadgeConfig {
  final String label;
  final Color backgroundColor;
  final Color textColor;
  const _BadgeConfig(this.label, this.backgroundColor, this.textColor);
}
