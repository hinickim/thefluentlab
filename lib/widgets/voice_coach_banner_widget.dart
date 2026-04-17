import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/chat_notifier.dart';
import '../services/voice_coach_service.dart';

/// A banner widget that displays AI voice coach messages.
/// Shows a typing indicator while loading, then reveals the coach's message.
class VoiceCoachBannerWidget extends ConsumerStatefulWidget {
  final List<Map<String, dynamic>> messages;
  final VoidCallback? onDismiss;
  final bool autoTrigger;

  const VoiceCoachBannerWidget({
    super.key,
    required this.messages,
    this.onDismiss,
    this.autoTrigger = true,
  });

  @override
  ConsumerState<VoiceCoachBannerWidget> createState() =>
      _VoiceCoachBannerWidgetState();
}

class _VoiceCoachBannerWidgetState extends ConsumerState<VoiceCoachBannerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  bool _dismissed = false;
  bool _triggered = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, -0.15), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
        );
    _animController.forward();

    if (widget.autoTrigger) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _triggerCoach();
      });
    }
  }

  void _triggerCoach() {
    if (_triggered) return;
    _triggered = true;
    ref
        .read(voiceCoachProvider.notifier)
        .sendMessage(
          widget.messages,
          parameters: {'max_completion_tokens': 120},
        );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _handleDismiss() {
    setState(() => _dismissed = true);
    widget.onDismiss?.call();
  }

  @override
  Widget build(BuildContext context) {
    if (_dismissed) return const SizedBox.shrink();

    final chatState = ref.watch(voiceCoachProvider);

    ref.listen<ChatState>(voiceCoachProvider, (previous, next) {
      if (next.error != null) {
        Fluttertoast.showToast(
          msg: 'Coach unavailable right now',
          backgroundColor: Colors.red,
          toastLength: Toast.LENGTH_SHORT,
        );
      }
    });

    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0D2B45), Color(0xFF1A3F5C)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16.0),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF4A90D9).withAlpha(60),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Coach avatar
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4A90D9), Color(0xFF9BDDFF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: const Icon(
                  Icons.record_voice_over_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Coach Aria',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF9BDDFF),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4A90D9).withAlpha(60),
                            borderRadius: BorderRadius.circular(6.0),
                          ),
                          child: Text(
                            'AI Coach',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF9BDDFF),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    chatState.isLoading
                        ? _buildTypingIndicator()
                        : Text(
                            chatState.response.isNotEmpty
                                ? chatState.response
                                : '',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              color: Colors.white.withAlpha(230),
                              height: 1.5,
                            ),
                          ),
                  ],
                ),
              ),
              if (!chatState.isLoading && chatState.response.isNotEmpty)
                GestureDetector(
                  onTap: _handleDismiss,
                  child: Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: Colors.white.withAlpha(120),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Row(
      children: [
        _DotPulse(delay: 0),
        const SizedBox(width: 4),
        _DotPulse(delay: 150),
        const SizedBox(width: 4),
        _DotPulse(delay: 300),
        const SizedBox(width: 8),
        Text(
          'Coach is thinking...',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            color: Colors.white.withAlpha(140),
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }
}

class _DotPulse extends StatefulWidget {
  final int delay;
  const _DotPulse({required this.delay});

  @override
  State<_DotPulse> createState() => _DotPulseState();
}

class _DotPulseState extends State<_DotPulse>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _anim = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _ctrl.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: Container(
        width: 6,
        height: 6,
        decoration: const BoxDecoration(
          color: Color(0xFF9BDDFF),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
