import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../theme/code_review_theme.dart';

/// Sophisticated shimmer skeleton loading state for the code result screen.
class LoadingSkeleton extends StatelessWidget {
  const LoadingSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: CodeReviewTheme.shimmerBase,
      highlightColor: CodeReviewTheme.shimmerHighlight,
      period: const Duration(milliseconds: 2000),
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── AI Insight Card Skeleton ──────────────────────
            _buildInsightSkeleton(),
            const SizedBox(height: 24),

            // ─── Tab Selector Skeleton ────────────────────────
            _buildTabSkeleton(),
            const SizedBox(height: 16),

            // ─── Code Block Skeleton ──────────────────────────
            _buildCodeBlockSkeleton(),
            const SizedBox(height: 24),

            // ─── Issues Skeleton ──────────────────────────────
            _buildIssuesSkeleton(),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightSkeleton() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: CodeReviewTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              _box(24, 24, radius: 6),
              const SizedBox(width: 10),
              _box(120, 20, radius: 4),
              const Spacer(),
              _box(72, 32, radius: 12),
            ],
          ),
          const SizedBox(height: 20),

          // Summary box
          _box(double.infinity, 48, radius: 10),
          const SizedBox(height: 16),

          // Text lines
          _box(double.infinity, 12, radius: 3),
          const SizedBox(height: 10),
          _box(280, 12, radius: 3),
          const SizedBox(height: 10),
          _box(320, 12, radius: 3),
          const SizedBox(height: 10),
          _box(200, 12, radius: 3),
        ],
      ),
    );
  }

  Widget _buildTabSkeleton() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: CodeReviewTheme.cardBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Center(child: _box(110, 14, radius: 4)),
          ),
          Expanded(
            child: Center(child: _box(120, 14, radius: 4)),
          ),
        ],
      ),
    );
  }

  Widget _buildCodeBlockSkeleton() {
    return Container(
      decoration: BoxDecoration(
        color: CodeReviewTheme.cardBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Header bar
          Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: CodeReviewTheme.codeHeaderBg,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                _box(40, 16, radius: 4),
                const SizedBox(width: 10),
                _box(90, 14, radius: 4),
                const Spacer(),
                _box(50, 16, radius: 4),
              ],
            ),
          ),

          // Code lines
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(12, (i) {
                // Vary widths for realism
                final widths = [
                  180.0, 250.0, 300.0, 150.0, 280.0, 220.0,
                  160.0, 320.0, 200.0, 240.0, 130.0, 270.0,
                ];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      _box(28, 12, radius: 2),
                      const SizedBox(width: 14),
                      _box(widths[i], 12, radius: 2),
                    ],
                  ),
                );
              }),
            ),
          ),

          // Footer
          Container(
            height: 32,
            decoration: BoxDecoration(
              color: CodeReviewTheme.codeHeaderBg.withValues(alpha: 0.5),
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIssuesSkeleton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Row(
          children: [
            _box(100, 16, radius: 4),
          ],
        ),
        const SizedBox(height: 10),

        // Issue cards
        ...List.generate(3, (i) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: CodeReviewTheme.cardBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  _box(28, 28, radius: 8),
                  const SizedBox(width: 10),
                  _box(50, 16, radius: 6),
                  const SizedBox(width: 8),
                  Expanded(child: _box(double.infinity, 14, radius: 4)),
                  const SizedBox(width: 8),
                  _box(30, 16, radius: 6),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _box(double width, double height, {double radius = 4}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
