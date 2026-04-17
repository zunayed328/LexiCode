/**
 * Language-specific syntax checking using regex patterns.
 * Mirrors the logic in the Flutter client's ai_service.dart.
 */

export interface SyntaxErrorResult {
  line: number;
  column: number | null;
  message: string;
  code: string;
  fix: string;
  description: string;
}

/**
 * Run syntax checks on the given code for the specified language.
 */
export function checkSyntax(code: string, language: string): SyntaxErrorResult[] {
  const errors: SyntaxErrorResult[] = [];
  const lines = code.split('\n');
  const lang = language.toLowerCase();

  // 1. Keyword typo detection (all languages)
  detectKeywordTypos(lines, errors);

  // 2. Language-specific checks
  switch (lang) {
    case 'python':
      detectPythonSyntax(lines, errors);
      break;
    case 'javascript':
    case 'typescript':
      detectJSSyntax(lines, errors, language);
      break;
    case 'dart':
      detectDartSyntax(lines, errors);
      break;
    case 'java':
    case 'c#':
      detectJavaCSharpSyntax(lines, errors, language);
      break;
    case 'c++':
    case 'c':
      detectCppSyntax(lines, errors);
      break;
    case 'go':
      detectGoSyntax(lines, errors);
      break;
    case 'swift':
      detectSwiftSyntax(lines, errors);
      break;
    case 'rust':
      detectRustSyntax(lines, errors);
      break;
    case 'php':
      detectPhpSyntax(lines, errors);
      break;
  }

  // 3. Unbalanced brackets (all languages)
  detectUnbalancedBrackets(lines, errors);

  // De-duplicate errors on same line with same message
  const seen = new Set<string>();
  const unique = errors.filter((e) => {
    const key = `${e.line}:${e.message}`;
    if (seen.has(key)) return false;
    seen.add(key);
    return true;
  });

  // Sort by line number
  unique.sort((a, b) => a.line - b.line);

  return unique;
}

// ─── KEYWORD TYPO DETECTION ────────────────────────────────────────

const TYPOS: Record<string, string> = {
  // Python
  deff: 'def', dfe: 'def', defn: 'def',
  iff: 'if', fi: 'if',
  retrun: 'return', reutrn: 'return', retrn: 'return', retunr: 'return', retur: 'return',
  improt: 'import', imoprt: 'import', ipmort: 'import', imort: 'import',
  pritn: 'print', pirnt: 'print', prnt: 'print', pint: 'print',
  esle: 'else', els: 'else', eles: 'else',
  ture: 'true', treu: 'true',
  flase: 'false', fasle: 'false', fales: 'false',
  whlie: 'while', whlile: 'while', whiel: 'while',
  contineu: 'continue', contniue: 'continue', contiue: 'continue',
  brek: 'break', braek: 'break', brak: 'break',
  calss: 'class', clss: 'class', clsas: 'class', classs: 'class',
  excpet: 'except', exept: 'except', execpt: 'except',
  finaly: 'finally', finlly: 'finally',
  lamda: 'lambda', labmda: 'lambda',
  yeild: 'yield', yiled: 'yield',
  asert: 'assert', assrt: 'assert',
  rais: 'raise', rasie: 'raise',
  // JavaScript / TypeScript
  fucntion: 'function', funciton: 'function', funtion: 'function',
  fuction: 'function', funtcion: 'function', functon: 'function',
  cnst: 'const', cosnt: 'const', conts: 'const', ocnst: 'const',
  lte: 'let', elt: 'let',
  varl: 'var', vra: 'var',
  consoel: 'console', conosle: 'console', consloe: 'console',
  docuemnt: 'document', documnet: 'document',
  widnow: 'window', windwo: 'window',
  undefind: 'undefined', undifined: 'undefined',
  typof: 'typeof', tyepof: 'typeof',
  instnaceof: 'instanceof', instancef: 'instanceof',
  swtich: 'switch', swich: 'switch', siwtch: 'switch',
  deafult: 'default', defualt: 'default',
  exprot: 'export', exoprt: 'export',
  reqiure: 'require', reuqire: 'require',
  asncy: 'async', asyc: 'async', asnyc: 'async',
  awiat: 'await', awit: 'await',
  // Java / C# / Dart
  pubic: 'public', pubilc: 'public', pulic: 'public',
  privat: 'private', prviate: 'private', priavte: 'private',
  proected: 'protected', protceted: 'protected',
  abstact: 'abstract', abstarct: 'abstract',
  interfce: 'interface', inteface: 'interface',
  pacakge: 'package', packge: 'package',
  throwr: 'throw', trhow: 'throw',
  catchh: 'catch', ctach: 'catch',
  voild: 'void', viod: 'void',
  statc: 'static', satic: 'static',
  finla: 'final', fianl: 'final',
  overrdie: 'override', overide: 'override',
  extens: 'extends', extneds: 'extends',
  implemnts: 'implements', implments: 'implements',
  enumm: 'enum', enmu: 'enum',
  // C++
  namesapce: 'namespace', namepsace: 'namespace',
  incldue: 'include', inlcude: 'include',
  tempalte: 'template', templat: 'template',
  struuct: 'struct', strcut: 'struct',
  virtaul: 'virtual', virutal: 'virtual',
};

