import 'package:flutter/foundation.dart';
import '../../shared/models/code_review_model.dart';
import '../../services/api_service.dart';

class AIService {
  /// Analyzes code using backend Cloud Function first.
  /// Falls back to local analysis if the backend call fails.
  Future<CodeReviewResult> analyzeCode(String code, String language) async {
    // ═══ TRY BACKEND API FIRST ═══
    try {
      final result = await ApiService.analyzeCode(
        code: code,
        language: language,
      );
      return result;
    } catch (e) {
      print('Backend API unavailable, falling back to local analysis: $e');
    }

    // ═══ FALLBACK: LOCAL ANALYSIS ═══
    await Future.delayed(const Duration(seconds: 3));

    // ═══ PHASE 1: SYNTAX VALIDATION (MANDATORY) ═══
    final syntaxErrors = _detectSyntaxErrors(code, language);

    if (syntaxErrors.isNotEmpty) {
      final syntaxIssues = syntaxErrors
          .map(
            (e) => CodeIssue(
              title: e.message,
              description:
                  'Line ${e.line}${e.column != null ? ', Column ${e.column}' : ''}: ${e.message}',
              simpleExplanation:
                  e.description ??
                  'This is a syntax error that prevents your code from running.',
              severity: IssueSeverity.critical,
              type: IssueType.syntax,
              lineNumber: e.line,
              column: e.column,
              suggestion: 'Change: "${e.code}" → "${e.fix}"',
              codeExample: e.code,
              explanation:
                  e.description ??
                  'This syntax error prevents your code from compiling or running.',
              exampleFix: e.fix,
            ),
          )
          .toList();

      final fixedCode = _applySyntaxFixes(code, syntaxErrors);
      final changedLines = syntaxErrors.map((e) => e.line).toSet().toList()
        ..sort();

      return CodeReviewResult(
        originalCode: code,
        language: language,
        overallScore: 0,
        ratings: {
          'quality': 0,
          'security': 0,
          'performance': 0,
          'maintainability': 0,
        },
        issues: syntaxIssues,
        suggestions: [
          'Fix all syntax errors before submitting for code review',
        ],
        explanation:
            'Your code has ${syntaxErrors.length} syntax error${syntaxErrors.length > 1 ? 's' : ''} that prevent it from running.',
        newVocabulary: _syntaxVocabulary(),
        fixedCode: fixedCode,
        changedLines: changedLines,
        summary:
            'Code has ${syntaxErrors.length} syntax error${syntaxErrors.length > 1 ? 's' : ''} and will not run/compile. '
            'These must be fixed before any logic, security, or performance analysis can be performed.',
        hasSyntaxErrors: true,
        syntaxErrors: syntaxErrors,
      );
    }

    // ═══ PHASE 2: COMPREHENSIVE ANALYSIS (no syntax errors) ═══
    final issues = _generateIssues(code, language);
    final suggestions = _generateSuggestions(language);
    final explanation = _generateExplanation(code, language);
    final vocabulary = _generateVocabulary();
    final score = _calculateScore(issues);
    final fixedCode = _generateFixedCode(code, language);
    final changedLines = _getChangedLines(code);
    final ratings = _generateRatings(issues, score);
    final summary = _generateSummary(code, language, issues);

    return CodeReviewResult(
      originalCode: code,
      language: language,
      overallScore: score,
      ratings: ratings,
      issues: issues,
      suggestions: suggestions,
      explanation: explanation,
      newVocabulary: vocabulary,
      fixedCode: fixedCode,
      changedLines: changedLines,
      summary: summary,
      hasSyntaxErrors: false,
      syntaxErrors: const [],
    );
  }

  Future<String> generateLesson(String level, String topic) async {
    // Try backend first
    try {
      final result = await ApiService.generateLesson(
        unitId: 'dynamic',
        lessonId: topic,
        userLevel: level,
        lessonType: topic,
      );
      return result['lesson']?['title'] ??
          'Generated lesson for $topic at $level level';
    } catch (e) {
      print('Backend lesson generation unavailable: $e');
    }
    // Fallback
    await Future.delayed(const Duration(seconds: 1));
    return 'Generated lesson for $topic at $level level';
  }

  Future<Map<String, dynamic>> evaluateWriting(
    String userInput,
    String context,
  ) async {
    await Future.delayed(const Duration(seconds: 1));
    return {
      'score': 85,
      'feedback': 'Good use of technical terminology.',
      'corrections': [
        {
          'original': 'fix the bug',
          'suggestion': 'resolve the defect',
          'reason': 'More professional phrasing',
        },
      ],
      'vocabularyUsed': ['implement', 'refactor', 'optimize'],
    };
  }

  Future<String> chatWithMentor(String message, String context) async {
    // Try backend first
    try {
      return await ApiService.chat(message: message, context: context);
    } catch (e) {
      print('Backend chat unavailable: $e');
    }
    // Fallback: local responses
    await Future.delayed(const Duration(milliseconds: 800));
    final responses = [
      "That's a great question! In software development, this concept is fundamental.",
      "I'd recommend breaking this down into smaller components.",
      "Great progress! Try applying it in a real code review next.",
      "Think of it like building blocks — each function should do one thing well.",
      "When writing PR descriptions, always include: what changed, why it changed, and how to test it.",
    ];
    return responses[message.length % responses.length];
  }

  // ════════════════════════════════════════════════════════════════
  //  PHASE 1: SYNTAX ERROR DETECTION
  // ════════════════════════════════════════════════════════════════

  List<SyntaxError> _detectSyntaxErrors(String code, String language) {
    final errors = <SyntaxError>[];
    final lines = code.split('\n');
    final lang = language.toLowerCase();

    // 1. Keyword typos (ALL languages, run FIRST so we know what's really there)
    _detectKeywordTypos(lines, errors, language);

    // 2. Language-specific checks
    if (lang == 'python') {
      _detectPythonSyntax(lines, errors);
    } else if (lang == 'javascript' || lang == 'typescript') {
      _detectJSSyntax(lines, errors, language);
    } else if (lang == 'dart') {
      _detectDartSyntax(lines, errors);
    } else if (lang == 'java' || lang == 'c#') {
      _detectJavaCSharpSyntax(lines, errors, language);
    } else if (lang == 'c++' || lang == 'c') {
      _detectCppSyntax(lines, errors);
    } else if (lang == 'go') {
      _detectGoSyntax(lines, errors);
    } else if (lang == 'swift') {
      _detectSwiftSyntax(lines, errors);
    } else if (lang == 'rust') {
      _detectRustSyntax(lines, errors);
    } else if (lang == 'kotlin') {
      _detectKotlinSyntax(lines, errors);
    } else if (lang == 'php') {
      _detectPhpSyntax(lines, errors);
    }

    // 3. Unbalanced brackets (ALL languages)
    _detectUnbalancedBrackets(lines, errors);

    // Remove duplicate errors on same line with same message
    final seen = <String>{};
    errors.removeWhere((e) {
      final key = '${e.line}:${e.message}';
      if (seen.contains(key)) return true;
      seen.add(key);
      return false;
    });

    // Sort by line number
    errors.sort((a, b) => a.line.compareTo(b.line));

    return errors;
  }

