import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_export.dart';
import '../../services/supabase_service.dart';
import '../../services/voice_coach_service.dart';
import '../../widgets/voice_coach_banner_widget.dart';
import './widgets/feedback_panel_widget.dart';
import './widgets/recording_controls_widget.dart';
import './widgets/sentence_prompt_widget.dart';
import './widgets/session_progress_widget.dart';
import './widgets/streak_indicator_widget.dart';

// TODO: Replace with Riverpod/Bloc for production state management

enum PracticeState { idle, recording, processing, feedback }

class PracticeScreen extends ConsumerStatefulWidget {
  const PracticeScreen({super.key});

  @override
  ConsumerState<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends ConsumerState<PracticeScreen>
    with TickerProviderStateMixin {
  PracticeState _practiceState = PracticeState.idle;
  int _currentSentenceIndex = 0;
  int _sessionCompletedCount = 0;
  int _currentStreak = 7;
  bool _sessionComplete = false;
  bool _showSessionStartCoach = true;
  bool _showFeedbackCoach = false;
  int _lastFeedbackScore = 0;

  // Dynamic exercises fetched from Supabase
  List<Map<String, dynamic>> _sentenceMaps = [];
  bool _isLoadingExercises = true;
  String? _exercisesError;

  late AnimationController _pageEntranceController;
  late Animation<double> _pageFadeAnimation;
  late Animation<Offset> _pageSlideAnimation;

  // TODO: Replace with AI-generated feedback from backend
  final Map<String, dynamic> _mockFeedbackMap = {
    'pronunciationScore': 78,
    'intonationScore': 85,
    'fluencyScore': 71,
    'overallScore': 78,
    'tip':
        'Focus on the "ch" sound — keep the tip of your tongue behind upper teeth.',
    'highlightedWords': ['woodchuck', 'chuck', 'would'],
    'status': 'good',
  };

  @override
  void initState() {
    super.initState();
    _pageEntranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _pageFadeAnimation = CurvedAnimation(
      parent: _pageEntranceController,
      curve: Curves.easeOutQuart,
    );
    _pageSlideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _pageEntranceController,
            curve: Curves.easeOutQuart,
          ),
        );
    _pageEntranceController.forward();
    _fetchExercises();
  }

  Future<void> _fetchExercises() async {
    try {
      setState(() {
        _isLoadingExercises = true;
        _exercisesError = null;
      });

      final client = SupabaseService.instance.client;
      final response = await client
          .from('exercises')
          .select(
            'id, text, difficulty, focus, exercise_categories(name, slug)',
          )
          .eq('is_active', true)
          .order('created_at');

      final exercises = (response as List).map((row) {
        final category = row['exercise_categories'] as Map<String, dynamic>?;
        return {
          'id': row['id'] as String,
          'text': row['text'] as String,
          'difficulty': row['difficulty'] as String? ?? 'medium',
          'focus': row['focus'] as String? ?? '',
          'category': category?['slug'] as String? ?? 'general',
        };
      }).toList();

      if (mounted) {
        setState(() {
          _sentenceMaps = exercises;
          _isLoadingExercises = false;
          _currentSentenceIndex = 0;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _exercisesError = 'Failed to load exercises. Please try again.';
          _isLoadingExercises = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _pageEntranceController.dispose();
    super.dispose();
  }

  void _onRecordingStarted() {
    setState(() {
      _practiceState = PracticeState.recording;
      _showSessionStartCoach = false;
      _showFeedbackCoach = false;
    });
  }

  void _onRecordingStopped() {
    setState(() => _practiceState = PracticeState.processing);
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (mounted) {
        setState(() {
          _practiceState = PracticeState.feedback;
          _showFeedbackCoach = true;
          _lastFeedbackScore = _mockFeedbackMap['overallScore'] as int;
        });
      }
    });
  }

  void _onNextSentence() {
    setState(() {
      _showFeedbackCoach = false;
      _sessionCompletedCount = (_sessionCompletedCount + 1).clamp(0, 5);
      if (_sessionCompletedCount >= 5) {
        _sessionComplete = true;
        _currentStreak += 1;
        _showStreakEarnedDialog();
        return;
      }
      _currentSentenceIndex =
          (_currentSentenceIndex + 1) % _sentenceMaps.length;
      _practiceState = PracticeState.idle;
    });
  }

  void _onRetry() {
    setState(() {
      _practiceState = PracticeState.idle;
      _showFeedbackCoach = false;
    });
  }

  void _onSkipSentence() {
    setState(() {
      _showFeedbackCoach = false;
      _currentSentenceIndex =
          (_currentSentenceIndex + 1) % _sentenceMaps.length;
      _practiceState = PracticeState.idle;
    });
  }

  void _showStreakEarnedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _StreakEarnedDialog(
        streak: _currentStreak,
        onContinue: () {
          Navigator.of(ctx).pop();
          setState(() {
            _sessionCompletedCount = 0;
            _sessionComplete = false;
            _currentSentenceIndex = 0;
            _practiceState = PracticeState.idle;
            _showSessionStartCoach = true;
          });
        },
        onViewProgress: () {
          Navigator.of(ctx).pop();
          Navigator.pushNamed(context, AppRoutes.progressScreen);
        },
      ),
    );
  }

  bool get _isTablet => MediaQuery.of(context).size.width >= 600;

  List<Map<String, dynamic>> get _currentCoachMessages {
    if (_showFeedbackCoach && _sentenceMaps.isNotEmpty) {
      final sentence = _sentenceMaps[_currentSentenceIndex];
      return VoiceCoachService.feedbackMessages(
        sentenceText: sentence['text'] as String,
        overallScore: _lastFeedbackScore,
        tip: _mockFeedbackMap['tip'] as String,
        highlightedWords: List<String>.from(
          _mockFeedbackMap['highlightedWords'] as List,
        ),
      );
    }
    return VoiceCoachService.sessionStartMessages();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoadingExercises) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        body: SafeArea(
          child: Column(
            children: [
              _buildGradientAppBar(theme),
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(color: Color(0xFF4A90D9)),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: AppNavigation(currentIndex: 0, onTap: (_) {}),
      );
    }

    if (_exercisesError != null || _sentenceMaps.isEmpty) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        body: SafeArea(
          child: Column(
            children: [
              _buildGradientAppBar(theme),
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.library_books_outlined,
                          size: 56,
                          color: Color(0xFF4A90D9),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _exercisesError ?? 'No exercises available yet.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFF6B7280),
                          ),
                        ),
                        const SizedBox(height: 20),
                        FilledButton.icon(
                          onPressed: _fetchExercises,
                          icon: const Icon(Icons.refresh_rounded, size: 18),
                          label: const Text('Retry'),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF4A90D9),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: AppNavigation(currentIndex: 0, onTap: (_) {}),
      );
    }

    final currentSentence = _sentenceMaps[_currentSentenceIndex];

    return Scaffold(
      backgroundColor: AppTheme.background,
      extendBody: true,
      body: SafeArea(
        bottom: false,
        child: FadeTransition(
          opacity: _pageFadeAnimation,
          child: SlideTransition(
            position: _pageSlideAnimation,
            child: _isTablet
                ? _buildTabletLayout(theme, currentSentence)
                : _buildPhoneLayout(theme, currentSentence),
          ),
        ),
      ),
      bottomNavigationBar: AppNavigation(currentIndex: 0, onTap: (_) {}),
    );
  }

  Widget _buildPhoneLayout(ThemeData theme, Map<String, dynamic> sentence) {
    return Column(
      children: [
        _buildGradientAppBar(theme),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(
              left: 16,
              right: 16,
              top: 8,
              bottom: 120,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Voice Coach Banner
                if (_showSessionStartCoach || _showFeedbackCoach)
                  VoiceCoachBannerWidget(
                    key: ValueKey(
                      _showFeedbackCoach
                          ? 'feedback_$_currentSentenceIndex'
                          : 'session_start',
                    ),
                    messages: _currentCoachMessages,
                    onDismiss: () => setState(() {
                      _showSessionStartCoach = false;
                      _showFeedbackCoach = false;
                    }),
                  ),
                StreakIndicatorWidget(streak: _currentStreak),
                const SizedBox(height: 12),
                SessionProgressWidget(
                  completedCount: _sessionCompletedCount,
                  total: 5,
                ),
                const SizedBox(height: 16),
                SentencePromptWidget(
                  sentenceData: sentence,
                  highlightedWords: _practiceState == PracticeState.feedback
                      ? List<String>.from(
                          _mockFeedbackMap['highlightedWords'] as List,
                        )
                      : [],
                  practiceState: _practiceState,
                ),
                if (_practiceState == PracticeState.idle ||
                    _practiceState == PracticeState.recording)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: _onSkipSentence,
                      icon: const Icon(
                        Icons.skip_next_rounded,
                        size: 16,
                        color: Color(0xFF4A90D9),
                      ),
                      label: const Text(
                        'Skip',
                        style: TextStyle(
                          color: Color(0xFF4A90D9),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ),
                const SizedBox(height: 20),
                RecordingControlsWidget(
                  practiceState: _practiceState,
                  onRecordingStarted: _onRecordingStarted,
                  onRecordingStopped: _onRecordingStopped,
                ),
                if (_practiceState == PracticeState.feedback) ...[
                  const SizedBox(height: 20),
                  FeedbackPanelWidget(
                    feedbackData: _mockFeedbackMap,
                    onNext: _onNextSentence,
                    onRetry: _onRetry,
                    sentenceText: sentence['text'] as String,
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTabletLayout(ThemeData theme, Map<String, dynamic> sentence) {
    return Column(
      children: [
        _buildGradientAppBar(theme),
        Expanded(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(
                  left: 24,
                  right: 24,
                  top: 12,
                  bottom: 120,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Voice Coach Banner
                    if (_showSessionStartCoach || _showFeedbackCoach)
                      VoiceCoachBannerWidget(
                        key: ValueKey(
                          _showFeedbackCoach
                              ? 'feedback_$_currentSentenceIndex'
                              : 'session_start',
                        ),
                        messages: _currentCoachMessages,
                        onDismiss: () => setState(() {
                          _showSessionStartCoach = false;
                          _showFeedbackCoach = false;
                        }),
                      ),
                    Row(
                      children: [
                        Expanded(
                          child: StreakIndicatorWidget(streak: _currentStreak),
                        ),
                        const SizedBox(width: 12),
                        SessionProgressWidget(
                          completedCount: _sessionCompletedCount,
                          total: 5,
                          compact: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SentencePromptWidget(
                      sentenceData: sentence,
                      highlightedWords: _practiceState == PracticeState.feedback
                          ? List<String>.from(
                              _mockFeedbackMap['highlightedWords'] as List,
                            )
                          : [],
                      practiceState: _practiceState,
                    ),
                    if (_practiceState == PracticeState.idle ||
                        _practiceState == PracticeState.recording)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: _onSkipSentence,
                          icon: const Icon(
                            Icons.skip_next_rounded,
                            size: 16,
                            color: Color(0xFF4A90D9),
                          ),
                          label: const Text(
                            'Skip',
                            style: TextStyle(
                              color: Color(0xFF4A90D9),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ),
                    const SizedBox(height: 24),
                    RecordingControlsWidget(
                      practiceState: _practiceState,
                      onRecordingStarted: _onRecordingStarted,
                      onRecordingStopped: _onRecordingStopped,
                    ),
                    if (_practiceState == PracticeState.feedback) ...[
                      const SizedBox(height: 24),
                      FeedbackPanelWidget(
                        feedbackData: _mockFeedbackMap,
                        onNext: _onNextSentence,
                        onRetry: _onRetry,
                        sentenceText: sentence['text'] as String,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGradientAppBar(ThemeData theme) {
    return Container(
      height: 56,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF4A90D9), Color(0xFF9BDDFF)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(51),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.mic_rounded, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          Text(
            'The Fluent Lab',
            style: Theme.of(context).appBarTheme.titleTextStyle,
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(51),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.local_fire_department_rounded,
                  color: Color(0xFFFF6B35),
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  '$_currentStreak',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(
              Icons.bar_chart_rounded,
              color: Colors.white,
              size: 22,
            ),
            onPressed: () =>
                Navigator.pushNamed(context, AppRoutes.progressScreen),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
        ],
      ),
    );
  }
}

// ── Streak Earned Dialog ───────────────────────────────────────────────────────
class _StreakEarnedDialog extends StatefulWidget {
  final int streak;
  final VoidCallback onContinue;
  final VoidCallback onViewProgress;

  const _StreakEarnedDialog({
    required this.streak,
    required this.onContinue,
    required this.onViewProgress,
  });

  @override
  State<_StreakEarnedDialog> createState() => _StreakEarnedDialogState();
}

class _StreakEarnedDialogState extends State<_StreakEarnedDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _scaleAnimation = Tween<double>(
      begin: 0.6,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ScaleTransition(
                scale: _scaleAnimation,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF6B35), Color(0xFFFF9F1C)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF6B35).withAlpha(102),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.local_fire_department_rounded,
                    color: Colors.white,
                    size: 44,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Session Complete! 🎉',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'You earned a streak star!\n${widget.streak} day streak — keep it up!',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(height: 1.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFDEF0FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      color: Color(0xFFF59E0B),
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${widget.streak} / 7 days to first badge',
                      style: const TextStyle(
                        color: Color(0xFF4A90D9),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: widget.onViewProgress,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                          color: Color(0xFF4A90D9),
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        'View Progress',
                        style: TextStyle(
                          color: Color(0xFF4A90D9),
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: widget.onContinue,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF4A90D9),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        'Keep Going',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