function detectKeywordTypos(lines: string[], errors: SyntaxErrorResult[]): void {
  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];
    const trimmed = line.trimStart();

    // Skip comments
    if (trimmed.startsWith('//') || trimmed.startsWith('#') ||
        trimmed.startsWith('/*') || trimmed.startsWith('*')) continue;

    const words = trimmed.split(/[\s\(\)\[\]{},;.:=+\-*/<>!&|~^%@#\\?]+/);
    for (const word of words) {
      if (!word) continue;
      if (TYPOS[word]) {
        errors.push({
          line: i + 1,
          column: line.indexOf(word) + 1,
          message: `Typo: "${word}" should be "${TYPOS[word]}"`,
          code: trimmed,
          fix: trimmed.replace(word, TYPOS[word]),
          description: `The keyword "${word}" is misspelled. The correct keyword is "${TYPOS[word]}".`,
        });
      }
    }
  }
}

// ─── PYTHON SYNTAX ─────────────────────────────────────────────────

function detectPythonSyntax(lines: string[], errors: SyntaxErrorResult[]): void {
  for (let i = 0; i < lines.length; i++) {
    const trimmed = lines[i].trim();
    if (!trimmed || trimmed.startsWith('#')) continue;

    // Missing colon after block keywords
    const colonPat = /^(if|elif|else|for|while|def|deff|dfe|class|calss|clss|try|except|excpet|exept|finally|finaly|with|lambda|lamda)\b/;
    const match = trimmed.match(colonPat);
    if (match) {
      const stripped = trimmed.replace(/#.*$/, '').trimEnd();
      if (!stripped.endsWith(':') && stripped.length > 0) {
        errors.push({
          line: i + 1,
          column: stripped.length + 1,
          message: `Missing colon (:) after "${match[1]}" statement`,
          code: trimmed,
          fix: `${stripped}:`,
          description: `In Python, all "${match[1]}" statements must end with a colon (:).`,
        });
      }
    }

    // Python 2 print syntax
    if (/^print\s+["']/.test(trimmed)) {
      const arg = trimmed.substring(5).trimStart();
      errors.push({
        line: i + 1,
        column: 1,
        message: 'Python 2 print syntax — use print() function',
        code: trimmed,
        fix: `print(${arg})`,
        description: 'In Python 3, "print" is a function and requires parentheses.',
      });
    }

    // Assignment with == instead of =
    if (/^[a-zA-Z_]\w*\s*==\s*.+/.test(trimmed) &&
        !trimmed.startsWith('if') && !trimmed.startsWith('elif') &&
        !trimmed.startsWith('while') && !trimmed.startsWith('return') &&
        !trimmed.startsWith('assert') && !trimmed.includes('(')) {
      errors.push({
        line: i + 1,
        column: trimmed.indexOf('==') + 1,
        message: 'Possible incorrect use of == (comparison) instead of = (assignment)',
        code: trimmed,
        fix: trimmed.replace('==', '='),
        description: '"==" is comparison, "=" is assignment.',
      });
    }
  }
}

// ─── JAVASCRIPT / TYPESCRIPT SYNTAX ────────────────────────────────

function detectJSSyntax(lines: string[], errors: SyntaxErrorResult[], lang: string): void {
  for (let i = 0; i < lines.length; i++) {
    const trimmed = lines[i].trim();
    if (!trimmed || trimmed.startsWith('//') || trimmed.startsWith('/*') ||
        trimmed.startsWith('*') || trimmed === '}' || trimmed === '{' ||
        trimmed === '});' || trimmed === ']);') continue;

    // Missing semicolons
    if (jsNeedsSemicolon(trimmed)) {
      errors.push({
        line: i + 1,
        column: trimmed.length + 1,
        message: 'Missing semicolon at end of statement',
        code: trimmed,
        fix: `${trimmed};`,
        description: `In ${lang}, statements should end with a semicolon (;).`,
      });
    }

    // === in assignment context
    if (/^(let|const|var)\s+\w+\s*===/.test(trimmed)) {
      errors.push({
        line: i + 1,
        column: trimmed.indexOf('===') + 1,
        message: 'Using === (comparison) in assignment — should use =',
        code: trimmed,
        fix: trimmed.replace('===', '='),
        description: '"===" is strict comparison, "=" is assignment.',
      });
    }
  }
}

function jsNeedsSemicolon(trimmed: string): boolean {
  if (/[;{},(:*/\\]$/.test(trimmed) || trimmed.endsWith('=>')) return false;
  if (/^(if|else|for|while|switch|case|try|catch|finally|class|import |export |\/\/|\/\*|\*)/.test(trimmed)) return false;
  if (/^(function|async function)/.test(trimmed)) return false;
  if (/^(const|let|var)\s+\w+\s*=\s*(async\s+)?\(/.test(trimmed) && trimmed.endsWith('{')) return false;

  if (/^(const |let |var |return|throw |await )/.test(trimmed) || /^\w/.test(trimmed)) {
    if (/[\w\d\]\)"'`]$/.test(trimmed)) return true;
  }
  return false;
}

// ─── DART SYNTAX ───────────────────────────────────────────────────

function detectDartSyntax(lines: string[], errors: SyntaxErrorResult[]): void {
  for (let i = 0; i < lines.length; i++) {
    const trimmed = lines[i].trim();
    if (!trimmed || trimmed.startsWith('//') || trimmed.startsWith('/*') ||
        trimmed.startsWith('*') || trimmed === '}' || trimmed === '{' ||
        trimmed === '});' || trimmed.startsWith('@')) continue;

    if (!trimmed.endsWith(';') && !trimmed.endsWith('{') && !trimmed.endsWith('}') &&
        !trimmed.endsWith(',') && !trimmed.endsWith('(') && !trimmed.endsWith(')') &&
        !trimmed.endsWith(':') && !trimmed.endsWith('=>') && !trimmed.endsWith('\\') &&
        !/^(if|else|for|while|switch|case|class|import |part |library)/.test(trimmed)) {
      if (/^(return|final |var |const |late |throw |await |print\(|debugPrint\()/.test(trimmed) ||
          trimmed.includes(' = ') || /^(int|double|String|bool|List|Map|Set|void|dynamic|num)\s/.test(trimmed) ||
          /^\w+\.\w+\(/.test(trimmed) || /[\w\d\]\)"']$/.test(trimmed)) {
        errors.push({
          line: i + 1,
          column: trimmed.length + 1,
          message: 'Missing semicolon at end of statement',
          code: trimmed,
          fix: `${trimmed};`,
          description: 'In Dart, all statements must end with a semicolon (;).',
        });
      }
    }
  }
}

// ─── JAVA / C# SYNTAX ─────────────────────────────────────────────

function detectJavaCSharpSyntax(lines: string[], errors: SyntaxErrorResult[], lang: string): void {
  for (let i = 0; i < lines.length; i++) {
    const trimmed = lines[i].trim();
    if (!trimmed || trimmed.startsWith('//') || trimmed.startsWith('/*') ||
        trimmed.startsWith('*') || trimmed === '}' || trimmed === '{' ||
        trimmed.startsWith('@')) continue;

    if (!trimmed.endsWith(';') && !trimmed.endsWith('{') && !trimmed.endsWith('}') &&
        !trimmed.endsWith(',') && !trimmed.endsWith(':') && !trimmed.endsWith('(') &&
        !trimmed.endsWith(')') &&
        !/^(if|else|for|while|switch|case|try|catch|class|public class|import |package |using |namespace)/.test(trimmed)) {
      if (/^(return|throw )/.test(trimmed) || trimmed.includes(' = ') ||
          /^(int|String|double|float|boolean|char|long|short|byte|void|var|final|static)\s/.test(trimmed) ||
          /^(public|private|protected)\s/.test(trimmed) ||
          /^\w+\.\w+\(/.test(trimmed) || /^\w+\(/.test(trimmed) ||
          /[\w\d\]\)"']$/.test(trimmed)) {
        errors.push({
          line: i + 1,
          column: trimmed.length + 1,
          message: 'Missing semicolon at end of statement',
          code: trimmed,
          fix: `${trimmed};`,
          description: `In ${lang}, all statements must end with a semicolon (;).`,
        });
      }
    }
  }
}

// ─── C++ SYNTAX ────────────────────────────────────────────────────

function detectCppSyntax(lines: string[], errors: SyntaxErrorResult[]): void {
  for (let i = 0; i < lines.length; i++) {
    const trimmed = lines[i].trim();
    if (!trimmed || trimmed.startsWith('//') || trimmed.startsWith('#') ||
        trimmed.startsWith('/*') || trimmed.startsWith('*') ||
        trimmed === '}' || trimmed === '{') continue;

    if (!trimmed.endsWith(';') && !trimmed.endsWith('{') && !trimmed.endsWith('}') &&
        !trimmed.endsWith(',') && !trimmed.endsWith(':') && !trimmed.endsWith('(') &&
        !trimmed.endsWith(')') && !trimmed.endsWith('\\') &&
        !/^(if|else|for|while|switch|case|class|struct|namespace|template)/.test(trimmed)) {
      if (/^(return|throw |delete )/.test(trimmed) || trimmed.includes(' = ') ||
          /^(int|float|double|char|bool|void|auto|string|long|short|unsigned)\s/.test(trimmed) ||
          /^(std::)/.test(trimmed) || /^\w+\(/.test(trimmed) ||
          /[\w\d\]\)"']$/.test(trimmed)) {
        errors.push({
          line: i + 1,
          column: trimmed.length + 1,
          message: 'Missing semicolon at end of statement',
          code: trimmed,
          fix: `${trimmed};`,
          description: 'In C++, all statements must end with a semicolon (;).',
        });
      }
    }
  }
}

// ─── GO SYNTAX ─────────────────────────────────────────────────────

function detectGoSyntax(lines: string[], errors: SyntaxErrorResult[]): void {
  for (let i = 0; i < lines.length; i++) {
    const trimmed = lines[i].trim();
    if (!trimmed || trimmed.startsWith('//')) continue;
    if (trimmed.endsWith(';') && !trimmed.includes('for')) {
      errors.push({
        line: i + 1,
        column: trimmed.length,
        message: 'Unnecessary semicolon — Go does not require semicolons',
        code: trimmed,
        fix: trimmed.slice(0, -1),
        description: 'Go automatically inserts semicolons. Explicit semicolons are rarely needed.',
      });
    }
  }
}

// ─── SWIFT SYNTAX ──────────────────────────────────────────────────

function detectSwiftSyntax(lines: string[], errors: SyntaxErrorResult[]): void {
  for (let i = 0; i < lines.length; i++) {
    const trimmed = lines[i].trim();
    if (!trimmed || trimmed.startsWith('//')) continue;
    if (trimmed.startsWith('guard') && !trimmed.includes('else')) {
      errors.push({
        line: i + 1,
        column: trimmed.length,
        message: '"guard" statements require an "else" clause',
        code: trimmed,
        fix: `${trimmed} else { return }`,
        description: 'Every "guard" statement in Swift must have an "else" clause that exits the scope.',
      });
    }
  }
}

// ─── RUST SYNTAX ───────────────────────────────────────────────────

function detectRustSyntax(lines: string[], errors: SyntaxErrorResult[]): void {
  for (let i = 0; i < lines.length; i++) {
    const trimmed = lines[i].trim();
    if (!trimmed || trimmed.startsWith('//')) continue;

    if (!trimmed.endsWith(';') && !trimmed.endsWith('{') && !trimmed.endsWith('}') &&
        !trimmed.endsWith(',') &&
        !/^(fn|if|else|for|while|match|struct|enum|impl|use|mod|pub)/.test(trimmed)) {
      if (/^(let|mut|return)/.test(trimmed) || trimmed.includes(' = ')) {
        errors.push({
          line: i + 1,
          column: trimmed.length + 1,
          message: 'Missing semicolon at end of statement',
          code: trimmed,
          fix: `${trimmed};`,
          description: 'In Rust, most statements must end with a semicolon (;).',
        });
      }
    }
  }
}

// ─── PHP SYNTAX ────────────────────────────────────────────────────

function detectPhpSyntax(lines: string[], errors: SyntaxErrorResult[]): void {
  for (let i = 0; i < lines.length; i++) {
    const trimmed = lines[i].trim();
    if (!trimmed || trimmed.startsWith('//') || trimmed.startsWith('#') ||
        trimmed.startsWith('/*') || trimmed.startsWith('*') ||
        trimmed === '<?php' || trimmed === '?>' ||
        trimmed === '}' || trimmed === '{') continue;

    if (!trimmed.endsWith(';') && !trimmed.endsWith('{') && !trimmed.endsWith('}') &&
        !trimmed.endsWith(':') && !trimmed.endsWith(',') &&
        !/^(if|else|for|while|function|class)/.test(trimmed)) {
      if (trimmed.includes(' = ') || /^(return|echo)/.test(trimmed) ||
          trimmed.startsWith('$') || /^\w+\(/.test(trimmed)) {
        errors.push({
          line: i + 1,
          column: trimmed.length + 1,
          message: 'Missing semicolon at end of statement',
          code: trimmed,
          fix: `${trimmed};`,
          description: 'In PHP, all statements must end with a semicolon (;).',
        });
      }
    }
  }
}

// ─── UNBALANCED BRACKETS ───────────────────────────────────────────

function detectUnbalancedBrackets(lines: string[], errors: SyntaxErrorResult[]): void {
  let parens = 0, brackets = 0, braces = 0;
  let lastOpenParenLine = 0, lastOpenBracketLine = 0, lastOpenBraceLine = 0;
  let inString = false;
  let stringChar = '';

  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];
    for (let j = 0; j < line.length; j++) {
      const ch = line[j];

      if (inString) {
        if (ch === stringChar && (j === 0 || line[j - 1] !== '\\')) inString = false;
        continue;
      }
      if (ch === '"' || ch === "'") {
        inString = true;
        stringChar = ch;
        continue;
      }
      if (ch === '/' && j + 1 < line.length && line[j + 1] === '/') break;
      if (ch === '#') break;

      switch (ch) {
        case '(': parens++; lastOpenParenLine = i + 1; break;
        case ')': parens--; break;
        case '[': brackets++; lastOpenBracketLine = i + 1; break;
        case ']': brackets--; break;
        case '{': braces++; lastOpenBraceLine = i + 1; break;
        case '}': braces--; break;
      }
    }
  }

  if (parens > 0) {
    errors.push({
      line: lastOpenParenLine, column: null,
      message: `Unclosed parenthesis — missing ${parens} closing ")"`,
      code: lines[lastOpenParenLine - 1].trim(),
      fix: `${lines[lastOpenParenLine - 1].trim()})`,
      description: 'Every opening "(" must have a matching ")".',
    });
  } else if (parens < 0) {
    errors.push({
      line: lines.length, column: null,
      message: `Extra closing parenthesis — ${-parens} unmatched ")"`,
      code: lines[lines.length - 1].trim(), fix: lines[lines.length - 1].trim(),
      description: 'Found a closing ")" without a matching "(".',
    });
  }

  if (brackets > 0) {
    errors.push({
      line: lastOpenBracketLine, column: null,
      message: `Unclosed bracket — missing ${brackets} closing "]"`,
      code: lines[lastOpenBracketLine - 1].trim(),
      fix: `${lines[lastOpenBracketLine - 1].trim()}]`,
      description: 'Every "[" must have a matching "]".',
    });
  }

  if (braces > 0) {
    errors.push({
      line: lastOpenBraceLine, column: null,
      message: `Unclosed brace — missing ${braces} closing "}"`,
      code: lines[lastOpenBraceLine - 1].trim(),
      fix: `${lines[lastOpenBraceLine - 1].trim()}\n}`,
      description: 'Every "{" must have a matching "}".',
    });
  } else if (braces < 0) {
    errors.push({
      line: lines.length, column: null,
      message: `Extra closing brace — ${-braces} unmatched "}"`,
      code: lines[lines.length - 1].trim(), fix: lines[lines.length - 1].trim(),
      description: 'Found a closing "}" without a matching "{".',
    });
  }
}