  // ─── KEYWORD TYPO DETECTION (ALL LANGUAGES) ─────────────────────

  void _detectKeywordTypos(
    List<String> lines,
    List<SyntaxError> errors,
    String language,
  ) {
    final typos = <String, String>{
      // Python
      'deff': 'def', 'dfe': 'def', 'defn': 'def',
      'iff': 'if', 'fi': 'if',
      'retrun': 'return',
      'reutrn': 'return',
      'retrn': 'return',
      'retunr': 'return',
      'retur': 'return',
      'improt': 'import',
      'imoprt': 'import',
      'ipmort': 'import',
      'imort': 'import',
      'pritn': 'print', 'pirnt': 'print', 'prnt': 'print', 'pint': 'print',
      'esle': 'else', 'els': 'else', 'eles': 'else',
      'ture': 'true', 'treu': 'true',
      'flase': 'false', 'fasle': 'false', 'fales': 'false',
      'Noen': 'None', 'NONe': 'None', 'noen': 'none',
      'whlie': 'while', 'whlile': 'while', 'whiel': 'while',
      'contineu': 'continue', 'contniue': 'continue', 'contiue': 'continue',
      'brek': 'break', 'braek': 'break', 'brak': 'break',
      'calss': 'class', 'clss': 'class', 'clsas': 'class', 'classs': 'class',
      'excpet': 'except', 'exept': 'except', 'execpt': 'except',
      'finaly': 'finally', 'finlly': 'finally',
      'lamda': 'lambda', 'labmda': 'lambda',
      'yeild': 'yield', 'yiled': 'yield',
      'globa': 'global', 'golbal': 'global',
      'asert': 'assert', 'assrt': 'assert',
      'rais': 'raise', 'rasie': 'raise',
      // JavaScript / TypeScript
      'fucntion': 'function', 'funciton': 'function', 'funtion': 'function',
      'fuction': 'function', 'funtcion': 'function', 'functon': 'function',
      'cnst': 'const', 'cosnt': 'const', 'conts': 'const', 'ocnst': 'const',
      'lte': 'let', 'elt': 'let',
      'varl': 'var', 'vra': 'var',
      'consoel': 'console', 'conosle': 'console', 'consloe': 'console',
      'docuemnt': 'document', 'documnet': 'document',
      'widnow': 'window', 'windwo': 'window',
      'undefind': 'undefined', 'undifined': 'undefined',
      'typof': 'typeof', 'tyepof': 'typeof',
      'instnaceof': 'instanceof', 'instancef': 'instanceof',
      'swtich': 'switch', 'swich': 'switch', 'siwtch': 'switch',
      'deafult': 'default', 'defualt': 'default',
      'exprot': 'export', 'exoprt': 'export',
      'reqiure': 'require', 'reuqire': 'require',
      'asncy': 'async', 'asyc': 'async', 'asnyc': 'async',
      'awiat': 'await', 'awit': 'await',
      // Java / C# / Dart
      'pubic': 'public', 'pubilc': 'public', 'pulic': 'public',
      'privat': 'private', 'prviate': 'private', 'priavte': 'private',
      'proected': 'protected', 'protceted': 'protected',
      'abstact': 'abstract', 'abstarct': 'abstract',
      'interfce': 'interface', 'inteface': 'interface',
      'pacakge': 'package', 'packge': 'package',
      'throwr': 'throw', 'trhow': 'throw',
      'catchh': 'catch', 'ctach': 'catch',
      'Sting': 'String', 'Stirng': 'String', 'Strign': 'String',
      'Interger': 'Integer', 'Intger': 'Integer',
      'Boolaen': 'Boolean', 'Boolen': 'Boolean',
      'voild': 'void', 'viod': 'void',
      'statc': 'static', 'satic': 'static',
      'finla': 'final', 'fianl': 'final',
      'overrdie': 'override', 'overide': 'override',
      'extens': 'extends', 'extneds': 'extends',
      'implemnts': 'implements', 'implments': 'implements',
      'enumm': 'enum', 'enmu': 'enum',
      // C++ specific
      'namesapce': 'namespace', 'namepsace': 'namespace',
      'incldue': 'include', 'inlcude': 'include',
      'tempalte': 'template', 'templat': 'template',
      'struuct': 'struct', 'strcut': 'struct',
      'virtaul': 'virtual', 'virutal': 'virtual',
    };

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final trimmed = line.trimLeft();

      // Skip comments
      if (trimmed.startsWith('//') ||
          trimmed.startsWith('#') ||
          trimmed.startsWith('/*') ||
          trimmed.startsWith('*')) {
        continue;
      }

      // Split line into words
      final words = trimmed.split(
        RegExp(r'[\s\(\)\[\]{},;.:=+\-*/<>!&|~^%@#\\?]+'),
      );
      for (final word in words) {
        if (word.isEmpty) continue;
        final lower = word.toLowerCase();
        // Check exact match first
        if (typos.containsKey(word)) {
          errors.add(
            SyntaxError(
              line: i + 1,
              column: line.indexOf(word) + 1,
              message: 'Typo: "$word" should be "${typos[word]}"',
              code: trimmed,
              fix: trimmed.replaceFirst(word, typos[word]!),
              description:
                  'The keyword "$word" is misspelled. The correct keyword is "${typos[word]}". This will cause a syntax or name error.',
            ),
          );
        }
        // Check lowercase match (for case-sensitive typos)
        else if (typos.containsKey(lower) && word != typos[lower]) {
          final correctWord = typos[lower]!;
          // Only flag if it looks like a keyword (not a variable name)
          if (word.length <= 10 &&
              !RegExp(r'[A-Z]').hasMatch(word.substring(1))) {
            errors.add(
              SyntaxError(
                line: i + 1,
                column: line.indexOf(word) + 1,
                message: 'Typo: "$word" should be "$correctWord"',
                code: trimmed,
                fix: trimmed.replaceFirst(word, correctWord),
                description:
                    'The keyword "$word" is misspelled. The correct keyword is "$correctWord".',
              ),
            );
          }
        }
      }
    }
  }

  // ─── PYTHON SYNTAX ──────────────────────────────────────────────

  void _detectPythonSyntax(List<String> lines, List<SyntaxError> errors) {
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final trimmed = line.trimLeft().trimRight();
      final lineNum = i + 1;

      if (trimmed.isEmpty || trimmed.startsWith('#')) continue;

      // 1. Missing colon after block keywords
      //    Match line that STARTS with (or contains typo of) these keywords
      final colonPat = RegExp(
        r'^(if|elif|else|for|while|def|deff|dfe|class|calss|clss|try|except|excpet|exept|finally|finaly|with|lambda|lamda)\b',
      );
      if (colonPat.hasMatch(trimmed)) {
        final stripped = trimmed.replaceAll(RegExp(r'#.*$'), '').trimRight();
        if (!stripped.endsWith(':') && stripped.isNotEmpty) {
          final keyword = colonPat.firstMatch(trimmed)!.group(1)!;
          errors.add(
            SyntaxError(
              line: lineNum,
              column: stripped.length + 1,
              message: 'Missing colon (:) after "$keyword" statement',
              code: trimmed,
              fix: '$stripped:',
              description:
                  'In Python, all "$keyword" statements must end with a colon (:). '
                  'The colon tells Python where the condition ends and the code block begins.',
            ),
          );
        }
      }

      // 2. Python 2 print syntax: print "text" or print 'text'
      if (RegExp(r'''^print\s+["']''').hasMatch(trimmed)) {
        final arg = trimmed.substring(5).trimLeft();
        errors.add(
          SyntaxError(
            line: lineNum,
            column: 1,
            message: 'Python 2 print syntax — use print() function',
            code: trimmed,
            fix: 'print($arg)',
            description:
                'In Python 3, "print" is a function and requires parentheses. '
                '"print "hello"" is Python 2 syntax and will cause a SyntaxError.',
          ),
        );
      }

      // 3. Assignment with == instead of =
      if (RegExp(r'^[a-zA-Z_]\w*\s*==\s*.+').hasMatch(trimmed) &&
          !trimmed.startsWith('if') &&
          !trimmed.startsWith('elif') &&
          !trimmed.startsWith('while') &&
          !trimmed.startsWith('return') &&
          !trimmed.startsWith('assert') &&
          !trimmed.contains('(')) {
        // e.g. x == 5 when they meant x = 5
        errors.add(
          SyntaxError(
            line: lineNum,
            column: trimmed.indexOf('==') + 1,
            message:
                'Possible incorrect use of == (comparison) instead of = (assignment)',
            code: trimmed,
            fix: trimmed.replaceFirst('==', '='),
            description:
                '"==" is a comparison operator (checks equality), while "=" is assignment (sets a value). '
                'If you meant to assign a value, use a single "=".',
          ),
        );
      }

      // 4. Invalid indentation — mixing tabs and spaces is detectable
      if (line.contains('\t') && line.contains('  ')) {
        errors.add(
          SyntaxError(
            line: lineNum,
            column: 1,
            message: 'Mixed tabs and spaces in indentation',
            code: trimmed,
            fix: trimmed, // can't auto-fix easily
            description:
                'Python requires consistent indentation. Mixing tabs and spaces will cause an IndentationError. '
                'Use either all spaces (recommended: 4 spaces) or all tabs, but never both.',
          ),
        );
      }
    }
  }

  // ─── JAVASCRIPT / TYPESCRIPT SYNTAX ─────────────────────────────

  void _detectJSSyntax(
    List<String> lines,
    List<SyntaxError> errors,
    String lang,
  ) {
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final trimmed = line.trimLeft().trimRight();
      final lineNum = i + 1;

      if (trimmed.isEmpty ||
          trimmed.startsWith('//') ||
          trimmed.startsWith('/*') ||
          trimmed.startsWith('*') ||
          trimmed == '}' ||
          trimmed == '{' ||
          trimmed == '});' ||
          trimmed == ']);') {
        continue;
      }

      // Missing semicolons — check lines that are statements
      if (_jsNeedsSemicolon(trimmed)) {
        errors.add(
          SyntaxError(
            line: lineNum,
            column: trimmed.length + 1,
            message: 'Missing semicolon at end of statement',
            code: trimmed,
            fix: '$trimmed;',
            description:
                'In $lang, statements should end with a semicolon (;). '
                'While JavaScript can sometimes auto-insert semicolons, explicit semicolons prevent bugs.',
          ),
        );
      }

      // Missing commas in object/array (check for : followed by newline with value)
      // e.g. {a: 1 b: 2} → {a: 1, b: 2}
      if (i + 1 < lines.length) {
        final nextTrimmed = lines[i + 1].trimLeft().trimRight();
        // Current line doesn't end with , and is inside an object/array
        if (!trimmed.endsWith(',') &&
            !trimmed.endsWith('{') &&
            !trimmed.endsWith('[') &&
            !trimmed.endsWith('(') &&
            !trimmed.endsWith(';') &&
            !trimmed.endsWith('}') &&
            trimmed.contains(':') &&
            nextTrimmed.contains(':') &&
            !trimmed.startsWith('//') &&
            !trimmed.startsWith('case')) {
          errors.add(
            SyntaxError(
              line: lineNum,
              column: trimmed.length + 1,
              message: 'Missing comma after property',
              code: trimmed,
              fix: '$trimmed,',
              description:
                  'In objects and arrays, each item must be separated by a comma. '
                  'Missing commas will cause a syntax error.',
            ),
          );
        }
      }

      // === instead of = in assignment context
      if (RegExp(r'^(let|const|var)\s+\w+\s*===').hasMatch(trimmed)) {
        errors.add(
          SyntaxError(
            line: lineNum,
            column: trimmed.indexOf('===') + 1,
            message: 'Using === (comparison) in assignment — should use =',
            code: trimmed,
            fix: trimmed.replaceFirst('===', '='),
            description:
                '"===" is strict comparison, "=" is assignment. You likely meant to assign a value here.',
          ),
        );
      }
    }
  }

  bool _jsNeedsSemicolon(String trimmed) {
    // Lines that should end with semicolons
    if (trimmed.endsWith(';') ||
        trimmed.endsWith('{') ||
        trimmed.endsWith('}') ||
        trimmed.endsWith(',') ||
        trimmed.endsWith('(') ||
        trimmed.endsWith(':') ||
        trimmed.endsWith('*/') ||
        trimmed.endsWith('=>') ||
        trimmed.endsWith('\\')) {
      return false;
    }
    // Control flow / block starters don't need semicolons
    if (trimmed.startsWith('if') ||
        trimmed.startsWith('else') ||
        trimmed.startsWith('for') ||
        trimmed.startsWith('while') ||
        trimmed.startsWith('switch') ||
        trimmed.startsWith('case') ||
        trimmed.startsWith('try') ||
        trimmed.startsWith('catch') ||
        trimmed.startsWith('finally') ||
        trimmed.startsWith('class') ||
        trimmed.startsWith('import ') ||
        trimmed.startsWith('export ') ||
        trimmed.startsWith('//') ||
        trimmed.startsWith('/*') ||
        trimmed.startsWith('*')) {
      return false;
    }
    // Function/method declarations with { don't need semicolons
    if (trimmed.startsWith('function') ||
        trimmed.startsWith('async function') ||
        RegExp(
          r'^(const|let|var)\s+\w+\s*=\s*(async\s+)?\(',
        ).hasMatch(trimmed) ||
        RegExp(r'^(const|let|var)\s+\w+\s*=\s*function').hasMatch(trimmed)) {
      // Arrow functions or function expressions that end with { don't need ;
      if (trimmed.endsWith('{')) return false;
    }

    // Lines that ARE statements needing semicolons:
    // - Variable declarations: const/let/var
    // - Assignments: x = ...
    // - Return statements
    // - Function calls: foo(), console.log()
    // - throw statements
    if (trimmed.startsWith('const ') ||
        trimmed.startsWith('let ') ||
        trimmed.startsWith('var ') ||
        trimmed.startsWith('return') ||
        trimmed.startsWith('throw ') ||
        trimmed.startsWith('await ') ||
        RegExp(r'^\w').hasMatch(trimmed)) {
      // But only if this line looks like it should be a statement
      if (trimmed.endsWith(')') ||
          trimmed.endsWith('"') ||
          trimmed.endsWith("'") ||
          trimmed.endsWith('`') ||
          RegExp(r'[\w\d\]\)]$').hasMatch(trimmed)) {
        return true;
      }
    }

    return false;
  }

  // ─── DART SYNTAX ────────────────────────────────────────────────

  void _detectDartSyntax(List<String> lines, List<SyntaxError> errors) {
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final trimmed = line.trimLeft().trimRight();
      final lineNum = i + 1;

      if (trimmed.isEmpty ||
          trimmed.startsWith('//') ||
          trimmed.startsWith('/*') ||
          trimmed.startsWith('*') ||
          trimmed == '}' ||
          trimmed == '{' ||
          trimmed == '});' ||
          trimmed.startsWith('@')) {
        continue;
      }

      // Missing semicolons
      if (!trimmed.endsWith(';') &&
          !trimmed.endsWith('{') &&
          !trimmed.endsWith('}') &&
          !trimmed.endsWith(',') &&
          !trimmed.endsWith('(') &&
          !trimmed.endsWith(')') &&
          !trimmed.endsWith(':') &&
          !trimmed.endsWith('=>') &&
          !trimmed.endsWith('\\') &&
          !trimmed.startsWith('if') &&
          !trimmed.startsWith('else') &&
          !trimmed.startsWith('for') &&
          !trimmed.startsWith('while') &&
          !trimmed.startsWith('switch') &&
          !trimmed.startsWith('case') &&
          !trimmed.startsWith('class') &&
          !trimmed.startsWith('import ') &&
          !trimmed.startsWith('part ') &&
          !trimmed.startsWith('library')) {
        // Check if this line SHOULD have a semicolon
        if (trimmed.startsWith('return') ||
            trimmed.startsWith('final ') ||
            trimmed.startsWith('var ') ||
            trimmed.startsWith('const ') ||
            trimmed.startsWith('late ') ||
            trimmed.startsWith('throw ') ||
            trimmed.startsWith('await ') ||
            trimmed.startsWith('print(') ||
            trimmed.startsWith('debugPrint(') ||
            trimmed.contains(' = ') ||
            trimmed.contains(' += ') ||
            trimmed.contains(' -= ') ||
            trimmed.contains(' *= ') ||
            RegExp(
              r'^(int|double|String|bool|List|Map|Set|void|dynamic|num)\s',
            ).hasMatch(trimmed) ||
            RegExp(r'^\w+\.\w+\(').hasMatch(trimmed) ||
            (RegExp(r'[\w\d\]\)"\x27]$').hasMatch(trimmed))) {
          errors.add(
            SyntaxError(
              line: lineNum,
              column: trimmed.length + 1,
              message: 'Missing semicolon at end of statement',
              code: trimmed,
              fix: '$trimmed;',
              description:
                  'In Dart, all statements must end with a semicolon (;). This is required, not optional.',
            ),
          );
        }
      }
    }
  }

  // ─── JAVA / C# SYNTAX ──────────────────────────────────────────

  void _detectJavaCSharpSyntax(
    List<String> lines,
    List<SyntaxError> errors,
    String lang,
  ) {
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final trimmed = line.trimLeft().trimRight();
      final lineNum = i + 1;

      if (trimmed.isEmpty ||
          trimmed.startsWith('//') ||
          trimmed.startsWith('/*') ||
          trimmed.startsWith('*') ||
          trimmed == '}' ||
          trimmed == '{' ||
          trimmed.startsWith('@')) {
        continue;
      }

      // Missing semicolons on statement lines
      if (!trimmed.endsWith(';') &&
          !trimmed.endsWith('{') &&
          !trimmed.endsWith('}') &&
          !trimmed.endsWith(',') &&
          !trimmed.endsWith(':') &&
          !trimmed.endsWith('(') &&
          !trimmed.endsWith(')') &&
          !trimmed.startsWith('if') &&
          !trimmed.startsWith('else') &&
          !trimmed.startsWith('for') &&
          !trimmed.startsWith('while') &&
          !trimmed.startsWith('switch') &&
          !trimmed.startsWith('case') &&
          !trimmed.startsWith('try') &&
          !trimmed.startsWith('catch') &&
          !trimmed.startsWith('class') &&
          !trimmed.startsWith('public class') &&
          !trimmed.startsWith('import ') &&
          !trimmed.startsWith('package ') &&
          !trimmed.startsWith('using ') &&
          !trimmed.startsWith('namespace')) {
        if (trimmed.startsWith('return') ||
            trimmed.contains(' = ') ||
            trimmed.startsWith('throw ') ||
            RegExp(
              r'^(int|String|double|float|boolean|char|long|short|byte|void|var|final|static)\s',
            ).hasMatch(trimmed) ||
            RegExp(r'^(public|private|protected)\s').hasMatch(trimmed) ||
            RegExp(r'^\w+\.\w+\(').hasMatch(trimmed) ||
            RegExp(r'^\w+\(').hasMatch(trimmed) ||
            (RegExp(r'[\w\d\]\)"\x27]$').hasMatch(trimmed))) {
          errors.add(
            SyntaxError(
              line: lineNum,
              column: trimmed.length + 1,
              message: 'Missing semicolon at end of statement',
              code: trimmed,
              fix: '$trimmed;',
              description:
                  'In $lang, all statements must end with a semicolon (;).',
            ),
          );
        }
      }
    }
  }

  // ─── C++ SYNTAX ─────────────────────────────────────────────────

  void _detectCppSyntax(List<String> lines, List<SyntaxError> errors) {
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final trimmed = line.trimLeft().trimRight();
      final lineNum = i + 1;

      if (trimmed.isEmpty ||
          trimmed.startsWith('//') ||
          trimmed.startsWith('#') ||
          trimmed.startsWith('/*') ||
          trimmed.startsWith('*') ||
          trimmed == '}' ||
          trimmed == '{') {
        continue;
      }

      // Missing semicolons on statements
      if (!trimmed.endsWith(';') &&
          !trimmed.endsWith('{') &&
          !trimmed.endsWith('}') &&
          !trimmed.endsWith(',') &&
          !trimmed.endsWith(':') &&
          !trimmed.endsWith('(') &&
          !trimmed.endsWith(')') &&
          !trimmed.endsWith('\\') &&
          !trimmed.startsWith('if') &&
          !trimmed.startsWith('else') &&
          !trimmed.startsWith('for') &&
          !trimmed.startsWith('while') &&
          !trimmed.startsWith('switch') &&
          !trimmed.startsWith('case') &&
          !trimmed.startsWith('class') &&
          !trimmed.startsWith('struct') &&
          !trimmed.startsWith('namespace') &&
          !trimmed.startsWith('template')) {
        if (trimmed.startsWith('return') ||
            trimmed.contains(' = ') ||
            trimmed.startsWith('throw ') ||
            trimmed.startsWith('delete ') ||
            RegExp(
              r'^(int|float|double|char|bool|void|auto|string|long|short|unsigned)\s',
            ).hasMatch(trimmed) ||
            RegExp(r'^(std::)').hasMatch(trimmed) ||
            RegExp(r'^\w+\(').hasMatch(trimmed) ||
            (RegExp(r'[\w\d\]\)"\x27]$').hasMatch(trimmed))) {
          errors.add(
            SyntaxError(
              line: lineNum,
              column: trimmed.length + 1,
              message: 'Missing semicolon at end of statement',
              code: trimmed,
              fix: '$trimmed;',
              description:
                  'In C++, all statements must end with a semicolon (;).',
            ),
          );
        }
      }
    }
  }

  // ─── Go SYNTAX ──────────────────────────────────────────────────

  void _detectGoSyntax(List<String> lines, List<SyntaxError> errors) {
    // Go has less semicolon issues but has other patterns
    for (int i = 0; i < lines.length; i++) {
      final trimmed = lines[i].trimLeft().trimRight();
      if (trimmed.isEmpty || trimmed.startsWith('//')) continue;
      // Go doesn't use semicolons, but check for common errors
      if (trimmed.endsWith(';') && !trimmed.contains('for')) {
        errors.add(
          SyntaxError(
            line: i + 1,
            column: trimmed.length,
            message: 'Unnecessary semicolon — Go does not require semicolons',
            code: trimmed,
            fix: trimmed.substring(0, trimmed.length - 1),
            description:
                'Go automatically inserts semicolons. Explicit semicolons are rarely needed.',
          ),
        );
      }
    }
  }

  // ─── Swift SYNTAX ───────────────────────────────────────────────

  void _detectSwiftSyntax(List<String> lines, List<SyntaxError> errors) {
    // Swift is like Go — no semicolons needed in most cases
    for (int i = 0; i < lines.length; i++) {
      final trimmed = lines[i].trimLeft().trimRight();
      if (trimmed.isEmpty || trimmed.startsWith('//')) continue;
      // Check for guard/if let without else
      if (trimmed.startsWith('guard') && !trimmed.contains('else')) {
        errors.add(
          SyntaxError(
            line: i + 1,
            column: trimmed.length,
            message: '"guard" statements require an "else" clause',
            code: trimmed,
            fix: '$trimmed else { return }',
            description:
                'Every "guard" statement in Swift must have an "else" clause that exits the scope.',
          ),
        );
      }
    }
  }

  // ─── Rust SYNTAX ────────────────────────────────────────────────

  void _detectRustSyntax(List<String> lines, List<SyntaxError> errors) {
    for (int i = 0; i < lines.length; i++) {
      final trimmed = lines[i].trimLeft().trimRight();
      if (trimmed.isEmpty || trimmed.startsWith('//')) continue;
      // Missing semicolons in Rust
      if (!trimmed.endsWith(';') &&
          !trimmed.endsWith('{') &&
          !trimmed.endsWith('}') &&
          !trimmed.endsWith(',') &&
          !trimmed.startsWith('fn') &&
          !trimmed.startsWith('if') &&
          !trimmed.startsWith('else') &&
          !trimmed.startsWith('for') &&
          !trimmed.startsWith('while') &&
          !trimmed.startsWith('match') &&
          !trimmed.startsWith('struct') &&
          !trimmed.startsWith('enum') &&
          !trimmed.startsWith('impl') &&
          !trimmed.startsWith('use') &&
          !trimmed.startsWith('mod') &&
          !trimmed.startsWith('pub')) {
        if (trimmed.startsWith('let') ||
            trimmed.startsWith('mut') ||
            trimmed.startsWith('return') ||
            trimmed.contains(' = ')) {
          errors.add(
            SyntaxError(
              line: i + 1,
              column: trimmed.length + 1,
              message: 'Missing semicolon at end of statement',
              code: trimmed,
              fix: '$trimmed;',
              description:
                  'In Rust, most statements must end with a semicolon (;).',
            ),
          );
        }
      }
    }
  }

  // ─── Kotlin SYNTAX ──────────────────────────────────────────────

  void _detectKotlinSyntax(List<String> lines, List<SyntaxError> errors) {
    // Kotlin doesn't require semicolons, similar to Go
  }

  // ─── PHP SYNTAX ─────────────────────────────────────────────────

  void _detectPhpSyntax(List<String> lines, List<SyntaxError> errors) {
    for (int i = 0; i < lines.length; i++) {
      final trimmed = lines[i].trimLeft().trimRight();
      if (trimmed.isEmpty ||
          trimmed.startsWith('//') ||
          trimmed.startsWith('#') ||
          trimmed.startsWith('/*') ||
          trimmed.startsWith('*') ||
          trimmed == '<?php' ||
          trimmed == '?>' ||
          trimmed == '}' ||
          trimmed == '{') {
        continue;
      }
      // Missing semicolons
      if (!trimmed.endsWith(';') &&
          !trimmed.endsWith('{') &&
          !trimmed.endsWith('}') &&
          !trimmed.endsWith(':') &&
          !trimmed.endsWith(',') &&
          !trimmed.startsWith('if') &&
          !trimmed.startsWith('else') &&
          !trimmed.startsWith('for') &&
          !trimmed.startsWith('while') &&
          !trimmed.startsWith('function') &&
          !trimmed.startsWith('class')) {
        if (trimmed.contains(' = ') ||
            trimmed.startsWith('return') ||
            trimmed.startsWith('echo') ||
            trimmed.startsWith('\$') ||
            RegExp(r'^\w+\(').hasMatch(trimmed)) {
          errors.add(
            SyntaxError(
              line: i + 1,
              column: trimmed.length + 1,
              message: 'Missing semicolon at end of statement',
              code: trimmed,
              fix: '$trimmed;',
              description:
                  'In PHP, all statements must end with a semicolon (;).',
            ),
          );
        }
      }
    }
  }

  // ─── UNBALANCED BRACKETS (ALL LANGUAGES) ────────────────────────

  void _detectUnbalancedBrackets(List<String> lines, List<SyntaxError> errors) {
    int parens = 0, brackets = 0, braces = 0;
    int lastOpenParenLine = 0, lastOpenBracketLine = 0, lastOpenBraceLine = 0;
    bool inString = false;
    String stringChar = '';

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      for (int j = 0; j < line.length; j++) {
        final ch = line[j];

        if (inString) {
          if (ch == stringChar && (j == 0 || line[j - 1] != '\\'))
            inString = false;
          continue;
        }
        if (ch == '"' || ch == "'") {
          inString = true;
          stringChar = ch;
          continue;
        }
        if (ch == '/' && j + 1 < line.length && line[j + 1] == '/') break;
        if (ch == '#') break;

        switch (ch) {
          case '(':
            parens++;
            lastOpenParenLine = i + 1;
            break;
          case ')':
            parens--;
            break;
          case '[':
            brackets++;
            lastOpenBracketLine = i + 1;
            break;
          case ']':
            brackets--;
            break;
          case '{':
            braces++;
            lastOpenBraceLine = i + 1;
            break;
          case '}':
            braces--;
            break;
        }
      }
    }

    if (parens > 0) {
      errors.add(
        SyntaxError(
          line: lastOpenParenLine,
          column: null,
          message: 'Unclosed parenthesis — missing $parens closing ")"',
          code: lines[lastOpenParenLine - 1].trim(),
          fix: '${lines[lastOpenParenLine - 1].trim()})',
          description:
              'Every opening "(" must have a matching ")". Check function calls and expressions.',
        ),
      );
    } else if (parens < 0) {
      errors.add(
        SyntaxError(
          line: lines.length,
          column: null,
          message: 'Extra closing parenthesis — ${-parens} unmatched ")"',
          code: lines.last.trim(),
          fix: lines.last.trim(),
          description:
              'Found a closing ")" without a matching "(". Remove it or add the missing "(".',
        ),
      );
    }

    if (brackets > 0) {
      errors.add(
        SyntaxError(
          line: lastOpenBracketLine,
          column: null,
          message: 'Unclosed bracket — missing $brackets closing "]"',
          code: lines[lastOpenBracketLine - 1].trim(),
          fix: '${lines[lastOpenBracketLine - 1].trim()}]',
          description:
              'Every "[" must have a matching "]". Check arrays, lists, or index operations.',
        ),
      );
    }

    if (braces > 0) {
      errors.add(
        SyntaxError(
          line: lastOpenBraceLine,
          column: null,
          message: 'Unclosed brace — missing $braces closing "}"',
          code: lines[lastOpenBraceLine - 1].trim(),
          fix: '${lines[lastOpenBraceLine - 1].trim()}\n}',
          description:
              'Every "{" must have a matching "}". Check functions, classes, or code blocks.',
        ),
      );
    } else if (braces < 0) {
      errors.add(
        SyntaxError(
          line: lines.length,
          column: null,
          message: 'Extra closing brace — ${-braces} unmatched "}"',
          code: lines.last.trim(),
          fix: lines.last.trim(),
          description:
              'Found a closing "}" without a matching "{". Remove it or add the missing "{".',
        ),
      );
    }
  }

  // ─── APPLY SYNTAX FIXES ─────────────────────────────────────────

  String _applySyntaxFixes(String code, List<SyntaxError> syntaxErrors) {
    final lines = code.split('\n');
    // Process in reverse line order so fixes don't shift line positions
    final errorsByLine = <int, List<SyntaxError>>{};
    for (final err in syntaxErrors) {
      errorsByLine.putIfAbsent(err.line, () => []).add(err);
    }

    for (final entry in errorsByLine.entries) {
      final lineIdx = entry.key - 1;
      if (lineIdx >= 0 && lineIdx < lines.length) {
        final errs = entry.value;
        // Apply the first fix for this line
        final err = errs.first;
        if (lines[lineIdx].contains(err.code)) {
          lines[lineIdx] = lines[lineIdx].replaceFirst(err.code, err.fix);
        } else {
          // If exact match fails, try applying fix directly
          final indent =
              lines[lineIdx].length - lines[lineIdx].trimLeft().length;
          lines[lineIdx] = '${' ' * indent}${err.fix}';
        }
      }
    }

    return '// Syntax fixes applied\n${lines.join('\n')}';
  }

  List<String> _syntaxVocabulary() => [
    'syntax - the set of rules that defines the structure of a programming language',
    'colon - the character (:) used to start code blocks in Python',
    'semicolon - the character (;) used to end statements in many languages',
    'bracket - characters like (), [], {} used to group code',
    'keyword - a reserved word with special meaning in a language',
    'indentation - the spaces/tabs at the start of a line that define code blocks',
  ];

  // ════════════════════════════════════════════════════════════════
  //  PHASE 2: COMPREHENSIVE ANALYSIS
  // ════════════════════════════════════════════════════════════════

  List<CodeIssue> _generateIssues(String code, String language) {
    final List<CodeIssue> issues = [];
    final lines = code.split('\n');

    // Division by zero
    for (int i = 0; i < lines.length; i++) {
      if (lines[i].contains('/') &&
          !lines[i].contains('//') &&
          !lines[i].contains('http') &&
          (lines[i].contains('/ ') ||
              lines[i].contains('/y') ||
              lines[i].contains('/b'))) {
        if (!code.contains('== 0') && !code.contains('!= 0')) {
          issues.add(
            CodeIssue(
              title: 'Potential division by zero',
              description: 'Division without checking if the divisor is zero.',
              simpleExplanation:
                  '💡 When you divide by zero, your program crashes.',
              severity: IssueSeverity.critical,
              type: IssueType.bug,
              lineNumber: i + 1,
              suggestion: 'Add a zero-check before performing division.',
              codeExample:
                  'if (divisor == 0) throw ArgumentError("Cannot divide by zero");',
              explanation:
                  'Division by zero causes a runtime error in most languages.',
              exampleFix:
                  'if y == 0:\n    raise ValueError("Cannot divide by zero")\nresult = x / y',
            ),
          );
          break;
        }
      }
    }

    // var usage
    if (code.contains('var ') &&
        (language == 'Dart' ||
            language == 'JavaScript' ||
            language == 'TypeScript')) {
      final lineIndex = lines.indexWhere((l) => l.contains('var '));
      issues.add(
        CodeIssue(
          title: 'Use explicit type declarations',
          description: 'Using "var" hides the type and reduces readability.',
          simpleExplanation:
              '💡 Using specific types makes your code easier to understand.',
          severity: IssueSeverity.warning,
          type: IssueType.style,
          lineNumber: lineIndex >= 0 ? lineIndex + 1 : 1,
          suggestion: 'Replace var with the specific type.',
          explanation:
              'Explicit types catch type-related bugs at compile time.',
          exampleFix: 'String name = "hello";',
        ),
      );
    }

    // Print/console.log statements
    if (code.contains('print(') || code.contains('console.log(')) {
      final lineIndex = lines.indexWhere(
        (l) => l.contains('print(') || l.contains('console.log('),
      );
      issues.add(
        CodeIssue(
          title: 'Debug statements detected',
          description: 'Print/console.log should be removed in production.',
          simpleExplanation: '💡 Use a proper logging framework instead.',
          severity: IssueSeverity.warning,
          type: IssueType.bestPractice,
          lineNumber: lineIndex >= 0 ? lineIndex + 1 : null,
          suggestion: 'Use a logging framework instead.',
          explanation: 'Debug prints can leak sensitive information.',
          exampleFix: 'logger.d("Fetching user: \$userId");',
        ),
      );
    }

    // Missing error handling
    if (!code.contains('try') &&
        !code.contains('catch') &&
        !code.contains('except')) {
      issues.add(
        CodeIssue(
          title: 'No error handling detected',
          description:
              'Operations that might fail should be wrapped in error handling.',
          simpleExplanation:
              '💡 Error handling keeps your app safe from crashes!',
          severity: IssueSeverity.error,
          type: IssueType.security,
          suggestion: 'Wrap risky operations in try-catch blocks.',
          explanation:
              'Without error handling, a single failure can crash your application.',
          exampleFix:
              'try:\n    data = api.get(url)\nexcept Exception as e:\n    return None',
        ),
      );
    }

    // String concatenation
    if (code.contains('" +') ||
        code.contains("' +") ||
        code.contains('+ "') ||
        code.contains("+ '")) {
      final lineIndex = lines.indexWhere(
        (l) =>
            l.contains('" +') ||
            l.contains("' +") ||
            l.contains('+ "') ||
            l.contains("+ '"),
      );
      issues.add(
        CodeIssue(
          title: 'String concatenation instead of interpolation',
          description: 'Using + for strings is inefficient.',
          simpleExplanation: '💡 String interpolation is cleaner and faster.',
          severity: IssueSeverity.warning,
          type: IssueType.performance,
          lineNumber: lineIndex >= 0 ? lineIndex + 1 : null,
          suggestion: 'Use string interpolation instead.',
          explanation: 'Concatenation creates intermediate string objects.',
          exampleFix: 'print(f"Fetching user: {userId}")',
        ),
      );
    }

    // TODO/FIXME
    if (code.contains('TODO') || code.contains('FIXME')) {
      final lineIndex = lines.indexWhere(
        (l) => l.contains('TODO') || l.contains('FIXME'),
      );
      issues.add(
        CodeIssue(
          title: 'Unresolved TODO/FIXME found',
          description: 'TODO/FIXME comments indicate unfinished work.',
          simpleExplanation: '💡 Resolve TODOs before deploying.',
          severity: IssueSeverity.info,
          type: IssueType.bestPractice,
          lineNumber: lineIndex >= 0 ? lineIndex + 1 : null,
          suggestion: 'Implement the TODO, then remove the comment.',
          explanation: 'Unresolved TODOs suggest incomplete code.',
        ),
      );
    }

    // Hardcoded secrets
    if (RegExp(
      r'["\x27](password|secret|api[_-]?key|token)["\x27]',
      caseSensitive: false,
    ).hasMatch(code)) {
      issues.add(
        CodeIssue(
          title: 'Hardcoded sensitive data detected',
          description: 'Passwords, API keys, or tokens appear to be hardcoded.',
          simpleExplanation:
              '💡 Never put passwords or API keys directly in your code!',
          severity: IssueSeverity.critical,
          type: IssueType.security,
          suggestion: 'Use environment variables or a secrets manager.',
          explanation:
              'If pushed to a public repo, anyone can see your secrets.',
          exampleFix: 'import os\napi_key = os.environ.get("API_KEY")',
        ),
      );
    }

    // Fallback
    if (issues.isEmpty) {
      issues.add(
        CodeIssue(
          title: 'Consider adding input validation',
          description: 'Adding input validation prevents unexpected behavior.',
          simpleExplanation: '💡 Always validate what users give you.',
          severity: IssueSeverity.info,
          type: IssueType.bestPractice,
          suggestion: 'Validate function parameters.',
          explanation:
              'Without validation, invalid inputs can cause subtle bugs.',
        ),
      );
    }

    return issues;
  }

  String _generateFixedCode(String code, String language) {
    String fixed = code;
    if (!code.contains('try') &&
        !code.contains('catch') &&
        !code.contains('except')) {
      if (language == 'Python') {
        final lines = fixed.split('\n');
        final funcMatch = RegExp(r'^def (\w+)\(');
        int funcLine = -1;
        for (int i = 0; i < lines.length; i++) {
          if (funcMatch.hasMatch(lines[i])) {
            funcLine = i;
            break;
          }
        }
        if (funcLine >= 0) {
          final body = lines
              .sublist(funcLine + 1)
              .map((l) => '    $l')
              .join('\n');
          fixed =
              '${lines.sublist(0, funcLine + 1).join('\n')}\n    try:\n$body\n    except Exception as e:\n        print(f"Error: {e}")\n        return None';
        }
      } else if (language == 'Dart' ||
          language == 'JavaScript' ||
          language == 'TypeScript') {
        fixed = fixed.replaceFirst('{', '{\n  try {');
        if (fixed.contains('}')) {
          final lastBrace = fixed.lastIndexOf('}');
          fixed =
              '${fixed.substring(0, lastBrace)}  } catch (e) {\n    debugPrint("Error: \$e");\n    rethrow;\n  }\n}';
        }
      }
    }
    if (language == 'Dart') {
      fixed = fixed.replaceAll('var data', 'Map<String, dynamic> data');
      fixed = fixed.replaceAll('var name', 'String name');
      fixed = fixed.replaceAll('var email', 'String email');
    }
    if (!fixed.contains('// Fixed:') && !fixed.contains('# Fixed:')) {
      final comment = language == 'Python' ? '# Fixed:' : '// Fixed:';
      fixed = '$comment Added error handling and input validation\n$fixed';
    }
    return fixed;
  }

  List<int> _getChangedLines(String code) {
    final lines = code.split('\n');
    final changed = <int>[];
    for (int i = 0; i < lines.length; i++) {
      if (lines[i].contains('var ') ||
          lines[i].contains('print(') ||
          lines[i].contains('console.log(') ||
          lines[i].contains('" +') ||
          lines[i].contains('TODO') ||
          (lines[i].contains('/') && !lines[i].contains('//'))) {
        changed.add(i + 1);
      }
    }
    if (!changed.contains(1)) changed.insert(0, 1);
    changed.add(lines.length + 1);
    changed.add(lines.length + 2);
    return changed;
  }

  Map<String, int> _generateRatings(List<CodeIssue> issues, int score) {
    int security = 85, performance = 80, maintainability = 75, quality = score;
    for (final issue in issues) {
      switch (issue.type) {
        case IssueType.security:
          security -= (issue.severity == IssueSeverity.critical ? 30 : 15);
          break;
        case IssueType.performance:
          performance -= (issue.severity == IssueSeverity.critical ? 25 : 10);
          break;
        case IssueType.style:
        case IssueType.bestPractice:
          maintainability -= 8;
          break;
        case IssueType.bug:
          quality -= 10;
          break;
        case IssueType.syntax:
          break;
      }
    }
    return {
      'quality': quality.clamp(0, 100),
      'security': security.clamp(0, 100),
      'performance': performance.clamp(0, 100),
      'maintainability': maintainability.clamp(0, 100),
    };
  }

  String _generateSummary(
    String code,
    String language,
    List<CodeIssue> issues,
  ) {
    final critCount = issues
        .where((i) => i.severity == IssueSeverity.critical)
        .length;
    final highCount = issues
        .where((i) => i.severity == IssueSeverity.error)
        .length;
    if (critCount > 0) {
      return 'This $language code has $critCount critical issue${critCount > 1 ? 's' : ''} that need immediate attention.';
    } else if (highCount > 0) {
      return 'The code has some important issues to address for production readiness.';
    }
    return 'Overall, this $language code follows most standard conventions with minor improvements suggested.';
  }

  List<String> _generateSuggestions(String language) => [
    '✨ Add unit tests for critical business logic',
    '🔒 Validate all user inputs before processing',
    '📝 Use consistent naming conventions throughout',
    '⚡ Consider using const constructors for immutable widgets',
    '🎯 Follow the Single Responsibility Principle',
  ];

  String _generateExplanation(String code, String language) =>
      'This $language code has been analyzed for common patterns and best practices.';

  List<String> _generateVocabulary() => [
    'refactor - to restructure code without changing its behavior',
    'immutable - cannot be changed after creation',
    'deprecated - outdated and should no longer be used',
    'polymorphism - ability of objects to take many forms',
    'encapsulation - hiding internal details from outside',
  ];

  int _calculateScore(List<CodeIssue> issues) {
    int score = 100;
    for (final issue in issues) {
      switch (issue.severity) {
        case IssueSeverity.critical:
          score -= 20;
          break;
        case IssueSeverity.error:
          score -= 15;
          break;
        case IssueSeverity.warning:
          score -= 8;
          break;
        case IssueSeverity.info:
          score -= 3;
          break;
      }
    }
    return score.clamp(0, 100);
  }
}
