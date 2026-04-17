import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../shared/models/code_review_model.dart';

enum CodeResultState { loading, success, error, empty }

class CodeResultViewModel extends ChangeNotifier {
  CodeResultViewModel({CodeReviewResult? result}) {
    if (result != null) {
      _result = result;
      _state = CodeResultState.success;
      _organizeIssues();
    } else {
      _state = CodeResultState.empty;
    }
  }

  // ─── State ──────────────────────────────────────────────────────
  CodeResultState _state = CodeResultState.loading;
  CodeResultState get state => _state;

  CodeReviewResult? _result;
  CodeReviewResult? get result => _result;

  // ─── Tab Selection ──────────────────────────────────────────────
  int _selectedTab = 0; // 0 = original, 1 = fixed
  int get selectedTab => _selectedTab;

  void selectTab(int tab) {
    if (_selectedTab != tab) {
      _selectedTab = tab;
      notifyListeners();
    }
  }

  // ─── Issues ─────────────────────────────────────────────────────
  final Set<int> _expandedIssues = {};
  Map<String, List<CodeIssue>> _groupedIssues = {};
  Map<String, List<CodeIssue>> get groupedIssues => _groupedIssues;

  bool isIssueExpanded(int index) => _expandedIssues.contains(index);

  void toggleIssue(int index) {
    if (_expandedIssues.contains(index)) {
      _expandedIssues.remove(index);
    } else {
      _expandedIssues.add(index);
    }
    notifyListeners();
  }

  void _organizeIssues() {
    if (_result == null) return;
    _groupedIssues = {};

    final severityOrder = ['critical', 'error', 'warning', 'info'];
    for (final severity in severityOrder) {
      final issues = _result!.issues.where((i) {
        return i.severity.name == severity;
      }).toList();
      if (issues.isNotEmpty) {
        _groupedIssues[severity] = issues;
      }
    }
  }

  // ─── Copy ───────────────────────────────────────────────────────
  bool _hasCopied = false;
  bool get hasCopied => _hasCopied;

  Future<void> copyCode() async {
    final code = _selectedTab == 0 ? _result?.originalCode : _result?.fixedCode;
    if (code == null || code.isEmpty) return;

    await Clipboard.setData(ClipboardData(text: code));
    _hasCopied = true;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 2));
    _hasCopied = false;
    notifyListeners();
  }

  // ─── Display Code ───────────────────────────────────────────────
  String get displayCode {
    if (_result == null) return '';
    return _selectedTab == 0 ? _result!.originalCode : _result!.fixedCode;
  }

  List<String> get displayLines => displayCode.split('\n');

  int get issueCount => _result?.issues.length ?? 0;

  // ─── Score Info ─────────────────────────────────────────────────
  String get scoreGrade => _result?.scoreGrade ?? '-';
  int get overallScore => _result?.overallScore ?? 0;
  String get scoreLabel => _result?.scoreLabel ?? '';
  Color get scoreColor => _result?.scoreColor ?? Colors.grey;
}
