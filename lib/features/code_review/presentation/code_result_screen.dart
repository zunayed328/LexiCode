import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../shared/models/code_review_model.dart';
import '../theme/code_review_theme.dart';
import '../viewmodel/code_result_viewmodel.dart';
import '../widgets/ai_insight_card.dart';
import '../widgets/code_tab_selector.dart';
import '../widgets/code_viewer_widget.dart';
import 'diff_comparison_screen.dart';
import '../widgets/issue_card.dart';
import '../widgets/error_state_widget.dart';
import '../widgets/loading_skeleton.dart';

/// Premium code result screen displaying AI analysis, code comparison,
/// and issues breakdown with staggered entry animations.
class CodeResultScreen extends StatefulWidget {
  final CodeReviewResult? result;

  const CodeResultScreen({super.key, this.result});

  @override
  State<CodeResultScreen> createState() => _CodeResultScreenState();
}

class _CodeResultScreenState extends State<CodeResultScreen>
    with TickerProviderStateMixin {
  late AnimationController _staggerController;
  late List<Animation<double>> _fadeAnimations;
  late List<Animation<Offset>> _slideAnimations;

  static const int _sectionCount = 4; // insight, tabs, code, issues

  @override
  void initState() {
    super.initState();
    _staggerController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimations = List.generate(_sectionCount, (i) {
      final start = i * 0.15;
      final end = (start + 0.4).clamp(0.0, 1.0);
      return CurvedAnimation(
        parent: _staggerController,
        curve: Interval(start, end, curve: Curves.easeOut),
      );
    });

    _slideAnimations = List.generate(_sectionCount, (i) {
      final start = i * 0.15;
      final end = (start + 0.4).clamp(0.0, 1.0);
      return Tween<Offset>(
        begin: const Offset(0, 0.08),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _staggerController,
        curve: Interval(start, end, curve: Curves.easeOut),
      ));
    });

    // Start animation after a short delay for the screen transition
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _staggerController.forward();
    });
  }

  @override
  void dispose() {
    _staggerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CodeResultViewModel(result: widget.result),
      child: Consumer<CodeResultViewModel>(
        builder: (context, viewModel, _) {
          return Scaffold(
            backgroundColor: CodeReviewTheme.primaryBg,
            extendBodyBehindAppBar: true,
            appBar: _buildGlassAppBar(context),
            body: _buildBody(viewModel),
          );
        },
      ),
    );
  }

  // ─── Glassmorphism App Bar ──────────────────────────────────────
  PreferredSizeWidget _buildGlassAppBar(BuildContext context) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(64),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: CodeReviewTheme.primaryBg.withValues(alpha: 0.75),
              border: Border(
                bottom: BorderSide(
                  color: CodeReviewTheme.borderSubtle,
                  width: 1,
                ),
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    // Back button
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        color: CodeReviewTheme.textPrimary,
                        size: 24,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 4),

                    // Title
                    Text(
                      'Code Review Results',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: CodeReviewTheme.textPrimary,
                      ),
                    ),
                    const Spacer(),

                    // Share button
                    IconButton(
                      icon: const Icon(
                        Icons.share_outlined,
                        color: CodeReviewTheme.textSecondary,
                        size: 22,
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Share coming soon',
                              style: GoogleFonts.inter(),
                            ),
                            backgroundColor: CodeReviewTheme.cardBg,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        );
                      },
                    ),

                    // Options menu
                    PopupMenuButton<String>(
                      icon: const Icon(
                        Icons.more_vert_rounded,
                        color: CodeReviewTheme.textSecondary,
                        size: 22,
                      ),
                      color: CodeReviewTheme.cardBg,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(
                          color: CodeReviewTheme.borderSubtle,
                        ),
                      ),
                      itemBuilder: (_) => [
                        PopupMenuItem(
                          value: 'diff',
                          child: Row(
                            children: [
                              const Icon(Icons.compare_arrows_rounded,
                                  size: 18, color: CodeReviewTheme.textSecondary),
                              const SizedBox(width: 10),
                              Text('View Diff',
                                  style: GoogleFonts.inter(
                                      fontSize: 13,
                                      color: CodeReviewTheme.textPrimary)),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'export',
                          child: Row(
                            children: [
                              const Icon(Icons.download_rounded,
                                  size: 18, color: CodeReviewTheme.textSecondary),
                              const SizedBox(width: 10),
                              Text('Export Report',
                                  style: GoogleFonts.inter(
                                      fontSize: 13,
                                      color: CodeReviewTheme.textPrimary)),
                            ],
                          ),
                        ),
                      ],
                      onSelected: (value) {
                        if (value == 'diff' && widget.result != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DiffComparisonScreen(
                                result: widget.result!,
                              ),
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Body ───────────────────────────────────────────────────────
  Widget _buildBody(CodeResultViewModel viewModel) {
    switch (viewModel.state) {
      case CodeResultState.loading:
        return const SafeArea(child: LoadingSkeleton());

      case CodeResultState.error:
        return SafeArea(
          child: ErrorStateWidget(
            onRetry: () => Navigator.pop(context),
          ),
        );

      case CodeResultState.empty:
        return SafeArea(
          child: ErrorStateWidget(
            message: 'No analysis data',
            onRetry: () => Navigator.pop(context),
          ),
        );

      case CodeResultState.success:
        return _buildSuccessBody(viewModel);
    }
  }

  Widget _buildSuccessBody(CodeResultViewModel viewModel) {
    final result = viewModel.result!;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // Spacer for app bar
        const SliverToBoxAdapter(child: SizedBox(height: 80)),

        // ─── AI Insight Card ─────────────────────────────────
        SliverToBoxAdapter(
          child: _staggeredSection(
            0,
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: AiInsightCard(
                explanation: result.explanation,
                summary: result.summary,
                overallScore: result.overallScore,
                scoreGrade: result.scoreGrade,
                scoreColor: result.scoreColor,
              ),
            ),
          ),
        ),

        // ─── Suggestions Pills ───────────────────────────────
        if (result.suggestions.isNotEmpty)
          SliverToBoxAdapter(
            child: _staggeredSection(
              0,
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: _buildSuggestionsPills(result.suggestions),
              ),
            ),
          ),

        // ─── Tab Selector ────────────────────────────────────
        SliverToBoxAdapter(
          child: _staggeredSection(
            1,
            Padding(
              padding: const EdgeInsets.only(top: 24),
              child: CodeTabSelector(
                selectedTab: viewModel.selectedTab,
                issueCount: viewModel.issueCount,
                onTabSelected: viewModel.selectTab,
              ),
            ),
          ),
        ),

        // ─── Code Viewer ─────────────────────────────────────
        SliverToBoxAdapter(
          child: _staggeredSection(
            2,
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: CodeViewerWidget(
                code: viewModel.displayCode,
                language: result.language,
                changedLines: result.changedLines,
                hasCopied: viewModel.hasCopied,
                onCopy: viewModel.copyCode,
                isFixed: viewModel.selectedTab == 1,
              ),
            ),
          ),
        ),

        // ─── Issues Section ──────────────────────────────────
        if (viewModel.groupedIssues.isNotEmpty)
          SliverToBoxAdapter(
            child: _staggeredSection(
              3,
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section title
                    Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: CodeReviewTheme.accentWarning
                                .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.bug_report_rounded,
                            size: 18,
                            color: CodeReviewTheme.accentWarning,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Issues Found',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: CodeReviewTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: CodeReviewTheme.textMuted
                                .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${viewModel.issueCount}',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: CodeReviewTheme.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Issue groups
                    ..._buildIssueGroups(viewModel),
                  ],
                ),
              ),
            ),
          ),

        // ─── Vocabulary Section ──────────────────────────────
        if (result.newVocabulary.isNotEmpty)
          SliverToBoxAdapter(
            child: _staggeredSection(
              3,
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: _buildVocabularySection(result.newVocabulary),
              ),
            ),
          ),

        // ─── Ratings Section ─────────────────────────────────
        if (result.ratings.isNotEmpty)
          SliverToBoxAdapter(
            child: _staggeredSection(
              3,
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: _buildRatingsSection(result.ratings),
              ),
            ),
          ),

        // Bottom padding
        const SliverToBoxAdapter(child: SizedBox(height: 40)),
      ],
    );
  }

  // ─── Staggered Animation Wrapper ────────────────────────────────
  Widget _staggeredSection(int index, Widget child) {
    final clampedIndex = index.clamp(0, _sectionCount - 1);
    return FadeTransition(
      opacity: _fadeAnimations[clampedIndex],
      child: SlideTransition(
        position: _slideAnimations[clampedIndex],
        child: child,
      ),
    );
  }

  // ─── Suggestions Pills ──────────────────────────────────────────
  Widget _buildSuggestionsPills(List<String> suggestions) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: suggestions.take(5).map((s) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: CodeReviewTheme.accentIndigo.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: CodeReviewTheme.accentIndigo.withValues(alpha: 0.15),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.lightbulb_outline_rounded,
                size: 14,
                color: CodeReviewTheme.accentIndigo,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  s,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: CodeReviewTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ─── Issue Groups ───────────────────────────────────────────────
  List<Widget> _buildIssueGroups(CodeResultViewModel viewModel) {
    final widgets = <Widget>[];
    int globalIndex = 0;

    for (final entry in viewModel.groupedIssues.entries) {
      widgets.add(
        IssueSectionHeader(
          severity: entry.key,
          count: entry.value.length,
        ),
      );

      for (final issue in entry.value) {
        final idx = globalIndex;
        widgets.add(
          IssueCard(
            issue: issue,
            index: idx,
            isExpanded: viewModel.isIssueExpanded(idx),
            onToggle: () => viewModel.toggleIssue(idx),
          ),
        );
        globalIndex++;
      }
    }

    return widgets;
  }

  // ─── Vocabulary Section ─────────────────────────────────────────
  Widget _buildVocabularySection(List<String> vocabulary) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CodeReviewTheme.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CodeReviewTheme.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.school_rounded,
                size: 18,
                color: CodeReviewTheme.accentPurple,
              ),
              const SizedBox(width: 8),
              Text(
                'New Vocabulary',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: CodeReviewTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: vocabulary.map((word) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: CodeReviewTheme.accentPurple.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color:
                        CodeReviewTheme.accentPurple.withValues(alpha: 0.2),
                  ),
                ),
                child: Text(
                  word,
                  style: GoogleFonts.firaCode(
                    fontSize: 12,
                    color: CodeReviewTheme.accentPurple,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ─── Ratings Section ────────────────────────────────────────────
  Widget _buildRatingsSection(Map<String, int> ratings) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CodeReviewTheme.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CodeReviewTheme.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.bar_chart_rounded,
                size: 18,
                color: CodeReviewTheme.accentIndigo,
              ),
              const SizedBox(width: 8),
              Text(
                'Quality Ratings',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: CodeReviewTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...ratings.entries.map((entry) {
            final label = entry.key
                .replaceAllMapped(
                  RegExp(r'([A-Z])'),
                  (m) => ' ${m[1]}',
                )
                .trim();
            final capitalizedLabel =
                label[0].toUpperCase() + label.substring(1);
            final value = entry.value;
            final color = value >= 80
                ? CodeReviewTheme.accentSuccess
                : value >= 60
                    ? CodeReviewTheme.accentWarning
                    : CodeReviewTheme.accentError;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        capitalizedLabel,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: CodeReviewTheme.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '$value/100',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: color,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: value / 100,
                      backgroundColor:
                          CodeReviewTheme.textMuted.withValues(alpha: 0.12),
                      valueColor: AlwaysStoppedAnimation(color),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
