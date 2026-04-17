import 'dart:convert';
import 'dart:io' if (dart.library.io) 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:universal_html/html.dart' as html;

import '../../core/app_export.dart';

class SessionHistoryScreen extends StatefulWidget {
  const SessionHistoryScreen({super.key});

  @override
  State<SessionHistoryScreen> createState() => _SessionHistoryScreenState();
}

class _SessionHistoryScreenState extends State<SessionHistoryScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _entranceController;
  late Animation<double> _fadeAnimation;

  final SupabaseClient _client = Supabase.instance.client;

  List<Map<String, dynamic>> _sessions = [];
  List<Map<String, dynamic>> _filteredSessions = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Filters
  String _selectedCategory = 'All';
  String _selectedPeriod = 'All Time';
  String _selectedScore = 'All Scores';
  String _sortBy = 'Newest First';

  final List<String> _categories = [
    'All',
    'Tongue Twister',
    'Professional',
    'Natural Speech',
    'Mixed',
  ];
  final List<String> _periods = [
    'All Time',
    'Today',
    'This Week',
    'This Month',
    'Last 3 Months',
  ];
  final List<String> _scoreRanges = [
    'All Scores',
    '90-100 (Excellent)',
    '75-89 (Good)',
    '60-74 (Fair)',
    'Below 60',
  ];
  final List<String> _sortOptions = [
    'Newest First',
    'Oldest First',
    'Highest Score',
    'Lowest Score',
  ];

  bool _showFilters = false;
  bool _isExporting = false;

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
    _entranceController.forward();
    _loadSessions();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  Future<void> _loadSessions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        setState(() {
          _sessions = [];
          _filteredSessions = [];
          _isLoading = false;
        });
        return;
      }

      final response = await _client
          .from('practice_sessions')
          .select('*, session_sentences(*)')
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      final sessions = List<Map<String, dynamic>>.from(response);
      setState(() {
        _sessions = sessions;
        _isLoading = false;
      });
      _applyFilters();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load sessions. Please try again.';
      });
    }
  }

  void _applyFilters() {
    List<Map<String, dynamic>> result = List.from(_sessions);

    // Category filter
    if (_selectedCategory != 'All') {
      result = result.where((s) {
        final cat = (s['category'] as String? ?? '').toLowerCase();
        return cat == _selectedCategory.toLowerCase().replaceAll(' ', '_');
      }).toList();
    }

    // Period filter
    final now = DateTime.now();
    if (_selectedPeriod != 'All Time') {
      result = result.where((s) {
        final createdAt = DateTime.tryParse(s['created_at'] as String? ?? '');
        if (createdAt == null) return false;
        switch (_selectedPeriod) {
          case 'Today':
            return createdAt.year == now.year &&
                createdAt.month == now.month &&
                createdAt.day == now.day;
          case 'This Week':
            return now.difference(createdAt).inDays <= 7;
          case 'This Month':
            return createdAt.year == now.year && createdAt.month == now.month;
          case 'Last 3 Months':
            return now.difference(createdAt).inDays <= 90;
          default:
            return true;
        }
      }).toList();
    }

    // Score filter
    if (_selectedScore != 'All Scores') {
      result = result.where((s) {
        final score = (s['overall_score'] as int?) ?? 0;
        switch (_selectedScore) {
          case '90-100 (Excellent)':
            return score >= 90;
          case '75-89 (Good)':
            return score >= 75 && score < 90;
          case '60-74 (Fair)':
            return score >= 60 && score < 75;
          case 'Below 60':
            return score < 60;
          default:
            return true;
        }
      }).toList();
    }

    // Sort
    switch (_sortBy) {
      case 'Newest First':
        result.sort((a, b) {
          final aDate =
              DateTime.tryParse(a['created_at'] as String? ?? '') ??
              DateTime(0);
          final bDate =
              DateTime.tryParse(b['created_at'] as String? ?? '') ??
              DateTime(0);
          return bDate.compareTo(aDate);
        });
        break;
      case 'Oldest First':
        result.sort((a, b) {
          final aDate =
              DateTime.tryParse(a['created_at'] as String? ?? '') ??
              DateTime(0);
          final bDate =
              DateTime.tryParse(b['created_at'] as String? ?? '') ??
              DateTime(0);
          return aDate.compareTo(bDate);
        });
        break;
      case 'Highest Score':
        result.sort(
          (a, b) => ((b['overall_score'] as int?) ?? 0).compareTo(
            (a['overall_score'] as int?) ?? 0,
          ),
        );
        break;
      case 'Lowest Score':
        result.sort(
          (a, b) => ((a['overall_score'] as int?) ?? 0).compareTo(
            (b['overall_score'] as int?) ?? 0,
          ),
        );
        break;
    }

    setState(() {
      _filteredSessions = result;
    });
  }

  Future<void> _exportSessions() async {
    if (_filteredSessions.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No sessions to export.')));
      return;
    }

    setState(() => _isExporting = true);

    try {
      final buffer = StringBuffer();
      buffer.writeln('VoiceCoach Practice Sessions Export');
      buffer.writeln('Generated: ${DateTime.now().toLocal()}');
      buffer.writeln('Total Sessions: ${_filteredSessions.length}');
      buffer.writeln('');
      buffer.writeln('=' * 60);

      for (final session in _filteredSessions) {
        final createdAt = DateTime.tryParse(
          session['created_at'] as String? ?? '',
        );
        final dateStr = createdAt != null
            ? '${createdAt.day}/${createdAt.month}/${createdAt.year}'
            : 'Unknown';
        final timeStr = createdAt != null
            ? '${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}'
            : '';

        buffer.writeln('');
        buffer.writeln('SESSION: $dateStr at $timeStr');
        buffer.writeln('Overall Score: ${session['overall_score'] ?? 0}%');
        buffer.writeln('Category: ${session['category'] ?? 'Mixed'}');
        buffer.writeln('Difficulty: ${session['difficulty'] ?? 'Medium'}');
        buffer.writeln(
          'Duration: ${_formatDuration((session['duration_seconds'] as int?) ?? 0)}',
        );
        buffer.writeln(
          'Sentences Practiced: ${session['sentences_practiced'] ?? 0}',
        );
        buffer.writeln(
          'Streak Earned: ${(session['streak_earned'] as bool?) == true ? 'Yes' : 'No'}',
        );

        final sentences = session['session_sentences'] as List?;
        if (sentences != null && sentences.isNotEmpty) {
          buffer.writeln('');
          buffer.writeln('  SENTENCE DETAILS:');
          for (int i = 0; i < sentences.length; i++) {
            final sent = sentences[i] as Map<String, dynamic>;
            buffer.writeln('  ${i + 1}. "${sent['sentence_text'] ?? ''}"');
            if ((sent['transcript'] as String?)?.isNotEmpty == true) {
              buffer.writeln('     Your transcript: "${sent['transcript']}"');
            }
            buffer.writeln('     Score: ${sent['score'] ?? 0}%');
            if ((sent['feedback'] as String?)?.isNotEmpty == true) {
              buffer.writeln('     Feedback: ${sent['feedback']}');
            }
          }
        }
        buffer.writeln('-' * 60);
      }

      final content = buffer.toString();
      final filename =
          'voicecoach_sessions_${DateTime.now().millisecondsSinceEpoch}.txt';

      if (kIsWeb) {
        final bytes = utf8.encode(content);
        final blob = html.Blob([bytes]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute('download', filename)
          ..click();
        html.Url.revokeObjectUrl(url);
      } else {
        final dir = await _getDocumentsDirectory();
        if (dir != null) {
          final file = File('$dir/$filename');
          await file.writeAsString(content);
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Exported ${_filteredSessions.length} sessions successfully!',
            ),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Export failed. Please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<String?> _getDocumentsDirectory() async {
    if (kIsWeb) return null;
    try {
      // Use path_provider if available, fallback to temp
      return '/tmp';
    } catch (_) {
      return null;
    }
  }

  String _formatDuration(int seconds) {
    if (seconds < 60) return '${seconds}s';
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return secs > 0 ? '${mins}m ${secs}s' : '${mins}m';
  }

  String _formatDate(String? isoDate) {
    if (isoDate == null) return '';
    final dt = DateTime.tryParse(isoDate);
    if (dt == null) return '';
    final local = dt.toLocal();
    final now = DateTime.now();
    final diff = now.difference(local);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return '${local.day}/${local.month}/${local.year}';
  }

  Color _scoreColor(int score) {
    if (score >= 80) return AppTheme.success;
    if (score >= 65) return AppTheme.primary;
    return AppTheme.warning;
  }

  double _avgScore() {
    if (_filteredSessions.isEmpty) return 0;
    final total = _filteredSessions.fold<int>(
      0,
      (sum, s) => sum + ((s['overall_score'] as int?) ?? 0),
    );
    return total / _filteredSessions.length;
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
          child: Column(
            children: [
              _buildAppBar(),
              if (_showFilters) _buildFilterPanel(),
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.primary,
                        ),
                      )
                    : _errorMessage != null
                    ? _buildError()
                    : _filteredSessions.isEmpty
                    ? _buildEmpty()
                    : _buildSessionList(),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: AppNavigation(currentIndex: 1, onTap: (_) {}),
    );
  }

  Widget _buildAppBar() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0D2B45), Color(0xFF1A4A6E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(26),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Session History',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => setState(() => _showFilters = !_showFilters),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: _showFilters
                        ? Colors.white.withAlpha(51)
                        : Colors.white.withAlpha(26),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _showFilters
                          ? Colors.white.withAlpha(128)
                          : Colors.transparent,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.tune_rounded, color: Colors.white, size: 15),
                      const SizedBox(width: 4),
                      Text(
                        'Filter',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _isExporting ? null : _exportSessions,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(26),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: _isExporting
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Row(
                          children: [
                            const Icon(
                              Icons.download_rounded,
                              color: Colors.white,
                              size: 15,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Export',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
          if (!_isLoading && _filteredSessions.isNotEmpty) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                _buildStatChip(
                  Icons.history_rounded,
                  '${_filteredSessions.length} sessions',
                ),
                const SizedBox(width: 8),
                _buildStatChip(
                  Icons.star_rounded,
                  'Avg ${_avgScore().toStringAsFixed(0)}%',
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(26),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryLight, size: 13),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterPanel() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFilterRow('Category', _categories, _selectedCategory, (v) {
            setState(() => _selectedCategory = v);
            _applyFilters();
          }),
          const SizedBox(height: 10),
          _buildFilterRow('Period', _periods, _selectedPeriod, (v) {
            setState(() => _selectedPeriod = v);
            _applyFilters();
          }),
          const SizedBox(height: 10),
          _buildFilterRow('Score', _scoreRanges, _selectedScore, (v) {
            setState(() => _selectedScore = v);
            _applyFilters();
          }),
          const SizedBox(height: 10),
          _buildFilterRow('Sort', _sortOptions, _sortBy, (v) {
            setState(() => _sortBy = v);
            _applyFilters();
          }),
          if (_selectedCategory != 'All' ||
              _selectedPeriod != 'All Time' ||
              _selectedScore != 'All Scores' ||
              _sortBy != 'Newest First') ...[
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () {
                setState(() {
                  _selectedCategory = 'All';
                  _selectedPeriod = 'All Time';
                  _selectedScore = 'All Scores';
                  _sortBy = 'Newest First';
                });
                _applyFilters();
              },
              child: Text(
                'Clear all filters',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterRow(
    String label,
    List<String> options,
    String selected,
    ValueChanged<String> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppTheme.textMuted,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 32,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: options.length,
            separatorBuilder: (_, __) => const SizedBox(width: 6),
            itemBuilder: (context, i) {
              final opt = options[i];
              final isSelected = opt == selected;
              return GestureDetector(
                onTap: () => onChanged(opt),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.primary
                        : AppTheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    opt,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : AppTheme.textSecondary,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSessionList() {
    return RefreshIndicator(
      onRefresh: _loadSessions,
      color: AppTheme.primary,
      child: ListView.builder(
        padding: EdgeInsets.fromLTRB(16, 12, 16, 100),
        itemCount: _filteredSessions.length,
        itemBuilder: (context, index) {
          return _SessionCard(
            session: _filteredSessions[index],
            formatDate: _formatDate,
            formatDuration: _formatDuration,
            scoreColor: _scoreColor,
          );
        },
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppTheme.surfaceVariant,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.history_rounded,
                color: AppTheme.textMuted,
                size: 36,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _selectedCategory != 'All' ||
                      _selectedPeriod != 'All Time' ||
                      _selectedScore != 'All Scores'
                  ? 'No sessions match your filters'
                  : 'No practice sessions yet',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _selectedCategory != 'All' ||
                      _selectedPeriod != 'All Time' ||
                      _selectedScore != 'All Scores'
                  ? 'Try adjusting your filters to see more sessions.'
                  : 'Complete a practice session to see your history here.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: AppTheme.error,
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage ?? 'Something went wrong',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadSessions,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SessionCard extends StatefulWidget {
  final Map<String, dynamic> session;
  final String Function(String?) formatDate;
  final String Function(int) formatDuration;
  final Color Function(int) scoreColor;

  const _SessionCard({
    required this.session,
    required this.formatDate,
    required this.formatDuration,
    required this.scoreColor,
  });

  @override
  State<_SessionCard> createState() => _SessionCardState();
}

class _SessionCardState extends State<_SessionCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final score = (session['overall_score'] as int?) ?? 0;
    final scoreColor = widget.scoreColor(score);
    final dateStr = widget.formatDate(session['created_at'] as String?);
    final duration = widget.formatDuration(
      (session['duration_seconds'] as int?) ?? 0,
    );
    final sentences = session['sentences_practiced'] as int? ?? 0;
    final category = session['category'] as String? ?? 'mixed';
    final streakEarned = (session['streak_earned'] as bool?) ?? false;
    final sentenceDetails = session['session_sentences'] as List?;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: scoreColor, width: 3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header row
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  // Score circle
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: scoreColor.withAlpha(26),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '$score',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: scoreColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              dateStr,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            if (streakEarned) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFEDE6),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.local_fire_department_rounded,
                                      color: Color(0xFFFF6B35),
                                      size: 10,
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      'Streak',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFFFF6B35),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            _InfoChip(
                              icon: Icons.mic_rounded,
                              label: '$sentences sentences',
                            ),
                            const SizedBox(width: 6),
                            _InfoChip(
                              icon: Icons.timer_outlined,
                              label: duration,
                            ),
                            const SizedBox(width: 6),
                            _InfoChip(
                              icon: Icons.category_outlined,
                              label: _formatCategory(category),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: AppTheme.textMuted,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          // Expanded transcript section
          if (_expanded &&
              sentenceDetails != null &&
              sentenceDetails.isNotEmpty)
            Container(
              decoration: BoxDecoration(
                color: AppTheme.background,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Divider(color: AppTheme.textMuted.withAlpha(51), height: 1),
                  const SizedBox(height: 12),
                  Text(
                    'Sentence Details',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textSecondary,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...List.generate(sentenceDetails.length, (i) {
                    final sent = sentenceDetails[i] as Map<String, dynamic>;
                    final sentScore = (sent['score'] as int?) ?? 0;
                    final sentColor = widget.scoreColor(sentScore);
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.textMuted.withAlpha(51),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  sent['sentence_text'] as String? ?? '',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textPrimary,
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
                                  color: sentColor.withAlpha(26),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '$sentScore%',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: sentColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if ((sent['transcript'] as String?)?.isNotEmpty ==
                              true) ...[
                            const SizedBox(height: 6),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.record_voice_over_rounded,
                                  size: 12,
                                  color: AppTheme.textMuted,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    '"${sent['transcript']}"',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      fontStyle: FontStyle.italic,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                          if ((sent['feedback'] as String?)?.isNotEmpty ==
                              true) ...[
                            const SizedBox(height: 6),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.lightbulb_outline_rounded,
                                  size: 12,
                                  color: AppTheme.scoreGold,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    sent['feedback'] as String,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                          if (sent['pronunciation_score'] != null ||
                              sent['fluency_score'] != null ||
                              sent['accuracy_score'] != null) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                if (sent['pronunciation_score'] != null)
                                  _ScoreTag(
                                    label: 'Pronunciation',
                                    score: sent['pronunciation_score'] as int,
                                  ),
                                if (sent['fluency_score'] != null) ...[
                                  const SizedBox(width: 6),
                                  _ScoreTag(
                                    label: 'Fluency',
                                    score: sent['fluency_score'] as int,
                                  ),
                                ],
                                if (sent['accuracy_score'] != null) ...[
                                  const SizedBox(width: 6),
                                  _ScoreTag(
                                    label: 'Accuracy',
                                    score: sent['accuracy_score'] as int,
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ],
                      ),
                    );
                  }),
                ],
              ),
            )
          else if (_expanded)
            Container(
              decoration: BoxDecoration(
                color: AppTheme.background,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Column(
                children: [
                  Divider(color: AppTheme.textMuted.withAlpha(51), height: 1),
                  const SizedBox(height: 12),
                  Text(
                    'No detailed transcript available for this session.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _formatCategory(String cat) {
    switch (cat.toLowerCase()) {
      case 'tongue_twister':
        return 'Tongue Twister';
      case 'professional':
        return 'Professional';
      case 'natural_speech':
        return 'Natural Speech';
      default:
        return cat[0].toUpperCase() + cat.substring(1);
    }
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 11, color: AppTheme.textMuted),
        const SizedBox(width: 3),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10,
            color: AppTheme.textMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _ScoreTag extends StatelessWidget {
  final String label;
  final int score;

  const _ScoreTag({required this.label, required this.score});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$label: $score%',
        style: GoogleFonts.plusJakartaSans(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: AppTheme.textSecondary,
        ),
      ),
    );
  }
}
