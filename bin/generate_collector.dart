/// CLI tool that fetches a Jira Issue Collector's form, discovers its
/// fields, and generates a type-safe Dart helper class.
///
/// Usage:
///   dart run flutter_jira_issue_collector:generate_collector \
///     --base-url https://jira.example.com \
///     --collector-id 3e3ffaf3 \
///     --output lib/generated/jira_collector_fields.dart
///
/// The generated file contains:
///   - A typed class with a constant for every field ID.
///   - A `build()` factory that accepts only the fields the collector
///     actually exposes (required fields are required parameters,
///     optional fields are optional).
///   - Inline documentation showing each field's type and label.
library;

import 'dart:io';

import 'package:flutter_jira_issue_collector/src/models/collector_config.dart';
import 'package:flutter_jira_issue_collector/src/models/collector_field.dart';
import 'package:flutter_jira_issue_collector/src/services/jira_collector_client.dart';

Future<void> main(List<String> args) async {
  final parsed = _parseArgs(args);

  if (parsed == null) {
    _printUsage();
    exit(1);
  }

  final baseUrl = parsed['base-url']!;
  final collectorId = parsed['collector-id']!;
  final output = parsed['output'] ?? 'lib/generated/jira_collector_fields.dart';
  final className = parsed['class-name'] ?? _deriveClassName(collectorId);

  stdout.writeln('Fetching fields from $baseUrl (collector: $collectorId)...');

  final client = JiraCollectorClient(
    config: JiraCollectorConfig(
      baseUrl: baseUrl,
      collectorId: collectorId,
    ),
  );

  try {
    final fields = await client.fetchFields();

    if (fields.isEmpty) {
      stderr.writeln('No fields found. Check your base URL and collector ID.');
      exit(1);
    }

    // Filter out hidden fields — they are handled automatically by the
    // package's submitIssue method (atl_token, pid, collectorId).
    final visibleFields =
        fields.where((f) => f.type != FieldType.hidden).toList();

    stdout.writeln('Found ${visibleFields.length} field(s):');
    for (final f in visibleFields) {
      final req = f.required ? ' (required)' : '';
      stdout.writeln('  - ${f.id}: ${f.label} [${f.type.name}]$req');
    }

    final code = _generateDart(
      className: className,
      fields: visibleFields,
      baseUrl: baseUrl,
      collectorId: collectorId,
    );

    final file = File(output);
    await file.parent.create(recursive: true);
    await file.writeAsString(code);

    stdout.writeln('\nGenerated $output');
  } finally {
    client.dispose();
  }
}

// ---------------------------------------------------------------------------
// Code generation
// ---------------------------------------------------------------------------

String _generateDart({
  required String className,
  required List<JiraCollectorField> fields,
  required String baseUrl,
  required String collectorId,
}) {
  final buf = StringBuffer();

  buf.writeln('// GENERATED FILE — DO NOT EDIT BY HAND');
  buf.writeln('// ignore_for_file: use_null_aware_elements');
  buf.writeln('//');
  buf.writeln('// Re-generate with:');
  buf.writeln(
      '//   dart run flutter_jira_issue_collector:generate_collector \\');
  buf.writeln('//     --base-url $baseUrl \\');
  buf.writeln('//     --collector-id $collectorId');
  buf.writeln();
  buf.writeln(
    "import 'package:flutter_jira_issue_collector/flutter_jira_issue_collector.dart';",
  );
  buf.writeln();

  // Class
  buf.writeln(
      '/// Type-safe helper for the Jira Issue Collector `$collectorId`.');
  buf.writeln('///');
  buf.writeln('/// This class was generated from the live collector form at');
  buf.writeln('/// `$baseUrl`. It exposes a constant for every field ID and a');
  buf.writeln('/// [build] factory that produces a validated field map ready');
  buf.writeln('/// for [JiraIssueCollector.submitInBackground].');
  buf.writeln('abstract final class $className {');

  // Build a mapping from each field to a unique Dart identifier derived
  // from its *label* (human-readable), while the constant *value* is the
  // field's runtime ID. This gives callers readable code like
  //   `MyCollector.description`  (from label "Description")
  // that maps to the runtime key `"description"` (the field ID).
  final dartNames = _assignDartNames(fields);

  // Field ID constants
  buf.writeln('  // ── Field IDs '
      '───────────────────────────────────────────────────');
  buf.writeln();
  for (final f in fields) {
    final dartName = dartNames[f]!;
    buf.writeln('  /// ${f.label} — ${f.type.name}'
        '${f.required ? ' (required)' : ''}');
    buf.writeln("  static const $dartName = '${f.id}';");
    buf.writeln();
  }

  // Config constants
  buf.writeln('  // ── Collector config '
      '──────────────────────────────────────────────');
  buf.writeln();
  buf.writeln("  static const baseUrl = '$baseUrl';");
  buf.writeln("  static const collectorId = '$collectorId';");
  buf.writeln();

  // Collector factory
  buf.writeln('  /// Creates a pre-configured [JiraIssueCollector] instance.');
  buf.writeln('  static JiraIssueCollector createCollector() {');
  buf.writeln('    return JiraIssueCollector(');
  buf.writeln('      config: const JiraCollectorConfig(');
  buf.writeln('        baseUrl: baseUrl,');
  buf.writeln('        collectorId: collectorId,');
  buf.writeln('      ),');
  buf.writeln('    );');
  buf.writeln('  }');
  buf.writeln();

  // build() factory
  final requiredFields = fields.where((f) => f.required).toList();
  final optionalFields = fields.where((f) => !f.required).toList();

  buf.writeln('  /// Builds a field-value map suitable for');
  buf.writeln('  /// [JiraIssueCollector.submitInBackground].');
  buf.writeln('  ///');
  buf.writeln('  /// Required fields are required parameters; optional fields');
  buf.writeln('  /// are nullable and excluded from the map when null.');
  buf.writeln('  static Map<String, dynamic> build({');

  // Required params
  for (final f in requiredFields) {
    final dartType = _dartType(f);
    buf.writeln('    required $dartType ${dartNames[f]!},');
  }
  // Optional params
  for (final f in optionalFields) {
    final dartType = _dartType(f);
    buf.writeln('    $dartType? ${dartNames[f]!},');
  }

  buf.writeln('  }) {');
  buf.writeln('    return {');

  for (final f in requiredFields) {
    final name = dartNames[f]!;
    buf.writeln("      '${f.id}': $name,");
  }
  for (final f in optionalFields) {
    final name = dartNames[f]!;
    buf.writeln("      if ($name != null) '${f.id}': $name,");
  }

  buf.writeln('    };');
  buf.writeln('  }');
  buf.writeln('}');

  return buf.toString();
}

