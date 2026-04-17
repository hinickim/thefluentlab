import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:record/record.dart';
import 'package:sizer/sizer.dart';
import '../../../theme/app_theme.dart';
import '../../../providers/chat_notifier.dart';

enum AudioTestState { idle, recording, processing, done, error }

class AudioTestWidget extends ConsumerStatefulWidget {
  final void Function(String level, String reasoning) onLevelDetected;

  const AudioTestWidget({super.key, required this.onLevelDetected});

  @override
  ConsumerState<AudioTestWidget> createState() => _AudioTestWidgetState();
}

class _AudioTestWidgetState extends ConsumerState<AudioTestWidget>
    with SingleTickerProviderStateMixin {
  final AudioRecorder _recorder = AudioRecorder();
  AudioTestState _testState = AudioTestState.idle;
  int _recordingSeconds = 0;
  Timer? _timer;
  String _aiLevel = '';
  String _aiReasoning = '';
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  static const _config = ChatConfig(
    provider: 'OPEN_AI',
    model: 'gpt-4o',
    streaming: false,
  );

  static const String _readAloudText =
      'The quick brown fox jumps over the lazy dog. '
      'She sells seashells by the seashore. '
      'How much wood would a woodchuck chuck?';

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.18).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      Fluttertoast.showToast(
        msg: 'Microphone permission is required for the audio test.',
        backgroundColor: Colors.red,
      );
      return;
    }

    try {
      if (kIsWeb) {
        await _recorder.start(
          const RecordConfig(encoder: AudioEncoder.wav),
          path: 'voice_test.wav',
        );
      } else {
        await _recorder.start(
          const RecordConfig(encoder: AudioEncoder.aacLc),
          path: '/tmp/voice_test_${DateTime.now().millisecondsSinceEpoch}.m4a',
        );
      }

      setState(() {
        _testState = AudioTestState.recording;
        _recordingSeconds = 0;
      });

      _timer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (!mounted) return;
        setState(() => _recordingSeconds++);
        if (_recordingSeconds >= 30) _stopRecording();
      });
    } catch (_) {
      setState(() => _testState = AudioTestState.error);
    }
  }

  Future<void> _stopRecording() async {
    _timer?.cancel();
    try {
      await _recorder.stop();
      setState(() => _testState = AudioTestState.processing);
      await _analyzeWithAI();
    } catch (_) {
      setState(() => _testState = AudioTestState.error);
    }
  }

  Future<void> _analyzeWithAI() async {
    final duration = _recordingSeconds;
    final messages = [
      {
        'role': 'system',
        'content':
            'You are an expert speech and voice coach. A user just completed a voice recording exercise during onboarding for a voice coaching app. '
            'Based on the exercise they performed and the recording duration, assess their likely speaking level. '
            'Respond ONLY with a JSON object in this exact format: {"level": "Beginner|Intermediate|Advanced", "reasoning": "one sentence explanation"}. '
            'No markdown, no extra text.',
      },
      {
        'role': 'user',
        'content':
            'The user read the following passage aloud: "$_readAloudText"\n\n'
            'Recording duration: $duration seconds.\n'
            'A very short recording (under 5 seconds) suggests hesitation or beginner level. '
            '5-15 seconds suggests intermediate comfort. '
            'Over 15 seconds with a full reading suggests advanced fluency. '
            'Please assess their level.',
      },
    ];

    ref
        .read(chatNotifierProvider(_config).notifier)
        .sendMessage(messages, parameters: {'max_completion_tokens': 200});
  }

  void _retry() {
    setState(() {
      _testState = AudioTestState.idle;
      _recordingSeconds = 0;
      _aiLevel = '';
      _aiReasoning = '';
    });
  }

  void _parseAIResponse(String response) {
    try {
      final cleaned = response
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();
      final json = jsonDecode(cleaned) as Map<String, dynamic>;
      final level = json['level'] as String? ?? 'Beginner';
      final reasoning = json['reasoning'] as String? ?? '';
      final validLevel =
          ['Beginner', 'Intermediate', 'Advanced'].contains(level)
          ? level
          : 'Beginner';
      setState(() {
        _aiLevel = validLevel;
        _aiReasoning = reasoning;
        _testState = AudioTestState.done;
      });
      widget.onLevelDetected(validLevel, reasoning);
    } catch (_) {
      setState(() => _testState = AudioTestState.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<ChatState>(chatNotifierProvider(_config), (prev, next) {
      if (next.error != null && _testState == AudioTestState.processing) {
        setState(() => _testState = AudioTestState.error);
        Fluttertoast.showToast(
          msg: 'Could not analyze recording. You can skip this step.',
          backgroundColor: Colors.orange,
        );
      }
      if (prev?.isLoading == true &&
          !next.isLoading &&
          next.response.isNotEmpty) {
        _parseAIResponse(next.response);
      }
    });

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 2.h),
          Text(
            'Voice Level Test',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          SizedBox(height: 0.5.h),
          Text(
            'Record yourself reading the passage below. Our AI will identify your speaking level.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.sp,
              color: AppTheme.textSecondary,
            ),
          ),
          SizedBox(height: 2.5.h),
          _buildReadAloudCard(),
          SizedBox(height: 2.5.h),
          _buildRecordingSection(),
          SizedBox(height: 2.h),
        ],
      ),
    );
  }

  Widget _buildReadAloudCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.primaryContainer,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: AppTheme.primary.withAlpha(77), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withAlpha(26),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: const Icon(
                  Icons.menu_book_rounded,
                  color: AppTheme.primary,
                  size: 18,
                ),
              ),
              SizedBox(width: 2.w),
              Text(
                'Read this aloud:',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primary,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.5.h),
          Text(
            _readAloudText,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13.sp,
              color: AppTheme.textPrimary,
              height: 1.6,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordingSection() {
    switch (_testState) {
      case AudioTestState.idle:
        return _buildIdleState();
      case AudioTestState.recording:
        return _buildRecordingState();
      case AudioTestState.processing:
        return _buildProcessingState();
      case AudioTestState.done:
        return _buildDoneState();
      case AudioTestState.error:
        return _buildErrorState();
    }
  }

  Widget _buildIdleState() {
    return Column(
      children: [
        Center(
          child: GestureDetector(
            onTap: _startRecording,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withAlpha(77),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(
                Icons.mic_rounded,
                color: Colors.white,
                size: 36,
              ),
            ),
          ),
        ),
        SizedBox(height: 1.5.h),
        Center(
          child: Text(
            'Tap to start recording',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
        SizedBox(height: 0.5.h),
        Center(
          child: Text(
            'Max 30 seconds',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11.sp,
              color: AppTheme.textMuted,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecordingState() {
    return Column(
      children: [
        Center(
          child: ScaleTransition(
            scale: _pulseAnimation,
            child: GestureDetector(
              onTap: _stopRecording,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppTheme.error,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.error.withAlpha(100),
                      blurRadius: 24,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.stop_rounded,
                  color: Colors.white,
                  size: 36,
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: 1.5.h),
        Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppTheme.error,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 1.5.w),
              Text(
                'Recording... ${_recordingSeconds}s',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.error,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 0.5.h),
        Center(
          child: Text(
            'Tap the button to stop',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11.sp,
              color: AppTheme.textMuted,
            ),
          ),
        ),
        SizedBox(height: 2.h),
        ClipRRect(
          borderRadius: BorderRadius.circular(4.0),
          child: LinearProgressIndicator(
            value: _recordingSeconds / 30,
            backgroundColor: AppTheme.surfaceVariant,
            valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.error),
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  Widget _buildProcessingState() {
    return Column(
      children: [
        Center(
          child: Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              color: AppTheme.warningContainer,
              shape: BoxShape.circle,
            ),
            child: const Padding(
              padding: EdgeInsets.all(22),
              child: CircularProgressIndicator(
                color: AppTheme.warning,
                strokeWidth: 3,
              ),
            ),
          ),
        ),
        SizedBox(height: 1.5.h),
        Center(
          child: Text(
            'Analyzing your voice...',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
        SizedBox(height: 0.5.h),
        Center(
          child: Text(
            'Our AI coach is assessing your level',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11.sp,
              color: AppTheme.textMuted,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDoneState() {
    final levelColor = _aiLevel == 'Beginner'
        ? AppTheme.success
        : _aiLevel == 'Intermediate'
        ? AppTheme.warning
        : AppTheme.secondary;

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            color: levelColor.withAlpha(20),
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(color: levelColor.withAlpha(77), width: 1.5),
          ),
          child: Column(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: levelColor.withAlpha(26),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle_rounded,
                  color: levelColor,
                  size: 30,
                ),
              ),
              SizedBox(height: 1.5.h),
              Text(
                'AI Detected Level: $_aiLevel',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                  color: levelColor,
                ),
              ),
              SizedBox(height: 0.8.h),
              Text(
                _aiReasoning,
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.sp,
                  color: AppTheme.textSecondary,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 2.h),
        TextButton.icon(
          onPressed: _retry,
          icon: const Icon(Icons.refresh_rounded, size: 16),
          label: Text(
            'Record again',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
          style: TextButton.styleFrom(foregroundColor: AppTheme.textSecondary),
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Column(
      children: [
        Center(
          child: Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              color: AppTheme.errorContainer,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.error_outline_rounded,
              color: AppTheme.error,
              size: 36,
            ),
          ),
        ),
        SizedBox(height: 1.5.h),
        Center(
          child: Text(
            'Something went wrong',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
        SizedBox(height: 0.5.h),
        Center(
          child: Text(
            'Tap below to try again or skip this step.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11.sp,
              color: AppTheme.textMuted,
            ),
          ),
        ),
        SizedBox(height: 2.h),
        TextButton.icon(
          onPressed: _retry,
          icon: const Icon(Icons.refresh_rounded, size: 16),
          label: Text(
            'Try again',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
          style: TextButton.styleFrom(foregroundColor: AppTheme.primary),
        ),
      ],
    );
  }
}
