import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _client = Supabase.instance.client;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  // Profile fields
  final _displayNameController = TextEditingController();
  String? _selectedRole;
  final _otherRoleController = TextEditingController();
  final Set<String> _selectedStruggles = {};
  String _difficultyLevel = 'Beginner';
  bool _notificationsEnabled = true;

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

  static const List<Map<String, dynamic>> _difficultyLevels = [
    {
      'label': 'Beginner',
      'icon': Icons.star_outline_rounded,
      'desc': 'Foundational exercises',
    },
    {
      'label': 'Intermediate',
      'icon': Icons.star_half_rounded,
      'desc': 'Clarity & confidence',
    },
    {
      'label': 'Advanced',
      'icon': Icons.star_rounded,
      'desc': 'Complex challenges',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _otherRoleController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return;

      final data = await _client
          .from('onboarding_profiles')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (data != null && mounted) {
        final role = data['user_role'] as String? ?? '';
        final knownRoles = _roles.map((r) => r['label'] as String).toList();
        final isKnownRole = knownRoles.contains(role);

        setState(() {
          _displayNameController.text = data['display_name'] as String? ?? '';
          _selectedRole = isKnownRole ? role : 'Other';
          if (!isKnownRole && role.isNotEmpty) {
            _otherRoleController.text = role;
          } else {
            _otherRoleController.text =
                data['user_role_other'] as String? ?? '';
          }
          final struggles = data['struggles'];
          if (struggles is List) {
            _selectedStruggles.addAll(struggles.cast<String>());
          }
          _difficultyLevel =
              data['difficulty_level'] as String? ??
              data['recommended_level'] as String? ??
              'Beginner';
          _notificationsEnabled =
              data['notifications_enabled'] as bool? ?? true;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _errorMessage = 'Failed to load profile.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSettings() async {
    if (_selectedRole == null) {
      setState(() => _errorMessage = 'Please select a role.');
      return;
    }
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return;

      final role = _selectedRole == 'Other'
          ? (_otherRoleController.text.trim().isNotEmpty
                ? _otherRoleController.text.trim()
                : 'Other')
          : _selectedRole!;

      await _client.from('onboarding_profiles').upsert({
        'user_id': userId,
        'display_name': _displayNameController.text.trim(),
        'user_role': role,
        'user_role_other': _selectedRole == 'Other'
            ? _otherRoleController.text.trim()
            : null,
        'struggles': _selectedStruggles.toList(),
        'difficulty_level': _difficultyLevel,
        'recommended_level': _difficultyLevel,
        'notifications_enabled': _notificationsEnabled,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Settings saved!',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _errorMessage = 'Failed to save settings. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _signOut() async {
    await _client.auth.signOut();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.loginScreen,
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppTheme.primary),
                    )
                  : _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0D2B45), Color(0xFF1A4A6E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(26),
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
          SizedBox(width: 3.w),
          Text(
            'Settings',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const Spacer(),
          _isSaving
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              : GestureDetector(
                  onTap: _saveSettings,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 3.w,
                      vertical: 1.h,
                    ),
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    child: Text(
                      'Save',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_errorMessage != null) _buildErrorBanner(),
          _buildProfileSection(),
          SizedBox(height: 2.h),
          _buildRoleSection(),
          SizedBox(height: 2.h),
          _buildStrugglesSection(),
          SizedBox(height: 2.h),
          _buildDifficultySection(),
          SizedBox(height: 2.h),
          _buildNotificationsSection(),
          SizedBox(height: 2.h),
          _buildSignOutButton(),
          SizedBox(height: 2.h),
        ],
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: AppTheme.errorContainer,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: AppTheme.error.withAlpha(77)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppTheme.error,
            size: 18,
          ),
          SizedBox(width: 2.w),
          Expanded(
            child: Text(
              _errorMessage!,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11.sp,
                color: AppTheme.error,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withAlpha(20),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 1.h),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Icon(icon, color: Colors.white, size: 16),
                ),
                SizedBox(width: 2.w),
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          Divider(color: AppTheme.surfaceVariant, height: 1),
          Padding(padding: EdgeInsets.all(4.w), child: child),
        ],
      ),
    );
  }

  Widget _buildProfileSection() {
    return _buildSectionCard(
      title: 'Profile',
      icon: Icons.person_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Display Name',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
          SizedBox(height: 1.h),
          TextField(
            controller: _displayNameController,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13.sp,
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: 'Enter your display name',
              hintStyle: GoogleFonts.plusJakartaSans(
                fontSize: 12.sp,
                color: AppTheme.textMuted,
              ),
              prefixIcon: const Icon(
                Icons.badge_rounded,
                color: AppTheme.primary,
                size: 20,
              ),
            ),
          ),
          SizedBox(height: 1.5.h),
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: AppTheme.surfaceVariant,
              borderRadius: BorderRadius.circular(10.0),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.email_rounded,
                  color: AppTheme.primary,
                  size: 18,
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: Text(
                    _client.auth.currentUser?.email ?? 'No email',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.sp,
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  'Email',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10.sp,
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

  Widget _buildRoleSection() {
    return _buildSectionCard(
      title: 'I am a...',
      icon: Icons.work_rounded,
      child: Column(
        children: [
          Wrap(
            spacing: 2.w,
            runSpacing: 1.h,
            children: _roles.map((role) {
              final isSelected = _selectedRole == role['label'];
              return GestureDetector(
                onTap: () =>
                    setState(() => _selectedRole = role['label'] as String),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                  decoration: BoxDecoration(
                    gradient: isSelected ? AppTheme.primaryGradient : null,
                    color: isSelected ? null : AppTheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(10.0),
                    border: Border.all(
                      color: isSelected ? AppTheme.primary : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        role['icon'] as IconData,
                        size: 16,
                        color: isSelected
                            ? Colors.white
                            : AppTheme.textSecondary,
                      ),
                      SizedBox(width: 1.5.w),
                      Text(
                        role['label'] as String,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.sp,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          if (_selectedRole == 'Other') ...[
            SizedBox(height: 1.5.h),
            TextField(
              controller: _otherRoleController,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.sp,
                color: AppTheme.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'Please specify your role',
                hintStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 11.sp,
                  color: AppTheme.textMuted,
                ),
                prefixIcon: const Icon(
                  Icons.edit_rounded,
                  color: AppTheme.primary,
                  size: 18,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStrugglesSection() {
    return _buildSectionCard(
      title: 'I am struggling with...',
      icon: Icons.psychology_rounded,
      child: Wrap(
        spacing: 2.w,
        runSpacing: 1.h,
        children: _struggles.map((struggle) {
          final isSelected = _selectedStruggles.contains(struggle['label']);
          return GestureDetector(
            onTap: () {
              setState(() {
                if (isSelected) {
                  _selectedStruggles.remove(struggle['label']);
                } else {
                  _selectedStruggles.add(struggle['label'] as String);
                }
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
              decoration: BoxDecoration(
                gradient: isSelected ? AppTheme.primaryGradient : null,
                color: isSelected ? null : AppTheme.surfaceVariant,
                borderRadius: BorderRadius.circular(10.0),
                border: Border.all(
                  color: isSelected ? AppTheme.primary : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    struggle['icon'] as IconData,
                    size: 15,
                    color: isSelected ? Colors.white : AppTheme.textSecondary,
                  ),
                  SizedBox(width: 1.5.w),
                  Text(
                    struggle['label'] as String,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.sp,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                      color: isSelected ? Colors.white : AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDifficultySection() {
    return _buildSectionCard(
      title: 'Difficulty Level',
      icon: Icons.tune_rounded,
      child: Column(
        children: _difficultyLevels.map((level) {
          final isSelected = _difficultyLevel == level['label'];
          return GestureDetector(
            onTap: () =>
                setState(() => _difficultyLevel = level['label'] as String),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: EdgeInsets.only(bottom: 1.h),
              padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.5.h),
              decoration: BoxDecoration(
                gradient: isSelected ? AppTheme.primaryGradient : null,
                color: isSelected ? null : AppTheme.surfaceVariant,
                borderRadius: BorderRadius.circular(12.0),
                border: Border.all(
                  color: isSelected ? AppTheme.primary : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    level['icon'] as IconData,
                    size: 20,
                    color: isSelected ? Colors.white : AppTheme.primary,
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          level['label'] as String,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w700,
                            color: isSelected
                                ? Colors.white
                                : AppTheme.textPrimary,
                          ),
                        ),
                        Text(
                          level['desc'] as String,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10.sp,
                            color: isSelected
                                ? Colors.white.withAlpha(204)
                                : AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    const Icon(
                      Icons.check_circle_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildNotificationsSection() {
    return _buildSectionCard(
      title: 'Notifications',
      icon: Icons.notifications_rounded,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Practice Reminders',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  'Get daily reminders to keep your streak going',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10.sp,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _notificationsEnabled,
            onChanged: (val) => setState(() => _notificationsEnabled = val),
            activeThumbColor: AppTheme.primary,
            activeTrackColor: AppTheme.primaryContainer,
          ),
        ],
      ),
    );
  }

  Widget _buildSignOutButton() {
    return GestureDetector(
      onTap: _signOut,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 1.8.h),
        decoration: BoxDecoration(
          color: AppTheme.errorContainer,
          borderRadius: BorderRadius.circular(14.0),
          border: Border.all(color: AppTheme.error.withAlpha(77)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.logout_rounded, color: AppTheme.error, size: 20),
            SizedBox(width: 2.w),
            Text(
              'Sign Out',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: AppTheme.error,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
