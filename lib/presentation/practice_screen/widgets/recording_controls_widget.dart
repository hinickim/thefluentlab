import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import '../practice_screen.dart';

// TODO: Replace with Riverpod/Bloc for production state management
// TODO: Wire up actual `record` package for real audio recording
class RecordingControlsWidget extends StatefulWidget {
  final PracticeState practiceState;
  final VoidCallback onRecordingStarted;
  final VoidCallback onRecordingStopped;

  const RecordingControlsWidget({
    super.key,
    required this.practiceState,
    required this.onRecordingStarted,
    required this.onRecordingStopped,
  });

  @override
  State<RecordingControlsWidget> createState() =>
      _RecordingControlsWidgetState();
}

class _RecordingControlsWidgetState extends State<RecordingControlsWidget>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _waveController;
  late AnimationController _processingController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _processingRotation;

  final List<double> _waveHeights = List.generate(28, (i) => 0.3);
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _waveController.addListener(_updateWaveHeights);

    _processingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _processingRotation = Tween<double>(begin: 0, end: 2 * math.pi).animate(
      CurvedAnimation(parent: _processingController, curve: Curves.linear),
    );
  }

  void _updateWaveHeights() {
    if (widget.practiceState == PracticeState.recording) {
      setState(() {
        for (int i = 0; i < _waveHeights.length; i++) {
          _waveHeights[i] = 0.2 + _random.nextDouble() * 0.8;
        }
      });
    }
  }

  @override
  void didUpdateWidget(RecordingControlsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.practiceState == PracticeState.recording) {
      _pulseController.repeat(reverse: true);
      _waveController.repeat();
      _processingController.stop();
    } else if (widget.practiceState == PracticeState.processing) {
      _pulseController.stop();
      _waveController.stop();
      _processingController.repeat();
      setState(() {
        for (int i = 0; i < _waveHeights.length; i++) {
          _waveHeights[i] = 0.3;
        }
      });
    } else {
      _pulseController.stop();
      _pulseController.reset();
      _waveController.stop();
      _processingController.stop();
      setState(() {
        for (int i = 0; i < _waveHeights.length; i++) {
          _waveHeights[i] = 0.3;
        }
      });
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _waveController.dispose();
    _processingController.dispose();
    super.dispose();
  }

  void _handleMicTap() {
    if (widget.practiceState == PracticeState.idle) {
      // TODO: Request microphone permission via permission_handler on mobile
      // TODO: Initialize record package recorder
      widget.onRecordingStarted();
    } else if (widget.practiceState == PracticeState.recording) {
      // TODO: Stop recorder and save audio file
      widget.onRecordingStopped();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Waveform visualizer
        Container(
          height: 72,
          width: double.infinity,
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(_waveHeights.length, (index) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 80),
                curve: Curves.easeOut,
                width: 3,
                height: _waveHeights[index] * 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  gradient: LinearGradient(
                    colors: widget.practiceState == PracticeState.recording
                        ? [const Color(0xFF4A90D9), const Color(0xFF9BDDFF)]
                        : [const Color(0xFFB0CCE0), const Color(0xFFDEF0FF)],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 24),
        // Mic button
        Center(
          child: Column(
            children: [
              GestureDetector(
                onTap: widget.practiceState == PracticeState.processing
                    ? null
                    : _handleMicTap,
                child: AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: widget.practiceState == PracticeState.recording
                          ? _pulseAnimation.value
                          : 1.0,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          if (widget.practiceState == PracticeState.recording)
                            Container(
                              width: 96,
                              height: 96,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF4A90D9).withAlpha(38),
                              ),
                            ),
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient:
                                  widget.practiceState ==
                                      PracticeState.recording
                                  ? const LinearGradient(
                                      colors: [
                                        Color(0xFFB91C1C),
                                        Color(0xFFEF4444),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    )
                                  : widget.practiceState ==
                                        PracticeState.processing
                                  ? const LinearGradient(
                                      colors: [
                                        Color(0xFF6B7280),
                                        Color(0xFF9CA3AF),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    )
                                  : const LinearGradient(
                                      colors: [
                                        Color(0xFF4A90D9),
                                        Color(0xFF9BDDFF),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      (widget.practiceState ==
                                                  PracticeState.recording
                                              ? const Color(0xFFB91C1C)
                                              : const Color(0xFF4A90D9))
                                          .withAlpha(102),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child:
                                widget.practiceState == PracticeState.processing
                                ? AnimatedBuilder(
                                    animation: _processingRotation,
                                    builder: (context, child) {
                                      return Transform.rotate(
                                        angle: _processingRotation.value,
                                        child: const Icon(
                                          Icons.autorenew_rounded,
                                          color: Colors.white,
                                          size: 36,
                                        ),
                                      );
                                    },
                                  )
                                : Icon(
                                    widget.practiceState ==
                                            PracticeState.recording
                                        ? Icons.stop_rounded
                                        : Icons.mic_rounded,
                                    color: Colors.white,
                                    size: 36,
                                  ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Text(
                  key: ValueKey(widget.practiceState),
                  _getStateLabel(),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF6B7280),
                  ),
                ),
              ),
              if (kIsWeb && widget.practiceState == PracticeState.idle)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    'Browser microphone access required',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: const Color(0xFF9CA3AF),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  String _getStateLabel() {
    switch (widget.practiceState) {
      case PracticeState.idle:
        return 'Tap to start recording';
      case PracticeState.recording:
        return 'Recording — tap to stop';
      case PracticeState.processing:
        return 'Analyzing your speech...';
      case PracticeState.feedback:
        return 'Analysis complete!';
    }
  }
}
