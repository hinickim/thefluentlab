import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../practice_screen.dart';

class SentencePromptWidget extends StatefulWidget {
  final Map<String, dynamic> sentenceData;
  final List<String> highlightedWords;
  final PracticeState practiceState;

  const SentencePromptWidget({
    super.key,
    required this.sentenceData,
    required this.highlightedWords,
    required this.practiceState,
  });

  @override
  State<SentencePromptWidget> createState() => _SentencePromptWidgetState();
}

class _SentencePromptWidgetState extends State<SentencePromptWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _entranceController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutQuart,
    );
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _entranceController,
            curve: Curves.easeOutQuart,
          ),
        );
    _entranceController.forward();
  }

  @override
  void didUpdateWidget(SentencePromptWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sentenceData['id'] != widget.sentenceData['id']) {
      _entranceController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sentence = widget.sentenceData['text'] as String;
    final difficulty = widget.sentenceData['difficulty'] as String;
    final focus = widget.sentenceData['focus'] as String;
    final category = widget.sentenceData['category'] as String;

    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border(
              left: BorderSide(width: 4, color: _getCategoryColor(category)),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6C3CE1).withAlpha(20),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: _getCategoryColor(category).withAlpha(31),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _getCategoryLabel(category),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: _getCategoryColor(category),
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: _getDifficultyColor(difficulty).withAlpha(31),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        difficulty.toUpperCase(),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: _getDifficultyColor(difficulty),
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.volume_up_rounded,
                      color: const Color(0xFF6C3CE1).withAlpha(128),
                      size: 20,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildHighlightedText(sentence),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F1FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.lightbulb_outline_rounded,
                        color: Color(0xFF6C3CE1),
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Focus: $focus',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF6C3CE1),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.practiceState == PracticeState.recording) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCF5E7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Color(0xFF2D7A4F),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Recording... speak clearly',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF2D7A4F),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHighlightedText(String sentence) {
    if (widget.highlightedWords.isEmpty) {
      return Text(
        sentence,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF1A1035),
          height: 1.6,
        ),
      );
    }

    final words = sentence.split(' ');
    final spans = <TextSpan>[];

    for (int i = 0; i < words.length; i++) {
      final word = words[i];
      final cleanWord = word.replaceAll(RegExp(r'[^\w]'), '').toLowerCase();
      final isHighlighted = widget.highlightedWords.any(
        (w) => w.toLowerCase() == cleanWord,
      );

      spans.add(
        TextSpan(
          text: i < words.length - 1 ? '$word ' : word,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: isHighlighted ? FontWeight.w700 : FontWeight.w600,
            color: isHighlighted
                ? const Color(0xFFB91C1C)
                : const Color(0xFF1A1035),
            backgroundColor: isHighlighted
                ? const Color(0xFFFFEBEB)
                : Colors.transparent,
            height: 1.6,
          ),
        ),
      );
    }

    return RichText(text: TextSpan(children: spans));
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'tongue_twister':
        return const Color(0xFF6C3CE1);
      case 'professional':
        return const Color(0xFF1B4FD8);
      case 'natural_speech':
        return const Color(0xFF2D7A4F);
      default:
        return const Color(0xFF6C3CE1);
    }
  }

  String _getCategoryLabel(String category) {
    switch (category) {
      case 'tongue_twister':
        return 'TONGUE TWISTER';
      case 'professional':
        return 'PROFESSIONAL';
      case 'natural_speech':
        return 'NATURAL SPEECH';
      default:
        return 'PRACTICE';
    }
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty) {
      case 'easy':
        return const Color(0xFF2D7A4F);
      case 'medium':
        return const Color(0xFFB45309);
      case 'hard':
        return const Color(0xFFB91C1C);
      default:
        return const Color(0xFF6B7280);
    }
  }
}
