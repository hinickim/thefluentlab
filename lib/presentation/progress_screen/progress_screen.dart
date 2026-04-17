import '../../core/app_export.dart';
import './widgets/badges_grid_widget.dart';
import './widgets/milestone_card_widget.dart';
import './widgets/recent_sessions_widget.dart';
import './widgets/streak_hero_widget.dart';
import './widgets/weekly_chart_widget.dart';

// TODO: Replace with Riverpod/Bloc for production state management

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _entranceController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // TODO: Replace with backend-fetched progress data
  final int _currentStreak = 7;
  final int _longestStreak = 12;
  final int _totalSessions = 34;
  final double _weeklyAvgScore = 76.4;

  final List<Map<String, dynamic>> _weeklyScoreMaps = [
    {'day': 'Mon', 'score': 68.0, 'date': '03/23/2026', 'sessions': 1},
    {'day': 'Tue', 'score': 72.0, 'date': '03/24/2026', 'sessions': 2},
    {'day': 'Wed', 'score': 75.0, 'date': '03/25/2026', 'sessions': 1},
    {'day': 'Thu', 'score': 71.0, 'date': '03/26/2026', 'sessions': 1},
    {'day': 'Fri', 'score': 80.0, 'date': '03/27/2026', 'sessions': 2},
    {'day': 'Sat', 'score': 83.0, 'date': '03/28/2026', 'sessions': 1},
    {'day': 'Sun', 'score': 0.0, 'date': '03/29/2026', 'sessions': 0},
  ];

  final List<Map<String, dynamic>> _badgeMaps = [
    {
      'id': 'b001',
      'name': 'First Step',
      'description': 'Complete your first practice session',
      'icon': 'mic',
      'earned': true,
      'earnedDate': '03/01/2026',
      'color': 'purple',
    },
    {
      'id': 'b002',
      'name': '3-Day Streak',
      'description': 'Practice 3 days in a row',
      'icon': 'fire',
      'earned': true,
      'earnedDate': '03/05/2026',
      'color': 'orange',
    },
    {
      'id': 'b003',
      'name': 'Week Warrior',
      'description': 'Complete a full 7-day streak',
      'icon': 'star',
      'earned': true,
      'earnedDate': '03/08/2026',
      'color': 'gold',
    },
    {
      'id': 'b004',
      'name': 'Score 80+',
      'description': 'Achieve 80% or above in a session',
      'icon': 'trophy',
      'earned': true,
      'earnedDate': '03/15/2026',
      'color': 'green',
    },
    {
      'id': 'b005',
      'name': '30-Day Streak',
      'description': 'Practice every day for a month',
      'icon': 'calendar',
      'earned': false,
      'earnedDate': null,
      'color': 'blue',
    },
    {
      'id': 'b006',
      'name': 'Pronunciation Pro',
      'description': 'Score 90%+ on pronunciation 5 times',
      'icon': 'voice',
      'earned': false,
      'earnedDate': null,
      'color': 'indigo',
    },
    {
      'id': 'b007',
      'name': '3-Month Master',
      'description': 'Complete 90 days of practice',
      'icon': 'diamond',
      'earned': false,
      'earnedDate': null,
      'color': 'cyan',
    },
    {
      'id': 'b008',
      'name': 'Perfect Session',
      'description': 'Score 95%+ overall in a full session',
      'icon': 'perfect',
      'earned': false,
      'earnedDate': null,
      'color': 'rose',
    },
  ];

  final List<Map<String, dynamic>> _recentSessionMaps = [
    {
      'id': 'sess007',
      'date': '03/28/2026',
      'dayLabel': 'Today',
      'overallScore': 83,
      'sentencesPracticed': 5,
      'duration': '8 min',
      'streakEarned': true,
      'topCategory': 'Tongue Twister',
    },
    {
      'id': 'sess006',
      'date': '03/27/2026',
      'dayLabel': 'Yesterday',
      'overallScore': 80,
      'sentencesPracticed': 5,
      'duration': '9 min',
      'streakEarned': true,
      'topCategory': 'Professional',
    },
    {
      'id': 'sess005',
      'date': '03/26/2026',
      'dayLabel': 'Thu',
      'overallScore': 71,
      'sentencesPracticed': 5,
      'duration': '7 min',
      'streakEarned': true,
      'topCategory': 'Natural Speech',
    },
    {
      'id': 'sess004',
      'date': '03/25/2026',
      'dayLabel': 'Wed',
      'overallScore': 75,
      'sentencesPracticed': 5,
      'duration': '10 min',
      'streakEarned': true,
      'topCategory': 'Tongue Twister',
    },
    {
      'id': 'sess003',
      'date': '03/24/2026',
      'dayLabel': 'Tue',
      'overallScore': 72,
      'sentencesPracticed': 5,
      'duration': '8 min',
      'streakEarned': true,
      'topCategory': 'Professional',
    },
    {
      'id': 'sess002',
      'date': '03/23/2026',
      'dayLabel': 'Mon',
      'overallScore': 68,
      'sentencesPracticed': 4,
      'duration': '6 min',
      'streakEarned': false,
      'topCategory': 'Natural Speech',
    },
    {
      'id': 'sess001',
      'date': '03/22/2026',
      'dayLabel': 'Sun',
      'overallScore': 65,
      'sentencesPracticed': 5,
      'duration': '9 min',
      'streakEarned': true,
      'topCategory': 'Tongue Twister',
    },
  ];

  final Map<String, dynamic> _nextMilestoneMaps = {
    'title': '30-Day Streak',
    'description': 'Practice every day for a month',
    'reward': '50% discount on Premium plan',
    'rewardType': 'discount',
    'currentProgress': 7,
    'targetProgress': 30,
    'daysRemaining': 23,
    'icon': 'fire',
  };

  bool get _isTablet => MediaQuery.of(context).size.width >= 600;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutQuart,
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _entranceController,
            curve: Curves.easeOutQuart,
          ),
        );
    _entranceController.forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      extendBody: true,
      body: SafeArea(
        bottom: false,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Column(
              children: [
                _buildGradientAppBar(),
                Expanded(
                  child: _isTablet ? _buildTabletLayout() : _buildPhoneLayout(),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: AppNavigation(currentIndex: 1, onTap: (_) {}),
    );
  }

  Widget _buildPhoneLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StreakHeroWidget(
            currentStreak: _currentStreak,
            longestStreak: _longestStreak,
            totalSessions: _totalSessions,
            weeklyAvgScore: _weeklyAvgScore,
          ),
          const SizedBox(height: 16),
          WeeklyChartWidget(weeklyScores: _weeklyScoreMaps),
          const SizedBox(height: 16),
          MilestoneCardWidget(milestoneData: _nextMilestoneMaps),
          const SizedBox(height: 16),
          BadgesGridWidget(badges: _badgeMaps),
          const SizedBox(height: 16),
          RecentSessionsWidget(sessions: _recentSessionMaps),
        ],
      ),
    );
  }

  Widget _buildTabletLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(left: 24, right: 24, top: 12, bottom: 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StreakHeroWidget(
            currentStreak: _currentStreak,
            longestStreak: _longestStreak,
            totalSessions: _totalSessions,
            weeklyAvgScore: _weeklyAvgScore,
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 6,
                child: Column(
                  children: [
                    WeeklyChartWidget(weeklyScores: _weeklyScoreMaps),
                    const SizedBox(height: 16),
                    RecentSessionsWidget(sessions: _recentSessionMaps),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 4,
                child: Column(
                  children: [
                    MilestoneCardWidget(milestoneData: _nextMilestoneMaps),
                    const SizedBox(height: 16),
                    BadgesGridWidget(badges: _badgeMaps),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGradientAppBar() {
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
            child: const Icon(
              Icons.bar_chart_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'My Progress',
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
                  Icons.calendar_today_rounded,
                  color: Colors.white70,
                  size: 13,
                ),
                const SizedBox(width: 4),
                const Text(
                  'Mar 2026',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.mic_rounded, color: Colors.white, size: 22),
            onPressed: () =>
                Navigator.pushNamed(context, AppRoutes.practiceScreen),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
        ],
      ),
    );
  }
}
