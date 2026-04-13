import 'package:flutter/material.dart';
import 'package:flutter_jira_issue_collector/flutter_jira_issue_collector.dart';

import 'generated/nmbma_collector.dart';

void main() {
  runApp(const ExampleApp());
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Jira Issue Collector Example',
      theme: ThemeData(
        colorSchemeSeed: Colors.blue,
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Using the generated collector — no manual config needed.
  late final JiraIssueCollector _collector;

  @override
  void initState() {
    super.initState();
    _collector = NmbmaCollector.createCollector();
  }

  @override
  void dispose() {
    _collector.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Jira Collector Example')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // --- UI Mode: Full-screen dialog ---
          _SectionCard(
            title: 'UI Mode — Full-screen Dialog',
            description:
                'Opens the issue collector form as a full-screen dialog. '
                'Fields are fetched dynamically from Jira.',
            buttonLabel: 'Open Dialog',
            onPressed: () => _showDialog(context),
          ),
          const SizedBox(height: 16),

          // --- UI Mode: Bottom sheet ---
          _SectionCard(
            title: 'UI Mode — Bottom Sheet',
            description:
                'Opens the issue collector as a draggable bottom sheet.',
            buttonLabel: 'Open Bottom Sheet',
            onPressed: () => _showBottomSheet(context),
          ),
          const SizedBox(height: 16),

          // --- UI Mode: With prefill + hidden fields ---
          _SectionCard(
            title: 'UI Mode — Prefilled + Hidden Fields',
            description:
                'Opens the form with name and email prefilled and hidden, '
                'so the user does not see or modify them.',
            buttonLabel: 'Open Prefilled',
            onPressed: () => _showPrefilled(context),
          ),
          const SizedBox(height: 16),

          // --- Background Mode: type-safe ---
          _SectionCard(
            title: 'Background Mode — Type-safe Submit',
            description: 'Submits an issue silently using the generated '
                'NmbmaCollector.build() — field names are checked '
                'at compile time.',
            buttonLabel: 'Submit in Background',
            onPressed: () => _submitBackground(context),
          ),
          const SizedBox(height: 16),

          // --- Automated Error Reporting ---
          _SectionCard(
            title: 'Automated Error Reporting',
            description:
                'Simulates an HTTP 500 error and creates a Jira ticket '
                'with full request/response details using the generated '
                'typed fields.',
            buttonLabel: 'Simulate Server Error',
            onPressed: () => _simulateErrorReport(context),
          ),
          const SizedBox(height: 16),

          // --- Inspect Fields ---
          _SectionCard(
            title: 'Inspect Available Fields',
            description:
                'Fetches and displays the fields available in the collector. '
                'Useful for verifying generated code is up-to-date.',
            buttonLabel: 'Fetch Fields',
            onPressed: () => _inspectFields(context),
          ),
        ],
      ),
    );
  }

  Future<void> _showDialog(BuildContext context) async {
    final result = await _collector.showCollector(
      context,
      onResult: (r) => _showSnackBar(context, r),
    );
    if (result != null && context.mounted) {
      _showSnackBar(context, result);
    }
  }

  Future<void> _showBottomSheet(BuildContext context) async {
    final result = await _collector.showCollectorBottomSheet(
      context,
      onResult: (r) => _showSnackBar(context, r),
    );
    if (result != null && context.mounted) {
      _showSnackBar(context, result);
    }
  }

  Future<void> _showPrefilled(BuildContext context) async {
    // Use generated constants for field IDs — no magic strings.
    final result = await _collector.showCollector(
      context,
      prefillValues: {
        NmbmaCollector.name: 'John Doe',
        NmbmaCollector.email: 'user@example.com',
      },
      hiddenFieldIds: {NmbmaCollector.name, NmbmaCollector.email},
      onResult: (r) => _showSnackBar(context, r),
    );
    if (result != null && context.mounted) {
      _showSnackBar(context, result);
    }
  }

  Future<void> _submitBackground(BuildContext context) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Submitting issue...')),
    );

    // Type-safe submission — the compiler ensures we only use fields
    // that actually exist in the collector.
    final result = await _collector.submitInBackground(
      fieldValues: NmbmaCollector.build(
        whatWentWrong:
            'This issue was submitted programmatically from the Flutter app.\n'
            'Timestamp: ${DateTime.now().toUtc().toIso8601String()}',
        name: 'Flutter App',
        email: 'flutter-app@example.com',
      ),
    );

    if (!context.mounted) return;
    _showSnackBar(context, result);
  }

  Future<void> _simulateErrorReport(BuildContext context) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Reporting simulated error...')),
    );

    // Build a rich error description — the kind an interceptor would send.
    final report = StringBuffer()
      ..writeln('[Mobile] Server 500 — POST /api/example/action')
      ..writeln()
      ..writeln('Method: POST')
      ..writeln('Path: /api/example/action')
      ..writeln('Status: 500')
      ..writeln('Timestamp: ${DateTime.now().toUtc().toIso8601String()}')
      ..writeln()
      ..writeln('--- Request Body ---')
      ..writeln('{"id": "abc-123", "action": "submit"}')
      ..writeln()
      ..writeln('--- Response Body ---')
      ..writeln('{"error": "Internal Server Error"}')
      ..writeln()
      ..writeln('--- User ---')
      ..writeln('ID: user-42')
      ..writeln('Name: Jane Doe')
      ..writeln('Email: jane@example.com');

    // Submit using the generated typed helper.
    final result = await _collector.submitInBackground(
      fieldValues: NmbmaCollector.build(
        whatWentWrong: report.toString(),
        name: 'Jane Doe',
        email: 'jane@example.com',
      ),
    );

    if (!context.mounted) return;
    _showSnackBar(context, result);
  }

  Future<void> _inspectFields(BuildContext context) async {
    try {
      final fields = await _collector.fetchFields();
      if (!context.mounted) return;

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Available Fields'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: fields.length,
              itemBuilder: (ctx, i) {
                final f = fields[i];
                return ListTile(
                  title: Text(f.label),
                  subtitle: Text(
                    'id: ${f.id} | type: ${f.type.name} | '
                    'required: ${f.required}',
                  ),
                  dense: true,
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching fields: $e')),
      );
    }
  }

  void _showSnackBar(BuildContext context, SubmissionResult result) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.success
              ? 'Issue submitted! ${result.issueKey ?? ''}'
              : 'Failed: ${result.errorMessage}',
        ),
        backgroundColor: result.success ? Colors.green : Colors.red,
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final String description;
  final String buttonLabel;
  final VoidCallback onPressed;

  const _SectionCard({
    required this.title,
    required this.description,
    required this.buttonLabel,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(description),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: onPressed,
              child: Text(buttonLabel),
            ),
          ],
        ),
      ),
    );
  }
}
