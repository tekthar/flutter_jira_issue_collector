# flutter_jira_issue_collector

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Flutter](https://img.shields.io/badge/Flutter-%3E%3D3.10-02569B.svg)](https://flutter.dev)
[![pub.dev](https://img.shields.io/pub/v/flutter_jira_issue_collector.svg)](https://pub.dev/packages/flutter_jira_issue_collector)
[![Sponsor](https://img.shields.io/badge/Sponsor-Tekthar-EA4AAA.svg?logo=github-sponsors)](https://github.com/sponsors/tekthar)

Jira Issue Collector for Flutter -- fetch collector fields dynamically, show customizable forms, or submit issues programmatically in the background. Includes a **code generator** that produces type-safe Dart helpers from your collector's live fields.

## Features

- **Code generator** -- fetches your collector's fields and generates a typed Dart class (no guessing field IDs)
- Fetches issue collector form fields dynamically from Jira (Data Center / Server)
- Shows a customizable form UI using builder pattern (bring your own widgets)
- Submits issues programmatically in the background without any UI
- Prefill and hide specific fields (e.g. email, reporter name)
- Includes default Material field renderers as opt-in fallback
- Full-screen dialog and bottom sheet presentation modes

## Getting Started

Add the package to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_jira_issue_collector: ^0.1.0
```

## Quick Start (recommended)

Every Jira collector has different fields. The code generator fetches
yours and produces a type-safe Dart class so you never have to guess
field IDs.

### 1. Generate your collector helper

```bash
dart run flutter_jira_issue_collector:generate_collector \
  --base-url https://jira.example.com \
  --collector-id 3e3ffaf3 \
  --output lib/generated/my_collector.dart \
  --class-name MyCollector
```

This connects to Jira, discovers the form fields, and generates:

```dart
// GENERATED FILE — DO NOT EDIT BY HAND
import 'package:flutter_jira_issue_collector/flutter_jira_issue_collector.dart';

abstract final class MyCollector {
  // Variable names come from field labels, values are runtime IDs.
  /// What went wrong? — textarea
  static const whatWentWrong = 'description';

  /// Name — text
  static const name = 'fullname';

  /// Email — text
  static const email = 'email';

  static const baseUrl = 'https://jira.example.com';
  static const collectorId = '3e3ffaf3';

  /// Creates a pre-configured [JiraIssueCollector] instance.
  static JiraIssueCollector createCollector() { /* ... */ }

  /// Builds a field-value map. Only fields that exist in the
  /// collector are accepted — the compiler catches the rest.
  static Map<String, dynamic> build({
    String? whatWentWrong,
    String? name,
    String? email,
  }) {
    return {
      if (whatWentWrong != null) 'description': whatWentWrong,
      if (name != null) 'fullname': name,
      if (email != null) 'email': email,
    };
  }
}
```

### 2. Use it in your app

```dart
import 'generated/my_collector.dart';

final collector = MyCollector.createCollector();

// Background submission — type-safe, no magic strings.
final result = await collector.submitInBackground(
  fieldValues: MyCollector.build(
    whatWentWrong: 'Server 500 on login — POST /api/auth',
    email: 'ops@example.com',
  ),
);

// Prefilled UI — use constants for field IDs.
await collector.showCollector(
  context,
  prefillValues: {
    MyCollector.name: 'John Doe',
    MyCollector.email: 'user@example.com',
  },
  hiddenFieldIds: {MyCollector.name, MyCollector.email},
);
```

If the collector's fields change in Jira, re-run the generator — your
code won't compile until you update the call sites.

### Generator options

| Flag | Required | Default | Description |
|------|----------|---------|-------------|
| `--base-url` | Yes | -- | Jira Server / Data Center URL |
| `--collector-id` | Yes | -- | Collector ID from embed script |
| `--output` | No | `lib/generated/jira_collector_fields.dart` | Output file |
| `--class-name` | No | Derived from ID | Generated class name |

## Manual Setup (without code generator)

If you prefer to configure manually:

```dart
import 'package:flutter_jira_issue_collector/flutter_jira_issue_collector.dart';

final collector = JiraIssueCollector(
  config: JiraCollectorConfig(
    baseUrl: 'https://jira.example.com',
    collectorId: '3e3ffaf3',
  ),
);
```

### Discover fields at runtime

```dart
final fields = await collector.fetchFields();
for (final field in fields) {
  print('${field.id}: ${field.label} (${field.type}, required: ${field.required})');
}
```

### Background submission

```dart
final result = await collector.submitInBackground(
  fieldValues: {'description': 'Something went wrong.'},
);
if (result.success) {
  print('Issue created: ${result.issueKey}');
}
```

### UI Mode -- dialog

```dart
final result = await collector.showCollector(context);
```

### UI Mode -- bottom sheet

```dart
final result = await collector.showCollectorBottomSheet(context);
```

### Custom field rendering

```dart
final result = await collector.showCollector(
  context,
  fieldBuilder: (context, field, controller, onChanged, defaultWidget) {
    if (field.id == 'description') {
      return MyCustomDescriptionField(controller: controller);
    }
    return defaultWidget;
  },
  layoutBuilder: (context, fieldWidgets, onSubmit, isSubmitting) {
    return MyCustomFormLayout(
      fields: fieldWidgets,
      onSubmit: onSubmit,
      isSubmitting: isSubmitting,
    );
  },
);
```

## Real-world: Automated Error Reporting

A common pattern is reporting server errors to Jira automatically from a
Dio interceptor. Using the generated helper:

```dart
import 'generated/my_collector.dart';

class JiraErrorReporter {
  JiraErrorReporter() : _collector = MyCollector.createCollector();
  final JiraIssueCollector _collector;

  Future<void> report({
    required String method,
    required String path,
    required int statusCode,
    String? requestBody,
    String? responseBody,
    String? userName,
    String? userEmail,
  }) async {
    try {
      final description = StringBuffer()
        ..writeln('[Mobile] Server $statusCode -- $method $path')
        ..writeln()
        ..writeln('Method: $method')
        ..writeln('Path: $path')
        ..writeln('Status: $statusCode')
        ..writeln('Timestamp: ${DateTime.now().toUtc().toIso8601String()}');

      if (requestBody != null) {
        description
          ..writeln()
          ..writeln('--- Request Body ---')
          ..writeln(requestBody);
      }
      if (responseBody != null) {
        description
          ..writeln()
          ..writeln('--- Response Body ---')
          ..writeln(responseBody);
      }

      await _collector.submitInBackground(
        fieldValues: MyCollector.build(
          whatWentWrong: description.toString(),
          name: userName,
          email: userEmail,
        ),
      );
    } catch (_) {
      // Never crash the app over a failed Jira report.
    }
  }

  void dispose() => _collector.dispose();
}
```

## Jira Setup

1. In Jira, go to **Administration > Issue Collectors**
2. Create or edit a collector
3. Copy the **collector ID** from the embed script URL:
   ```
   .../issueCollectorBootstrap.js?collectorId=3e3ffaf3
   ```
4. Use your Jira base URL and collector ID with the code generator or `JiraCollectorConfig`

## Cleanup

```dart
collector.dispose();
```

## License

MIT