String _dartType(JiraCollectorField field) {
  switch (field.type) {
    case FieldType.number:
      return 'num';
    case FieldType.checkbox:
      return 'bool';
    case FieldType.multiSelect:
      return 'List<String>';
    default:
      return 'String';
  }
}

/// Assigns a unique Dart identifier to each field, derived from the
/// field's *label* (human-readable). Falls back to the field ID if the
/// label is empty. Handles collisions by appending a numeric suffix.
Map<JiraCollectorField, String> _assignDartNames(
  List<JiraCollectorField> fields,
) {
  final result = <JiraCollectorField, String>{};
  final usedNames = <String>{};

  for (final f in fields) {
    // Prefer the label; fall back to the ID.
    final source = f.label.isNotEmpty ? f.label : f.id;
    var name = _dartIdentifier(source);

    // Deduplicate: if two fields produce the same name, append _2, _3, …
    if (usedNames.contains(name)) {
      var suffix = 2;
      while (usedNames.contains('${name}_$suffix')) {
        suffix++;
      }
      name = '${name}_$suffix';
    }

    usedNames.add(name);
    result[f] = name;
  }

  return result;
}

/// Converts a label like "Full Name" or an ID like "full-name" into a
/// valid Dart identifier like `fullName`.
String _dartIdentifier(String id) {
  // Reserved words in Dart that might collide with field IDs.
  const reserved = {
    'default',
    'class',
    'switch',
    'return',
    'new',
    'null',
    'true',
    'false',
    'is',
    'in',
    'this',
    'super',
    'enum',
    'assert',
    'try',
    'catch',
    'throw',
    'void',
    'var',
    'final',
    'const',
    'if',
    'else',
    'for',
    'while',
    'do',
    'break',
    'continue',
    'import',
    'export',
    'part',
    'library',
    'abstract',
    'static',
    'async',
    'await',
    'yield',
    'required',
    'late',
    'type',
  };

  // Replace non-alphanumeric with underscore, then camelCase.
  final parts = id.split(RegExp(r'[^a-zA-Z0-9]'));
  final camel = StringBuffer();
  for (var i = 0; i < parts.length; i++) {
    final p = parts[i];
    if (p.isEmpty) continue;
    if (camel.isEmpty) {
      camel.write(p[0].toLowerCase());
      if (p.length > 1) camel.write(p.substring(1));
    } else {
      camel.write(p[0].toUpperCase());
      if (p.length > 1) camel.write(p.substring(1));
    }
  }

  var result = camel.toString();
  if (result.isEmpty) result = 'field';
  if (reserved.contains(result)) result = '${result}Field';

  return result;
}

/// Derives a PascalCase class name from the collector ID.
String _deriveClassName(String collectorId) {
  // Use a generic name with the last 4 chars of the ID for uniqueness.
  final suffix = collectorId.length >= 4
      ? collectorId.substring(collectorId.length - 4).toUpperCase()
      : collectorId.toUpperCase();
  return 'JiraCollector$suffix';
}

// ---------------------------------------------------------------------------
// Arg parsing (no package:args dependency — keep it lean)
// ---------------------------------------------------------------------------

Map<String, String>? _parseArgs(List<String> args) {
  final result = <String, String>{};

  for (var i = 0; i < args.length; i++) {
    if (args[i] == '--help' || args[i] == '-h') return null;

    if (args[i].startsWith('--') && i + 1 < args.length) {
      result[args[i].substring(2)] = args[i + 1];
      i++;
    }
  }

  if (!result.containsKey('base-url') || !result.containsKey('collector-id')) {
    return null;
  }

  return result;
}

void _printUsage() {
  stderr.writeln('''
Usage:
  dart run flutter_jira_issue_collector:generate_collector \\
    --base-url <JIRA_URL> \\
    --collector-id <ID> \\
    [--output <FILE>] \\
    [--class-name <NAME>]

Required:
  --base-url       Jira Server / Data Center base URL
  --collector-id   The issue collector ID (from the embed script)

Optional:
  --output         Output file path (default: lib/generated/jira_collector_fields.dart)
  --class-name     Generated class name (default: derived from collector ID)

Example:
  dart run flutter_jira_issue_collector:generate_collector \\
    --base-url https://jira.example.com \\
    --collector-id 3e3ffaf3 \\
    --output lib/src/jira_fields.dart \\
    --class-name MyProjectCollector
''');
}
