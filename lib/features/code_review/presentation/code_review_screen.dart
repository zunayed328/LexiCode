import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/providers/app_provider.dart';
import '../../../core/services/ai_service.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/gradient_button.dart';
import 'code_result_screen.dart';

class CodeReviewScreen extends StatefulWidget {
  const CodeReviewScreen({super.key});

  @override
  State<CodeReviewScreen> createState() => _CodeReviewScreenState();
}

class _CodeReviewScreenState extends State<CodeReviewScreen>
    with TickerProviderStateMixin {
  final TextEditingController _codeController = TextEditingController();
  late AnimationController _pulseController;
  late AnimationController _stepController;
  int _currentStep = 0;
  int _lineCount = 0;
  int _charCount = 0;

  final List<_AnalysisStep> _analysisSteps = [
    _AnalysisStep('Checking syntax errors', Icons.code_off_rounded),
    _AnalysisStep('Detecting logic bugs', Icons.bug_report_rounded),
    _AnalysisStep('Analyzing security', Icons.security_rounded),
    _AnalysisStep('Checking performance', Icons.speed_rounded),
    _AnalysisStep('Generating suggestions', Icons.auto_awesome_rounded),
  ];

  // Quick examples
  static const Map<String, Map<String, String>> _quickExamples = {
    'Bug Fix': {
      'Dart': '''void fetchUserData(var userId) {
  print("Fetching user: " + userId);
  var data = api.get("/users/" + userId);
  var name = data["name"];
  var email = data["email"];
  // TODO: add error handling
  return data;
}''',
      'Python': '''def calculate(x, y):
  result = x / y
  print("Result: " + str(result))
  return result

data = calculate(10, 0)
print(data)''',
      'JavaScript': '''function fetchUser(userId) {
  var data = fetch("/api/users/" + userId);
  var name = data.name;
  console.log("User: " + name);
  // TODO: handle errors
  return data;
}''',
    },
    'Performance': {
      'Dart': '''List<int> findDuplicates(List<int> items) {
  List<int> duplicates = [];
  for (var i = 0; i < items.length; i++) {
    for (var j = i + 1; j < items.length; j++) {
      if (items[i] == items[j]) {
        if (!duplicates.contains(items[i])) {
          duplicates.add(items[i]);
        }
      }
    }
  }
  return duplicates;
}''',
      'Python': '''def find_duplicates(items):
    duplicates = []
    for i in range(len(items)):
        for j in range(i + 1, len(items)):
            if items[i] == items[j]:
                if items[i] not in duplicates:
                    duplicates.append(items[i])
    return duplicates''',
      'JavaScript': '''function findDuplicates(items) {
  var duplicates = [];
  for (var i = 0; i < items.length; i++) {
    for (var j = i + 1; j < items.length; j++) {
      if (items[i] === items[j]) {
        if (!duplicates.includes(items[i])) {
          duplicates.push(items[i]);
        }
      }
    }
  }
  return duplicates;
}''',
    },
    'Refactor': {
      'Dart': '''String processOrder(Map order) {
  var total = 0.0;
  var items = order["items"];
  for (var i = 0; i < items.length; i++) {
    var price = items[i]["price"];
    var qty = items[i]["qty"];
    total = total + (price * qty);
  }
  if (total > 100) {
    total = total * 0.9;
  }
  if (total > 50) {
    total = total + 5.0;
  } else {
    total = total + 10.0;
  }
  print("Total: " + total.toString());
  return total.toString();
}''',
      'Python': '''def process_order(order):
    total = 0
    items = order["items"]
    for i in range(len(items)):
        price = items[i]["price"]
        qty = items[i]["qty"]
        total = total + (price * qty)
    if total > 100:
        total = total * 0.9
    if total > 50:
        total = total + 5.0
    else:
        total = total + 10.0
    print("Total: " + str(total))
    return str(total)''',
      'JavaScript': '''function processOrder(order) {
  var total = 0;
  var items = order.items;
  for (var i = 0; i < items.length; i++) {
    var price = items[i].price;
    var qty = items[i].qty;
    total = total + (price * qty);
  }
  if (total > 100) {
    total = total * 0.9;
  }
  if (total > 50) {
    total = total + 5.0;
  } else {
    total = total + 10.0;
  }
  console.log("Total: " + total);
  return total.toString();
}''',
    },
    'Syntax Error': {
      'Dart': '''void main() {
  var name = "hello"
  if (name == "hello") {
    pritn("Found it!")
  }
  var items = [1, 2, 3
  retrun items;
}''',
      'Python': '''deff calculate(x, y)
  if x > 0
    result = x / y
  print "Result: " + str(result)
  retrun result

data = calculate(10, 0
print(data)''',
      'JavaScript': '''fucntion fetchUser(userId) {
  cnst data = fetch("/api/" + userId)
  var name = data.name
  console.log("User: " + name)
  retrun data
}''',
    },
  };

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _stepController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _codeController.addListener(_updateCounts);
  }

  void _updateCounts() {
    final text = _codeController.text;
    setState(() {
      _charCount = text.length;
      _lineCount = text.isEmpty ? 0 : text.split('\n').length;
    });
  }

  @override
  void dispose() {
    _codeController.dispose();
    _pulseController.dispose();
    _stepController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(provider, isDark)),
            SliverToBoxAdapter(child: _buildLanguageSelector(provider, isDark)),
            SliverToBoxAdapter(child: _buildCodeEditor(provider, isDark)),
            SliverToBoxAdapter(child: _buildQuickExamples(provider, isDark)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: provider.isReviewing
                    ? _buildAnalyzingState(isDark)
                    : GradientButton(
                        text: '🔍  Analyze Code',
                        onPressed: _codeController.text.trim().isEmpty
                            ? () {}
                            : () => _analyzeCode(context),
                        width: double.infinity,
                      ),
              ),
            ),
            SliverToBoxAdapter(child: _buildTips(isDark)),
            if (provider.reviewHistory.isNotEmpty)
              SliverToBoxAdapter(child: _buildHistory(provider, isDark)),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  // ─── Header ─────────────────────────────────────────────────────

  Widget _buildHeader(AppProvider provider, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(13),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(
              Icons.code_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Code Review',
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'AI-powered code analysis',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.rate_review_rounded,
                  color: AppColors.primary,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  '${provider.user.codeReviewsCompleted}',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Language Selector ──────────────────────────────────────────

  Widget _buildLanguageSelector(AppProvider provider, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Programming Language',
            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: AppStrings.programmingLanguages.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final lang = AppStrings.programmingLanguages[index];
                final isSelected = provider.selectedLanguage == lang;
                return GestureDetector(
                  onTap: () => provider.setSelectedLanguage(lang),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      gradient: isSelected ? AppColors.primaryGradient : null,
                      color: isSelected
                          ? null
                          : (isDark
                                ? AppColors.darkCard
                                : AppColors.lightSurface),
                      borderRadius: BorderRadius.circular(20),
                      border: isSelected
                          ? null
                          : Border.all(
                              color: isDark
                                  ? AppColors.darkBorder
                                  : AppColors.lightBorder,
                            ),
                    ),
                    child: Text(
                      lang,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: isSelected
                            ? Colors.white
                            : (isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ─── Code Editor with Line Numbers ──────────────────────────────

  Widget _buildCodeEditor(AppProvider provider, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Your Code',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Row(
                children: [
                  // Character/line count
                  Text(
                    '$_lineCount lines · $_charCount chars',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Paste button
                  GestureDetector(
                    onTap: () async {
                      final data = await Clipboard.getData(
                        Clipboard.kTextPlain,
                      );
                      if (data?.text != null) {
                        _codeController.text = data!.text!;
                        // Auto-detect language and update the selected chip
                        final detected = _detectLanguage(data.text!);
                        if (detected != null) {
                          context.read<AppProvider>().setSelectedLanguage(
                            detected,
                          );
                        }
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.content_paste_rounded,
                            size: 14,
                            color: AppColors.primary,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Paste',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Clear button
                  GestureDetector(
                    onTap: () => _codeController.clear(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkCard
                            : AppColors.lightDivider,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.delete_outline_rounded,
                            size: 14,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Clear',
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
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: AppColors.codeBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.darkBorder.withValues(alpha: 0.5),
              ),
            ),
            child: Column(
              children: [
                // Title bar with dots
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: const BoxDecoration(
                    color: AppColors.codeSurface,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      ...[0xFFFF5555, 0xFFFFB86C, 0xFF50FA7B].map(
                        (hex) => Container(
                          width: 10,
                          height: 10,
                          margin: const EdgeInsets.only(right: 6),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(hex),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${provider.selectedLanguage.toLowerCase()}_code.${_getExt(provider.selectedLanguage)}',
                        style: GoogleFonts.firaCode(
                          fontSize: 12,
                          color: AppColors.darkTextSecondary,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.fullscreen_rounded,
                        size: 18,
                        color: AppColors.darkTextSecondary.withValues(
                          alpha: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                // Code input
                ConstrainedBox(
                  constraints: const BoxConstraints(
                    minHeight: 180,
                    maxHeight: 350,
                  ),
                  child: TextField(
                    controller: _codeController,
                    maxLines: null,
                    minLines: 8,
                    style: GoogleFonts.firaCode(
                      fontSize: 13,
                      color: AppColors.darkText,
                      height: 1.6,
                    ),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.codeBackground,
                      hintText: 'Paste your code here...',
                      hintStyle: GoogleFonts.firaCode(
                        color: AppColors.darkTextSecondary.withValues(
                          alpha: 0.4,
                        ),
                        fontSize: 13,
                      ),
                      border: const OutlineInputBorder(
                        borderRadius: BorderRadius.vertical(
                          bottom: Radius.circular(16),
                        ),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.all(16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Quick Examples ─────────────────────────────────────────────

  Widget _buildQuickExamples(AppProvider provider, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.lightbulb_rounded,
                color: AppColors.xpColor,
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                'Quick Examples',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _quickExamples.keys.map((label) {
              final IconData icon;
              final Color color;
              switch (label) {
                case 'Bug Fix':
                  icon = Icons.bug_report_rounded;
                  color = const Color(0xFFFF4757);
                  break;
                case 'Performance':
                  icon = Icons.speed_rounded;
                  color = const Color(0xFFFFB800);
                  break;
                default:
                  icon = Icons.autorenew_rounded;
                  color = AppColors.primary;
              }
              return GestureDetector(
                onTap: () {
                  final lang = provider.selectedLanguage;
                  final examples = _quickExamples[label]!;
                  _codeController.text = examples[lang] ?? examples['Dart']!;
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: color.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: 16, color: color),
                      const SizedBox(width: 6),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ─── Analyzing State (Multi-Step) ───────────────────────────────

  Widget _buildAnalyzingState(bool isDark) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(
            alpha: 0.05 + (_pulseController.value * 0.05),
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.primary.withValues(
              alpha: 0.2 + (_pulseController.value * 0.15),
            ),
          ),
        ),
        child: Column(
          children: [
            const SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(AppColors.primary),
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Analyzing Your Code...',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            ..._analysisSteps.asMap().entries.map((e) {
              final idx = e.key;
              final step = e.value;
              final isComplete = idx < _currentStep;
              final isCurrent = idx == _currentStep;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: isComplete
                          ? const Icon(
                              Icons.check_circle_rounded,
                              color: Color(0xFF00D68F),
                              size: 20,
                              key: ValueKey('done'),
                            )
                          : isCurrent
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(
                                  AppColors.primary,
                                ),
                              ),
                            )
                          : Icon(
                              Icons.circle_outlined,
                              color: Colors.grey.shade400,
                              size: 20,
                              key: const ValueKey('pending'),
                            ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      step.label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isCurrent
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: isComplete
                            ? const Color(0xFF00D68F)
                            : isCurrent
                            ? AppColors.primary
                            : (isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary),
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 8),
            Text(
              'This may take 5-10 seconds',
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

  // ─── Tips ───────────────────────────────────────────────────────

  Widget _buildTips(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.tips_and_updates_rounded,
                  color: AppColors.xpColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Pro Tips',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...[
              'Paste your actual project code for best results',
              'Each review earns you +25 XP points',
              'Switch between Suggestions & Fixed Code tabs',
              'Check the vocabulary section for new tech terms',
            ].map(
              (t) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 4,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        t,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── History ────────────────────────────────────────────────────

  Widget _buildHistory(AppProvider provider, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Recent Reviews',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                '${provider.reviewHistory.length} total',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...provider.reviewHistory
              .take(5)
              .map(
                (review) => GlassCard(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CodeResultScreen(result: review),
                    ),
                  ),
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: review.scoreColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            '${review.overallScore}',
                            style: TextStyle(
                              color: review.scoreColor,
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${review.language} Code Review',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '${review.issues.length} issues · Score: ${review.overallScore}/100',
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
                      const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }

  // ─── Analyze Code ───────────────────────────────────────────────

  Future<void> _analyzeCode(BuildContext context) async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter some code to review'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    final provider = context.read<AppProvider>();

    // Start step animation
    setState(() => _currentStep = 0);
    _startStepAnimation();

    try {
      final result = await provider.reviewCode(code);
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => CodeResultScreen(result: result)),
        );
      }
    } on LanguageMismatchException catch (e) {
      if (!mounted) return;
      _showLanguageMismatchDialog(context, e, provider);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Analysis failed: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  void _showLanguageMismatchDialog(
    BuildContext context,
    LanguageMismatchException e,
    AppProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
        ),
        icon: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.warning.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.warning_amber_rounded,
            color: AppColors.warning,
            size: 32,
          ),
        ),
        title: Text(
          'Language Mismatch',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: Colors.white,
          ),
        ),
        content: RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.white70,
              height: 1.5,
            ),
            children: [
              const TextSpan(text: 'This looks like '),
              TextSpan(
                text: e.detectedLanguage,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const TextSpan(text: ' code, but you selected '),
              TextSpan(
                text: e.selectedLanguage,
                style: const TextStyle(
                  color: AppColors.error,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const TextSpan(
                text:
                    '.\n\nPlease select the correct language chip before analyzing.',
              ),
            ],
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Dismiss',
              style: GoogleFonts.inter(
                color: Colors.white54,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            onPressed: () {
              provider.setSelectedLanguage(e.detectedLanguage);
              Navigator.pop(ctx);
            },
            icon: const Icon(Icons.swap_horiz_rounded, size: 18),
            label: Text(
              'Switch to ${e.detectedLanguage}',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _startStepAnimation() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return false;
      if (_currentStep < _analysisSteps.length - 1) {
        setState(() => _currentStep++);
        return true;
      }
      return false;
    });
  }

  // ─── Language Auto-Detection ────────────────────────────────────

  /// Detects the programming language of the given [code] by scanning
  /// for strong keyword indicators. Returns the language name or `null`.
  String? _detectLanguage(String code) {
    const signatures = <String, List<String>>{
      'C++': [
        '#include',
        'std::',
        'cout',
        'cin',
        'using namespace',
        'int main(',
        'endl',
      ],
      'Dart': [
        "import 'package:",
        'void main(',
        '@override',
        'StatelessWidget',
        'StatefulWidget',
        'BuildContext',
        'Widget ',
        'setState(',
      ],
      'Python': [
        'def ',
        'elif ',
        "if __name__ == '__main__':",
        'self.',
        '__init__',
        'import ',
        'from ',
        'print(',
      ],
      'Java': [
        'public class',
        'System.out.println',
        'package ',
        'import java.',
        '@Override',
        'void main(String',
      ],
      'JavaScript': [
        'console.log',
        'function ',
        'const ',
        'let ',
        'document.',
        'require(',
        'module.exports',
        '=>',
      ],
      'TypeScript': [
        'interface ',
        ': string',
        ': number',
        ': boolean',
        'import {',
        'export ',
        'type ',
      ],
      'Kotlin': [
        'fun ',
        'val ',
        'println(',
        'suspend ',
        'override fun',
        'companion object',
        'data class',
      ],
      'Swift': [
        'func ',
        'import UIKit',
        'import Foundation',
        'guard ',
        '@IBOutlet',
        'override func',
      ],
      'Go': [
        'package main',
        'func main()',
        'fmt.',
        'import (',
        ':= ',
        'func (',
      ],
      'Rust': [
        'fn main()',
        'let mut',
        'println!',
        'use std::',
        'impl ',
        'pub fn',
      ],
      'C#': [
        'using System',
        'namespace ',
        'Console.Write',
        'static void Main',
        'get;',
        'set;',
      ],
      'PHP': ['<?php', 'echo ', '\$this->', '::class'],
    };

    int bestScore = 0;
    String? bestLang;

    for (final entry in signatures.entries) {
      int hits = 0;
      for (final kw in entry.value) {
        if (code.contains(kw)) hits++;
      }
      if (hits > bestScore) {
        bestScore = hits;
        bestLang = entry.key;
      }
    }

    // Require at least 2 keyword hits to be confident
    return bestScore >= 2 ? bestLang : null;
  }

  String _getExt(String lang) {
    const map = {
      'Dart': 'dart',
      'Python': 'py',
      'JavaScript': 'js',
      'TypeScript': 'ts',
      'Java': 'java',
      'Kotlin': 'kt',
      'Swift': 'swift',
      'Go': 'go',
      'Rust': 'rs',
      'C++': 'cpp',
      'C#': 'cs',
      'PHP': 'php',
    };
    return map[lang] ?? 'txt';
  }
}

class _AnalysisStep {
  final String label;
  final IconData icon;
  const _AnalysisStep(this.label, this.icon);
}
