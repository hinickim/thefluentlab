import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../routes/app_routes.dart';
import '../../services/voice_coach_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/voice_coach_banner_widget.dart';
import './widgets/audio_test_widget.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Step 1 - Role
  String? _selectedRole;
  final _otherController = TextEditingController();

  // Step 2 - Struggles
  final Set<String> _selectedStruggles = {};

  // Step 3 - Audio Test
  String? _aiDetectedLevel;
  bool _audioTestCompleted = false;

  // Step 4 - Level & Streak
  bool _streakCommitted = false;
  bool _isLoading = false;

  static const int _totalPages = 4;

  static const List<Map<String, dynamic>> _roles = [
    {'label': 'Student', 'icon': Icons.school_rounded},
    {'label': 'Teacher', 'icon': Icons.cast_for_education_rounded},
    {'label': 'Content Creator', 'icon': Icons.videocam_rounded},
    {'label': 'Business Owner', 'icon': Icons.business_center_rounded},
    {'label': 'Artist', 'icon': Icons.palette_rounded},
    {'label': 'Other', 'icon': Icons.more_horiz_rounded},
  ];

  static const List<Map<String, dynamic>> _struggles = [
    {
      'label': 'Speaking with confidence',
      'icon': Icons.record_voice_over_rounded,
    },
    {'label': 'Breathing', 'icon': Icons.air_rounded},
    {'label': 'Accent', 'icon': Icons.language_rounded},
    {'label': 'Fluency', 'icon': Icons.speed_rounded},
    {'label': 'Pronunciation', 'icon': Icons.mic_rounded},
  ];

  String get _recommendedLevel {
    // AI-detected level takes priority over questionnaire
    if (_aiDetectedLevel != null && _aiDetectedLevel!.isNotEmpty) {
      return _aiDetectedLevel!;
    }
    if (_selectedStruggles.contains('Breathing') ||
        _selectedStruggles.contains('Pronunciation')) {
      return 'Beginner';
    } else if (_selectedStruggles.contains('Accent') ||
        _selectedStruggles.contains('Speaking with confidence')) {
      return 'Intermediate';
    } else if (_selectedStruggles.contains('Fluency')) {
      return 'Advanced';
    }
    return 'Beginner';
  }

  String get _levelDescription {
    switch (_recommendedLevel) {
      case 'Beginner':
        return 'Start with foundational exercises to build your voice and breathing technique.';
      case 'Intermediate':
        return 'Work on clarity, confidence, and natural speech patterns.';
      case 'Advanced':
        return 'Refine your fluency and master complex speech challenges.';
      default:
        return 'Start with foundational exercises.';
    }
  }

  Color get _levelColor {
    switch (_recommendedLevel) {
      case 'Beginner':
        return AppTheme.success;
      case 'Intermediate':
        return AppTheme.warning;
      case 'Advanced':
        return AppTheme.secondary;
      default:
        return AppTheme.success;
    }
  }

  void _nextPage() {
    if (_currentPage == 0 && _selectedRole == null) return;
    if (_currentPage == 1 && _selectedStruggles.isEmpty) return;
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _completeOnboarding() async {
    setState(() => _isLoading = true);
    try {
      final client = Supabase.instance.client;
      final userId = client.auth.currentUser?.id;
      if (userId == null) {
        // Guest user — skip DB save and navigate directly
        if (mounted) {
          Navigator.pushReplacementNamed(context, AppRoutes.practiceScreen);
        }
        return;
      }

      final role = _selectedRole == 'Other'
          ? (_otherController.text.trim().isNotEmpty
                ? _otherController.text.trim()
                : 'Other')
          : _selectedRole!;

      await client.from('onboarding_profiles').upsert({
        'user_id': userId,
        'user_role': role,
        'user_role_other': _selectedRole == 'Other'
            ? _otherController.text.trim()
            : null,
        'struggles': _selectedStruggles.toList(),
        'recommended_level': _recommendedLevel,
        'streak_committed': _streakCommitted,
        'completed_at': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.practiceScreen);
      }
    } catch (_) {
      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.practiceScreen);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _otherController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _currentPage = i),
                children: [
                  _buildRolePage(),
                  _buildStrugglesPage(),
                  _buildAudioTestPage(),
                  _buildLevelPage(),
                ],
              ),
            ),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: const Icon(
                  Icons.mic_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              SizedBox(width: 2.w),
              Text(
                'The Fluent Lab',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                '${_currentPage + 1} of $_totalPages',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.sp,
                  color: AppTheme.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.5.h),
          Row(
            children: List.generate(_totalPages, (i) {
              return Expanded(
                child: Container(
                  height: 4,
                  margin: EdgeInsets.only(right: i < _totalPages - 1 ? 1.w : 0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2.0),
                    color: i <= _currentPage
                        ? AppTheme.primary
                        : AppTheme.surfaceVariant,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildRolePage() {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 2.h),
          Text(
            'I am a...',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          SizedBox(height: 0.5.h),
          Text(
            'Tell us about yourself so we can personalize your experience.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.sp,
              color: AppTheme.textSecondary,
            ),
          ),
          SizedBox(height: 2.5.h),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 3.w,
            mainAxisSpacing: 1.5.h,
            childAspectRatio: 2.2,
            children: _roles.map((role) {
              final isSelected = _selectedRole == role['label'];
              return GestureDetector(
                onTap: () =>
                    setState(() => _selectedRole = role['label'] as String),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.primaryContainer
                        : AppTheme.surface,
                    borderRadius: BorderRadius.circular(12.0),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.primary
                          : const Color(0xFFB0CCE0),
                      width: isSelected ? 2 : 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        role['icon'] as IconData,
                        size: 18,
                        color: isSelected
                            ? AppTheme.primary
                            : AppTheme.textSecondary,
                      ),
                      SizedBox(width: 2.w),
                      Flexible(
                        child: Text(
                          role['label'] as String,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.sp,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w500,
                            color: isSelected
                                ? AppTheme.primary
                                : AppTheme.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          if (_selectedRole == 'Other') ...[
            SizedBox(height: 2.h),
            TextFormField(
              controller: _otherController,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13.sp,
                color: AppTheme.textPrimary,
              ),
              decoration: InputDecoration(
                labelText: 'Please specify your role',
                prefixIcon: const Icon(
                  Icons.edit_outlined,
                  color: AppTheme.textMuted,
                  size: 20,
                ),
              ),
            ),
          ],
          SizedBox(height: 2.h),
        ],
      ),
    );
  }

  Widget _buildStrugglesPage() {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 2.h),
          Text(
            'I am struggling with...',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          SizedBox(height: 0.5.h),
          Text(
            'Select all that apply. This helps us recommend the right exercises.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.sp,
              color: AppTheme.textSecondary,
            ),
          ),
          SizedBox(height: 2.5.h),
          ..._struggles.map((struggle) {
            final label = struggle['label'] as String;
            final isSelected = _selectedStruggles.contains(label);
            return GestureDetector(
              onTap: () => setState(() {
                isSelected
                    ? _selectedStruggles.remove(label)
                    : _selectedStruggles.add(label);
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: EdgeInsets.only(bottom: 1.5.h),
                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.8.h),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.primaryContainer
                      : AppTheme.surface,
                  borderRadius: BorderRadius.circular(14.0),
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.primary
                        : const Color(0xFFB0CCE0),
                    width: isSelected ? 2 : 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.primary.withAlpha(26)
                            : AppTheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      child: Icon(
                        struggle['icon'] as IconData,
                        size: 20,
                        color: isSelected
                            ? AppTheme.primary
                            : AppTheme.textSecondary,
                      ),
                    ),
                    SizedBox(width: 3.w),
                    Expanded(
                      child: Text(
                        label,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13.sp,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w500,
                          color: isSelected
                              ? AppTheme.primary
                              : AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.primary
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(6.0),
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.primary
                              : const Color(0xFFB0CCE0),
                          width: 2,
                        ),
                      ),
                      child: isSelected
                          ? const Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 14,
                            )
                          : null,
                    ),
                  ],
                ),
              ),
            );
          }),
          SizedBox(height: 2.h),
        ],
      ),
    );
  }

  Widget _buildAudioTestPage() {
    return AudioTestWidget(
      key: const ValueKey('audio_test'),
      onLevelDetected: (level, reasoning) {
        setState(() {
          _aiDetectedLevel = level;
          _audioTestCompleted = true;
        });
      },
    );
  }

  Widget _buildLevelPage() {
    final isAILevel = _aiDetectedLevel != null && _aiDetectedLevel!.isNotEmpty;
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 2.h),
          VoiceCoachBannerWidget(
            key: ValueKey('onboarding_${_recommendedLevel}_$_selectedRole'),
            messages: VoiceCoachService.onboardingWelcomeMessages(
              role: _selectedRole ?? 'learner',
              struggles: _selectedStruggles.toList(),
              level: _recommendedLevel,
            ),
          ),
          SizedBox(height: 1.5.h),
          Text(
            'Your recommended level',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          SizedBox(height: 0.5.h),
          Text(
            isAILevel
                ? 'Based on your voice recording, our AI coach identified your level.'
                : 'Based on your answers, here is where we suggest you start.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.sp,
              color: AppTheme.textSecondary,
            ),
          ),
          if (isAILevel) ...[
            SizedBox(height: 1.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.8.h),
              decoration: BoxDecoration(
                color: AppTheme.primaryContainer,
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.auto_awesome_rounded,
                    color: AppTheme.primary,
                    size: 14,
                  ),
                  SizedBox(width: 1.5.w),
                  Text(
                    'AI Voice Analysis',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
          SizedBox(height: 3.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_levelColor.withAlpha(26), _levelColor.withAlpha(13)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18.0),
              border: Border.all(color: _levelColor.withAlpha(77), width: 1.5),
            ),
            child: Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: _levelColor.withAlpha(26),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _recommendedLevel == 'Beginner'
                        ? Icons.emoji_events_rounded
                        : _recommendedLevel == 'Intermediate'
                        ? Icons.trending_up_rounded
                        : Icons.rocket_launch_rounded,
                    color: _levelColor,
                    size: 32,
                  ),
                ),
                SizedBox(height: 1.5.h),
                Text(
                  _recommendedLevel,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 17.sp,
                    fontWeight: FontWeight.w700,
                    color: _levelColor,
                  ),
                ),
                SizedBox(height: 0.8.h),
                Text(
                  _levelDescription,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.sp,
                    color: AppTheme.textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 3.h),
          Text(
            'Commit to a daily streak?',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          SizedBox(height: 0.8.h),
          Text(
            'Users who practice daily improve 3x faster. Ready to commit?',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.sp,
              color: AppTheme.textSecondary,
            ),
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _streakCommitted = true),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: EdgeInsets.symmetric(vertical: 2.h),
                    decoration: BoxDecoration(
                      gradient: _streakCommitted
                          ? AppTheme.streakGradient
                          : null,
                      color: _streakCommitted ? null : AppTheme.surface,
                      borderRadius: BorderRadius.circular(14.0),
                      border: Border.all(
                        color: _streakCommitted
                            ? Colors.transparent
                            : const Color(0xFFB0CCE0),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text('🔥', style: TextStyle(fontSize: 14.sp)),
                        SizedBox(height: 0.5.h),
                        Text(
                          "Yes, I'm in!",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            color: _streakCommitted
                                ? Colors.white
                                : AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _streakCommitted = false),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: EdgeInsets.symmetric(vertical: 2.h),
                    decoration: BoxDecoration(
                      color: !_streakCommitted
                          ? AppTheme.surfaceVariant
                          : AppTheme.surface,
                      borderRadius: BorderRadius.circular(14.0),
                      border: Border.all(
                        color: !_streakCommitted
                            ? AppTheme.primary
                            : const Color(0xFFB0CCE0),
                        width: !_streakCommitted ? 2 : 1.5,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text('😌', style: TextStyle(fontSize: 14.sp)),
                        SizedBox(height: 0.5.h),
                        Text(
                          'Maybe later',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    final bool canProceed =
        (_currentPage == 0 && _selectedRole != null) ||
        (_currentPage == 1 && _selectedStruggles.isNotEmpty) ||
        _currentPage == 2 ||
        _currentPage == 3;

    // On audio test page: show "Skip" and "Continue" based on completion
    final bool isAudioPage = _currentPage == 2;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: const Border(
          top: BorderSide(color: Color(0xFFDEF0FF), width: 1),
        ),
      ),
      child: _currentPage < 3
          ? Row(
              children: [
                if (isAudioPage) ...[
                  Expanded(
                    flex: 1,
                    child: SizedBox(
                      height: 52,
                      child: OutlinedButton(
                        onPressed: _nextPage,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                            color: Color(0xFFB0CCE0),
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14.0),
                          ),
                        ),
                        child: Text(
                          'Skip',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 3.w),
                ],
                Expanded(
                  flex: isAudioPage ? 2 : 1,
                  child: SizedBox(
                    height: 52,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: canProceed
                            ? (_audioTestCompleted && isAudioPage
                                  ? AppTheme.primaryGradient
                                  : AppTheme.primaryGradient)
                            : const LinearGradient(
                                colors: [Color(0xFFB0CCE0), Color(0xFFB0CCE0)],
                              ),
                        borderRadius: BorderRadius.circular(14.0),
                      ),
                      child: TextButton(
                        onPressed: canProceed ? _nextPage : null,
                        child: Text(
                          isAudioPage && _audioTestCompleted
                              ? 'Continue'
                              : isAudioPage
                              ? 'Continue'
                              : 'Continue',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            )
          : SizedBox(
              width: double.infinity,
              height: 52,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(14.0),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withAlpha(77),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextButton(
                  onPressed: _isLoading ? null : _completeOnboarding,
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text(
                          "Let's start practicing!",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ),
    );
  }
}
