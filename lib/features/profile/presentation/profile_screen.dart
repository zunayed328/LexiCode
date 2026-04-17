import 'dart:math';
import 'dart:ui';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/app_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/auth_service.dart';
import '../../../shared/models/activity_entry.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../auth/presentation/login_screen.dart';
import '../../auth/presentation/welcome_screen.dart';
import '../../language_learning/providers/progress_provider.dart';
import '../../language_learning/providers/learning_provider.dart';

// ─── Accent Palette ───────────────────────────────────────────────
const _cyanAccent = Color(0xFF00D2FF);
const _emeraldAccent = Color(0xFF10B981);

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _localPhotoPath;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
    _loadSavedPhoto();
  }

  Future<void> _loadSavedPhoto() async {
    final path = await context.read<AuthProvider>().getPhotoPath();
    if (path != null && path.isNotEmpty && mounted) {
      setState(() => _localPhotoPath = path);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
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
            SliverToBoxAdapter(
              child: _buildProfileHeader(user, provider, isDark),
            ),
            SliverToBoxAdapter(child: _buildStatsBar(user, provider, isDark)),
            SliverToBoxAdapter(child: _buildWeeklyChart(provider, isDark)),
            SliverToBoxAdapter(child: _buildActivityTabs(isDark)),
            SliverToBoxAdapter(child: _buildActivityList(user, isDark)),
            SliverToBoxAdapter(
              child: _buildSettingsSection(provider, isDark, context),
            ),
            SliverToBoxAdapter(child: _buildAboutSection(isDark)),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }

  // ─── Profile Header with Progress Ring ───────────────────────────
  Widget _buildProfileHeader(user, AppProvider provider, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
      child: Column(
        children: [
          // Avatar with glowing progress ring + camera edit button
          SizedBox(
            width: 120,
            height: 120,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Progress ring
                SizedBox(
                  width: 120,
                  height: 120,
                  child: CustomPaint(
                    painter: _ProgressRingPainter(
                      progress: user.levelProgress.clamp(0.0, 1.0),
                      strokeWidth: 4,
                      gradient: const LinearGradient(
                        colors: [
                          _cyanAccent,
                          AppColors.primary,
                          _emeraldAccent,
                        ],
                      ),
                    ),
                  ),
                ),
                // Avatar circle — shows picked photo or Google photo or initial letter
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    gradient:
                        (_localPhotoPath == null && user.avatarUrl.isEmpty)
                        ? AppColors.primaryGradient
                        : null,
                    shape: BoxShape.circle,
                    image: _localPhotoPath != null || user.avatarUrl.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(
                              _localPhotoPath ?? user.avatarUrl,
                            ),
                            fit: BoxFit.cover,
                            filterQuality: FilterQuality.high,
                          )
                        : null,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.35),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: (_localPhotoPath == null && user.avatarUrl.isEmpty)
                      ? Center(
                          child: Text(
                            user.name.isNotEmpty
                                ? user.name.substring(0, 1).toUpperCase()
                                : 'U',
                            style: GoogleFonts.inter(
                              fontSize: 36,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        )
                      : null,
                ),
                // Camera edit button
                Positioned(
                  bottom: 2,
                  right: 2,
                  child: GestureDetector(
                    onTap: () => _pickProfileImage(provider),
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark
                              ? AppColors.darkBackground
                              : AppColors.lightBackground,
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.4),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.camera_alt_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          // Editable name row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                user.name,
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () =>
                    _showEditNameSheet(context, provider, user.name, isDark),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.edit_rounded,
                    color: AppColors.primary,
                    size: 15,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            user.email,
            style: TextStyle(
              fontSize: 14,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 8),
          // Rank badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.2),
                  _cyanAccent.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.military_tech_rounded,
                  color: AppColors.primary,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  user.levelTitle,
                  style: GoogleFonts.inter(
                    color: AppColors.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '  ·  Lv.${user.level}',
                  style: TextStyle(
                    color: AppColors.primary.withValues(alpha: 0.7),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Profile Editing Actions ──────────────────────────────────────

  Future<void> _pickProfileImage(AppProvider provider) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );

    if (image != null && mounted) {
      setState(() => _localPhotoPath = image.path);
      provider.updateUserAvatar(image.path);
      // Persist the path for next app launch
      context.read<AuthProvider>().updatePhotoPath(image.path);
    }
  }

  void _showEditNameSheet(
    BuildContext context,
    AppProvider provider,
    String currentName,
    bool isDark,
  ) {
    final controller = TextEditingController(text: currentName);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkCard.withValues(alpha: 0.9)
                    : Colors.white.withValues(alpha: 0.95),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
                border: Border.all(
                  color: isDark
                      ? AppColors.darkBorder.withValues(alpha: 0.5)
                      : AppColors.lightBorder,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle bar
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkBorder
                          : AppColors.lightBorder,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Edit Display Name',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller,
                    autofocus: true,
                    style: GoogleFonts.inter(fontSize: 16),
                    decoration: InputDecoration(
                      labelText: 'Display Name',
                      labelStyle: TextStyle(
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                      filled: true,
                      fillColor: isDark
                          ? AppColors.darkSurface.withValues(alpha: 0.5)
                          : AppColors.lightDivider,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: AppColors.primary,
                          width: 2,
                        ),
                      ),
                      prefixIcon: const Icon(
                        Icons.person_rounded,
                        color: AppColors.primary,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton(
                      onPressed: () {
                        final newName = controller.text.trim();
                        if (newName.isNotEmpty) {
                          provider.updateUserName(newName);
                          context.read<AuthProvider>().updateDisplayName(
                            newName,
                          );
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Name updated successfully!'),
                              backgroundColor: _emeraldAccent,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          );
                        }
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        'Save Changes',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Stats Bar (4 metrics) ───────────────────────────────────────
  Widget _buildStatsBar(user, AppProvider provider, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [
                        AppColors.darkCard.withValues(alpha: 0.7),
                        AppColors.darkSurface.withValues(alpha: 0.5),
                      ]
                    : [
                        Colors.white.withValues(alpha: 0.85),
                        Colors.white.withValues(alpha: 0.65),
                      ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark
                    ? AppColors.darkBorder.withValues(alpha: 0.4)
                    : AppColors.lightBorder.withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  Icons.local_fire_department_rounded,
                  '${user.streak}',
                  'Streak',
                  AppColors.streakColor,
                ),
                _statDivider(isDark),
                _buildStatItem(
                  Icons.timer_rounded,
                  provider.formattedTotalTime,
                  'Active',
                  _cyanAccent,
                ),
                _statDivider(isDark),
                _buildStatItem(
                  Icons.star_rounded,
                  '${user.xp}',
                  'XP',
                  AppColors.xpColor,
                ),
                _statDivider(isDark),
                _buildStatItem(
                  Icons.code_rounded,
                  '${user.codeReviewsCompleted}',
                  'Reviews',
                  AppColors.primary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _statDivider(bool isDark) => Container(
    width: 1,
    height: 40,
    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
  );

  Widget _buildStatItem(
    IconData icon,
    String value,
    String label,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 6),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: AppColors.darkTextSecondary,
          ),
        ),
      ],
    );
  }

  // ─── 7-Day Activity Chart ────────────────────────────────────────
  Widget _buildWeeklyChart(AppProvider provider, bool isDark) {
    final data = provider.weeklyActivityData;
    final maxY = data.reduce(max).clamp(1.0, double.infinity);
    final now = DateTime.now();
    final dayLabels = List.generate(7, (i) {
      final d = now.subtract(Duration(days: 6 - i));
      return ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][d.weekday - 1];
    });

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.insights_rounded,
                  color: _cyanAccent,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Weekly Activity',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: _cyanAccent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${data.reduce((a, b) => a + b).toInt()} total',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _cyanAccent,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 150,
              child: LineChart(
                LineChartData(
                  minY: 0,
                  maxY: maxY + 1,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: max(1, maxY / 3),
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: isDark
                          ? AppColors.darkBorder.withValues(alpha: 0.3)
                          : AppColors.lightBorder.withValues(alpha: 0.5),
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 24,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx < 0 || idx >= dayLabels.length)
                            return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              dayLabels[idx],
                              style: TextStyle(
                                fontSize: 10,
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: List.generate(
                        7,
                        (i) => FlSpot(i.toDouble(), data[i]),
                      ),
                      isCurved: true,
                      curveSmoothness: 0.35,
                      color: _cyanAccent,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, bar, index) =>
                            FlDotCirclePainter(
                              radius: 4,
                              color: _cyanAccent,
                              strokeWidth: 2,
                              strokeColor: isDark
                                  ? AppColors.darkCard
                                  : Colors.white,
                            ),
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            _cyanAccent.withValues(alpha: 0.25),
                            _cyanAccent.withValues(alpha: 0.0),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ],
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (spot) =>
                          isDark ? AppColors.darkCard : Colors.white,
                      getTooltipItems: (spots) => spots.map((s) {
                        return LineTooltipItem(
                          '${s.y.toInt()} activities',
                          GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _cyanAccent,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Activity Tab Bar ────────────────────────────────────────────
  Widget _buildActivityTabs(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Activity History',
            style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkCard.withValues(alpha: 0.6)
                  : AppColors.lightDivider,
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.all(4),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(11),
                color: isDark ? AppColors.darkSurface : Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: _tabController.index == 0
                  ? _cyanAccent
                  : _emeraldAccent,
              unselectedLabelColor: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
              labelStyle: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              tabs: const [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.code_rounded, size: 16),
                      SizedBox(width: 6),
                      Text('Code Reviews'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.school_rounded, size: 16),
                      SizedBox(width: 6),
                      Text('English Practice'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Activity List ───────────────────────────────────────────────
  Widget _buildActivityList(user, bool isDark) {
    final isCodeTab = _tabController.index == 0;
    final List<ActivityEntry> entries = isCodeTab
        ? user.codeReviewActivities
        : user.englishActivities;
    final displayEntries = entries.take(10).toList();

    if (displayEntries.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
        child: GlassCard(
          child: Column(
            children: [
              Icon(
                isCodeTab ? Icons.code_off_rounded : Icons.school_outlined,
                size: 40,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
              const SizedBox(height: 12),
              Text(
                isCodeTab ? 'No code reviews yet' : 'No English practice yet',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                isCodeTab
                    ? 'Analyze some code to see your history'
                    : 'Complete a lesson or practice session',
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
      );
    }

    final accentColor = isCodeTab ? _cyanAccent : _emeraldAccent;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Column(
        children: displayEntries.map((entry) {
          return _buildActivityCard(entry, accentColor, isDark);
        }).toList(),
      ),
    );
  }

  Widget _buildActivityCard(ActivityEntry entry, Color accent, bool isDark) {
    final icon = switch (entry.type) {
      ActivityType.codeReview => Icons.code_rounded,
      ActivityType.lesson => Icons.menu_book_rounded,
      ActivityType.ielts => Icons.quiz_rounded,
      ActivityType.mentorChat => Icons.smart_toy_rounded,
      ActivityType.practice => Icons.fitness_center_rounded,
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [
                        AppColors.darkCard.withValues(alpha: 0.7),
                        AppColors.darkSurface.withValues(alpha: 0.5),
                      ]
                    : [
                        Colors.white.withValues(alpha: 0.85),
                        Colors.white.withValues(alpha: 0.65),
                      ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: accent.withValues(alpha: 0.15)),
            ),
            child: Row(
              children: [
                // Icon container
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: accent, size: 20),
                ),
                const SizedBox(width: 12),
                // Title + timestamp
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.title,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        entry.relativeTime,
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
                // Detail pill
                if (entry.detail != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: accent.withValues(alpha: 0.2)),
                    ),
                    child: Text(
                      entry.detail!,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: accent,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Settings Section ────────────────────────────────────────────
  Widget _buildSettingsSection(
    AppProvider provider,
    bool isDark,
    BuildContext context,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Settings',
            style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          GlassCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _buildSettingsTile(
                  Icons.dark_mode_rounded,
                  'Dark Mode',
                  AppColors.primary,
                  trailing: Switch.adaptive(
                    value: provider.themeMode == ThemeMode.dark,
                    onChanged: (_) => provider.toggleTheme(),
                    activeColor: AppColors.primary,
                  ),
                ),
                Divider(
                  height: 1,
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
                _buildSettingsTile(
                  Icons.notifications_rounded,
                  'Notifications',
                  AppColors.secondary,
                  trailing: Switch.adaptive(
                    value: true,
                    onChanged: (_) {},
                    activeColor: AppColors.primary,
                  ),
                ),
                Divider(
                  height: 1,
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
                _buildSettingsTile(
                  Icons.translate_rounded,
                  'Proficiency Level',
                  _emeraldAccent,
                  subtitle: provider.user.proficiencyLevel,
                  onTap: () {},
                ),
                Divider(
                  height: 1,
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
                _buildSettingsTile(
                  Icons.timer_rounded,
                  'Daily Goal',
                  AppColors.xpColor,
                  subtitle: '50 XP/day',
                  onTap: () {},
                ),
                Divider(
                  height: 1,
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
                _buildSettingsTile(
                  Icons.lock_rounded,
                  'Change Password',
                  _cyanAccent,
                  subtitle: 'Update your account security',
                  onTap: () => _showChangePasswordDialog(context, isDark),
                ),
                Divider(
                  height: 1,
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
                _buildSettingsTile(
                  Icons.logout_rounded,
                  'Log Out',
                  AppColors.error,
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: isDark
                            ? AppColors.darkCard
                            : Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        title: Text(
                          'Log Out',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                        ),
                        content: const Text(
                          'Are you sure you want to log out?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Cancel'),
                          ),
                          FilledButton(
                            onPressed: () async {
                              Navigator.pop(ctx);
                              try {
                                if (context.mounted) {
                                  context
                                      .read<ProgressProvider>()
                                      .clearUserData();
                                  context
                                      .read<LearningProvider>()
                                      .clearUserData();
                                  context.read<AuthProvider>().clearUserData();
                                }
                                await context.read<AuthProvider>().signOut();
                                if (context.mounted) {
                                  Navigator.of(context).pushAndRemoveUntil(
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const WelcomeScreen(),
                                    ),
                                    (Route<dynamic> route) => false,
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Failed to log out: $e',
                                        style: const TextStyle(
                                          color: Colors.white,
                                        ),
                                      ),
                                      backgroundColor: AppColors.error,
                                    ),
                                  );
                                }
                              }
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.error,
                            ),
                            child: const Text('Log Out'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile(
    IconData icon,
    String title,
    Color color, {
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
      title: Text(
        title,
        style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.darkTextSecondary,
              ),
            )
          : null,
      trailing:
          trailing ?? const Icon(Icons.arrow_forward_ios_rounded, size: 16),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
    );
  }

  // ─── Change Password Dialog ──────────────────────────────────────
  void _showChangePasswordDialog(BuildContext context, bool isDark) {
    final currentPwController = TextEditingController();
    final newPwController = TextEditingController();
    bool obscureCurrent = true;
    bool obscureNew = true;
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E1E2E) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(
              color: isDark
                  ? AppColors.darkBorder.withValues(alpha: 0.4)
                  : AppColors.lightBorder,
            ),
          ),
          icon: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: _cyanAccent.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.lock_rounded, color: _cyanAccent, size: 28),
          ),
          title: Text(
            'Change Password',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 18),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: currentPwController,
                obscureText: obscureCurrent,
                style: GoogleFonts.inter(fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'Current Password',
                  labelStyle: TextStyle(
                    fontSize: 13,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                  filled: true,
                  fillColor: isDark
                      ? AppColors.darkSurface.withValues(alpha: 0.5)
                      : AppColors.lightDivider,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: _cyanAccent, width: 2),
                  ),
                  prefixIcon: const Icon(
                    Icons.lock_outline_rounded,
                    color: _cyanAccent,
                    size: 20,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscureCurrent
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                      size: 20,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                    onPressed: () =>
                        setDialogState(() => obscureCurrent = !obscureCurrent),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: newPwController,
                obscureText: obscureNew,
                style: GoogleFonts.inter(fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'New Password',
                  labelStyle: TextStyle(
                    fontSize: 13,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                  filled: true,
                  fillColor: isDark
                      ? AppColors.darkSurface.withValues(alpha: 0.5)
                      : AppColors.lightDivider,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: _cyanAccent, width: 2),
                  ),
                  prefixIcon: const Icon(
                    Icons.lock_reset_rounded,
                    color: _cyanAccent,
                    size: 20,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscureNew
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                      size: 20,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                    onPressed: () =>
                        setDialogState(() => obscureNew = !obscureNew),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.center,
          actionsPadding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
          actions: [
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: isLoading
                    ? null
                    : () async {
                        setDialogState(() => isLoading = true);
                        try {
                          await context.read<AuthProvider>().changePassword(
                            currentPassword: currentPwController.text,
                            newPassword: newPwController.text,
                          );
                          if (ctx.mounted) Navigator.pop(ctx);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text(
                                  'Password changed successfully!',
                                ),
                                backgroundColor: _emeraldAccent,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            );
                          }
                        } on AuthException catch (e) {
                          setDialogState(() => isLoading = false);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(e.message),
                                backgroundColor: AppColors.error,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            );
                          }
                        } catch (e) {
                          setDialogState(() => isLoading = false);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text(
                                  'Failed to change password',
                                ),
                                backgroundColor: AppColors.error,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            );
                          }
                        }
                      },
                style: FilledButton.styleFrom(
                  backgroundColor: _cyanAccent,
                  disabledBackgroundColor: _cyanAccent.withValues(alpha: 0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'Update Password',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── About Section ───────────────────────────────────────────────
  Widget _buildAboutSection(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'About',
            style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ShaderMask(
                      shaderCallback: (bounds) =>
                          AppColors.primaryGradient.createShader(bounds),
                      child: Text(
                        'LexiCode',
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'v1.0.0',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'AI-Powered Code Review & English Learning for Developers',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildAboutChip('🔒', 'E2E Encrypted'),
                    const SizedBox(width: 8),
                    _buildAboutChip('🛡️', 'GDPR Compliant'),
                    const SizedBox(width: 8),
                    _buildAboutChip('📊', 'Anonymous Analytics'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutChip(String emoji, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

// ─── Progress Ring Custom Painter ──────────────────────────────────
class _ProgressRingPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final LinearGradient gradient;

  _ProgressRingPainter({
    required this.progress,
    required this.strokeWidth,
    required this.gradient,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final center = rect.center;
    final radius = (min(size.width, size.height) - strokeWidth) / 2;

    // Background track
    final trackPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    // Progress arc
    final progressPaint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ProgressRingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
