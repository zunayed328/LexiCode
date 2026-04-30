import 'dart:io' show File;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import '../../core/constants/app_colors.dart';
import '../../core/providers/app_provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/streak_widget.dart';
import '../../shared/widgets/xp_progress_ring.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  String? _localPhotoPath;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..forward();
    _loadSavedPhoto();
  }

  Future<void> _loadSavedPhoto() async {
    final path = await context.read<AuthProvider>().getPhotoPath();
    if (path != null && path.isNotEmpty && mounted) {
      setState(() => _localPhotoPath = path);
    }
  }

  /// Resolves the correct ImageProvider based on whether the path
  /// is a local file (from image_picker) or a network URL (e.g. Google avatar).
  ImageProvider _resolveAvatarImage(String pathOrUrl) {
    if (pathOrUrl.startsWith('http://') || pathOrUrl.startsWith('https://')) {
      return NetworkImage(pathOrUrl);
    }
    return FileImage(File(pathOrUrl));
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final user = provider.user;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Header
            SliverToBoxAdapter(child: _buildHeader(user, isDark, provider)),
            // Streak
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: StreakWidget(streak: user.streak),
              ),
            ),
            // Daily Goal
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: _buildDailyGoal(provider, isDark),
              ),
            ),
            // Quick Actions
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                child: _buildQuickActions(provider, isDark),
              ),
            ),
            // Today's Lesson Card
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                child: _buildTodayLesson(isDark),
              ),
            ),
            // Stats Grid
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                child: _buildStatsGrid(user, isDark),
              ),
            ),
            // Recent Activity
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                child: _buildRecentActivity(isDark),
              ),
            ),
            // Practice Modes
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: _buildPracticeModes(provider, isDark),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(user, bool isDark, AppProvider provider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: (_localPhotoPath == null && user.avatarUrl.isEmpty)
                  ? AppColors.primaryGradient
                  : null,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
              image: (_localPhotoPath != null || user.avatarUrl.isNotEmpty)
                  ? DecorationImage(
                      image: _resolveAvatarImage(
                        _localPhotoPath ?? user.avatarUrl,
                      ),
                      fit: BoxFit.cover,
                      filterQuality: FilterQuality.high,
                    )
                  : null,
            ),
            child: (_localPhotoPath == null && user.avatarUrl.isEmpty)
                ? Center(
                    child: Text(
                      user.name.isNotEmpty
                          ? user.name.substring(0, 1).toUpperCase()
                          : 'U',
                      style: GoogleFonts.inter(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back,',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
                Text(
                  user.name,
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          // Theme toggle
          IconButton(
            onPressed: () => provider.toggleTheme(),
            icon: Icon(
              isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(width: 4),
          // XP Ring
          XpProgressRing(
            currentXp: user.xp,
            maxXp: user.xpForNextLevel,
            level: user.level,
            size: 56,
            lineWidth: 5,
            showLabel: false,
          ),
        ],
      ),
    );
  }

  Widget _buildDailyGoal(AppProvider provider, bool isDark) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '🎯 Daily Goal',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.xpColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${provider.todayXp}/50 XP',
                  style: const TextStyle(
                    color: AppColors.xpColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearPercentIndicator(
            lineHeight: 10,
            percent: provider.dailyProgress,
            backgroundColor: isDark
                ? AppColors.darkBorder
                : AppColors.lightBorder,
            linearGradient: AppColors.goldGradient,
            barRadius: const Radius.circular(5),
            padding: EdgeInsets.zero,
            animation: true,
            animationDuration: 1000,
          ),
          const SizedBox(height: 8),
          Text(
            provider.dailyProgress >= 1.0
                ? '🎉 Daily goal achieved! Great work!'
                : '${((1 - provider.dailyProgress) * 50).round()} XP to go. You got this!',
            style: TextStyle(
              fontSize: 12,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(AppProvider provider, bool isDark) {
    final actions = [
      _QuickAction(
        icon: Icons.code_rounded,
        label: 'Review\nCode',
        gradient: AppColors.primaryGradient,
        onTap: () => provider.setCurrentIndex(1),
      ),
      _QuickAction(
        icon: Icons.school_rounded,
        label: 'Learn\nEnglish',
        gradient: const LinearGradient(
          colors: [AppColors.accentGreen, Color(0xFF38A802)],
        ),
        onTap: () => provider.setCurrentIndex(2),
      ),
      _QuickAction(
        icon: Icons.chat_rounded,
        label: 'AI\nMentor',
        gradient: AppColors.accentGradient,
        onTap: () => _showMentorChat(context),
      ),
      _QuickAction(
        icon: Icons.emoji_events_rounded,
        label: 'Progress\nTracker',
        gradient: AppColors.goldGradient,
        onTap: () => provider.setCurrentIndex(3),
      ),
    ];

    return Row(
      children: actions.map((action) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: GestureDetector(
              onTap: action.onTap,
              child: GlassCard(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: action.gradient,
                        borderRadius: BorderRadius.circular(13),
                        boxShadow: [
                          BoxShadow(
                            color: action.gradient.colors.first.withValues(
                              alpha: 0.3,
                            ),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Icon(action.icon, color: Colors.white, size: 22),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      action.label,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTodayLesson(bool isDark) {
    return GlassCard(
      onTap: () {
        context.read<AppProvider>().setCurrentIndex(2);
      },
      borderColor: AppColors.accentGreen.withValues(alpha: 0.3),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.accentGreen, Color(0xFF38A802)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accentGreen.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(
              Icons.error_outline_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accentGreen.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'IN PROGRESS',
                        style: TextStyle(
                          color: AppColors.accentGreen,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      '+15 XP',
                      style: TextStyle(
                        color: AppColors.xpColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Error Messages',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Understand common error descriptions',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          // Progress
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 44,
                height: 44,
                child: CircularProgressIndicator(
                  value: 0.6,
                  backgroundColor: isDark
                      ? AppColors.darkBorder
                      : AppColors.lightBorder,
                  valueColor: const AlwaysStoppedAnimation(
                    AppColors.accentGreen,
                  ),
                  strokeWidth: 4,
                ),
              ),
              const Text(
                '3/5',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(user, bool isDark) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            Icons.star_rounded,
            '${user.xp}',
            'Total XP',
            AppColors.xpColor,
            isDark,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatCard(
            Icons.school_rounded,
            '${user.lessonsCompleted}',
            'Lessons',
            AppColors.accentGreen,
            isDark,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatCard(
            Icons.code_rounded,
            '${user.codeReviewsCompleted}',
            'Reviews',
            AppColors.primary,
            isDark,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    IconData icon,
    String value,
    String label,
    Color color,
    bool isDark,
  ) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity(bool isDark) {
    final activities = [
      _Activity(
        'Completed "Variables & Types"',
        'Lesson',
        '+15 XP',
        Icons.school_rounded,
        AppColors.accentGreen,
        '2h ago',
      ),
      _Activity(
        'Reviewed Dart code',
        'Code Review',
        '+25 XP',
        Icons.code_rounded,
        AppColors.primary,
        '5h ago',
      ),
      _Activity(
        'Completed "Functions"',
        'Lesson',
        '+15 XP',
        Icons.school_rounded,
        AppColors.accentGreen,
        'Yesterday',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            'Recent Activity',
            style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700),
          ),
        ),
        ...activities.map(
          (activity) => GlassCard(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: activity.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(activity.icon, color: activity.color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        activity.title,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${activity.type} • ${activity.time}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  activity.xp,
                  style: const TextStyle(
                    color: AppColors.xpColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPracticeModes(AppProvider provider, bool isDark) {
    final modes = [
      _PracticeMode(
        'Code Comment Challenge',
        Icons.comment_rounded,
        AppColors.primary,
        'Write clear code comments',
      ),
      _PracticeMode(
        'PR Description Builder',
        Icons.merge_type_rounded,
        AppColors.accentGreen,
        'Craft professional PRs',
      ),
      _PracticeMode(
        'Standup Speech Practice',
        Icons.record_voice_over_rounded,
        AppColors.secondary,
        'Practice daily standup',
      ),
      _PracticeMode(
        'Tech Interview Sim',
        Icons.work_rounded,
        AppColors.accent,
        'Simulate tech interviews',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            'Practice Modes',
            style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700),
          ),
        ),
        SizedBox(
          height: 120,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: modes.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final mode = modes[index];
              return GestureDetector(
                onTap: () => provider.setCurrentIndex(2),
                child: Container(
                  width: 150,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        mode.color.withValues(alpha: 0.15),
                        mode.color.withValues(alpha: 0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: mode.color.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: mode.color.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(mode.icon, color: mode.color, size: 18),
                      ),
                      const Spacer(),
                      Text(
                        mode.title,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        mode.description,
                        style: TextStyle(
                          fontSize: 10,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showMentorChat(BuildContext context) {
    final provider = context.read<AppProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textController = TextEditingController();
    // ScrollController to programmatically jump to the latest message.
    final scrollController = ScrollController();
    final messages = <Map<String, String>>[
      {
        'role': 'mentor',
        'text':
            'Hi! 👋 I\'m your AI coding mentor. Ask me anything about coding best practices, technical English, or career advice!',
      },
    ];

    /// Scrolls the chat list to the very bottom after the frame is rendered.
    void _scrollToBottom() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (scrollController.hasClients) {
          scrollController.animateTo(
            scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            // viewInsets.bottom is the height of the on-screen keyboard (0 when hidden).
            final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

            return Padding(
              // Push the entire sheet up by exactly the keyboard height.
              padding: EdgeInsets.only(bottom: keyboardHeight),
              child: Container(
                // Use a max height so the sheet doesn't exceed 75% of the screen,
                // but allows it to shrink naturally when the keyboard opens.
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.75,
                ),
                decoration: BoxDecoration(
                  color:
                      isDark ? AppColors.darkSurface : AppColors.lightSurface,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Handle
                    Container(
                      margin: const EdgeInsets.only(top: 12),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkBorder
                            : AppColors.lightBorder,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    // Title
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              gradient: AppColors.accentGradient,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.smart_toy_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'AI Mentor',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                'Online',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.accentGreen,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    // Messages — Expanded so it fills available space and
                    // shrinks naturally when the keyboard pushes the sheet up.
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final msg = messages[index];
                          final isMentor = msg['role'] == 'mentor';
                          return Align(
                            alignment: isMentor
                                ? Alignment.centerLeft
                                : Alignment.centerRight,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(14),
                              constraints: BoxConstraints(
                                maxWidth:
                                    MediaQuery.of(context).size.width * 0.75,
                              ),
                              decoration: BoxDecoration(
                                color: isMentor
                                    ? (isDark
                                          ? AppColors.darkCard
                                          : AppColors.lightDivider)
                                    : AppColors.primary,
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(16),
                                  topRight: const Radius.circular(16),
                                  bottomLeft:
                                      Radius.circular(isMentor ? 4 : 16),
                                  bottomRight:
                                      Radius.circular(isMentor ? 16 : 4),
                                ),
                              ),
                              child: Text(
                                msg['text']!,
                                style: TextStyle(
                                  color: isMentor
                                      ? (isDark
                                            ? AppColors.darkText
                                            : AppColors.lightText)
                                      : Colors.white,
                                  fontSize: 14,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    // Input bar — always visible above the keyboard because its
                    // parent sheet is already shifted up by keyboardHeight.
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkBackground
                            : AppColors.lightBackground,
                        border: Border(
                          top: BorderSide(
                            color: isDark
                                ? AppColors.darkBorder
                                : AppColors.lightBorder,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: textController,
                              decoration: InputDecoration(
                                hintText: 'Ask me anything...',
                                filled: true,
                                fillColor: isDark
                                    ? AppColors.darkSurface
                                    : AppColors.lightSurface,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(24),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () async {
                              if (textController.text.trim().isEmpty) return;
                              final msg = textController.text.trim();
                              textController.clear();
                              setModalState(() {
                                messages.add({'role': 'user', 'text': msg});
                              });
                              // Scroll to the user's message immediately.
                              _scrollToBottom();
                              final response =
                                  await provider.chatWithMentor(msg);
                              setModalState(() {
                                messages.add({
                                  'role': 'mentor',
                                  'text': response,
                                });
                              });
                              // Scroll again to reveal the mentor's reply.
                              _scrollToBottom();
                              // Award XP for the mentor chat interaction.
                              provider.addMentorChatXp();
                            },
                            child: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                gradient: AppColors.primaryGradient,
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: const Icon(
                                Icons.send_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _QuickAction {
  final IconData icon;
  final String label;
  final LinearGradient gradient;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.gradient,
    required this.onTap,
  });
}

class _Activity {
  final String title;
  final String type;
  final String xp;
  final IconData icon;
  final Color color;
  final String time;

  const _Activity(
    this.title,
    this.type,
    this.xp,
    this.icon,
    this.color,
    this.time,
  );
}

class _PracticeMode {
  final String title;
  final IconData icon;
  final Color color;
  final String description;

  const _PracticeMode(this.title, this.icon, this.color, this.description);
}
