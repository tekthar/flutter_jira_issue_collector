import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';

import 'models/collector_config.dart';
import 'models/collector_field.dart';
import 'models/collector_result.dart';
import 'services/jira_collector_client.dart';
import 'ui/jira_collector_dialog.dart';
import 'ui/jira_collector_page.dart';

/// Main entry point for the Jira Issue Collector package.
///
/// Supports two modes:
/// - **UI Mode**: [showCollector] / [showCollectorBottomSheet] — fetches
///   fields dynamically and shows a customizable form.
/// - **Background Mode**: [submitInBackground] — submits an issue
///   programmatically without any UI.
class JiraIssueCollector {
  final JiraCollectorConfig config;
  late final JiraCollectorClient _client;

  /// Create a collector instance.
  ///
  /// Optionally provide a custom [Dio] instance for advanced configuration
  /// (interceptors, proxies, certificates, etc.).
  JiraIssueCollector({
    required this.config,
    Dio? dio,
  }) {
    _client = JiraCollectorClient(config: config, dio: dio);
  }

  /// Fetch the available fields from the issue collector without showing UI.
  ///
  /// Useful for inspecting what fields are available, or for building
  /// a custom submission payload.
  Future<List<JiraCollectorField>> fetchFields() {
    return _client.fetchFields();
  }

  /// Submit an issue in the background without any UI.
  ///
  /// [fieldValues] should map field IDs (from [fetchFields]) to their values.
  ///
  /// Example:
  /// ```dart
  /// final result = await collector.submitInBackground(
  ///   fieldValues: {
  ///     'summary': 'Crash on login',
  ///     'description': 'App crashes when tapping login button',
  ///     'email': 'user@example.com',
  ///   },
  /// );
  /// ```
  Future<SubmissionResult> submitInBackground({
    required Map<String, dynamic> fieldValues,
  }) {
    return _client.submitIssue(fieldValues);
  }

  /// Show the issue collector form as a full-screen dialog.
  ///
  /// Returns a [SubmissionResult] on successful submission, or null if the
  /// user dismisses the dialog.
  ///
  /// [prefillValues] — pre-populate specific fields.
  /// [hiddenFieldIds] — fields that are pre-filled and hidden from the user.
  /// [fieldBuilder] — custom widget builder per field.
  /// [layoutBuilder] — custom overall form layout.
  Future<SubmissionResult?> showCollector(
    BuildContext context, {
    Map<String, String> prefillValues = const {},
    Set<String> hiddenFieldIds = const {},
    FieldWidgetBuilder? fieldBuilder,
    FormLayoutBuilder? layoutBuilder,
    ValueChanged<SubmissionResult>? onResult,
    String title = 'Report an Issue',
  }) {
    return showJiraCollectorDialog(
      context,
      client: _client,
      prefillValues: prefillValues,
      hiddenFieldIds: hiddenFieldIds,
      fieldBuilder: fieldBuilder,
      layoutBuilder: layoutBuilder,
      onResult: onResult,
      title: title,
    );
  }

  /// Show the issue collector form as a bottom sheet.
  ///
  /// Returns a [SubmissionResult] on successful submission, or null if the
  /// user dismisses the sheet.
  Future<SubmissionResult?> showCollectorBottomSheet(
    BuildContext context, {
    Map<String, String> prefillValues = const {},
    Set<String> hiddenFieldIds = const {},
    FieldWidgetBuilder? fieldBuilder,
    FormLayoutBuilder? layoutBuilder,
    ValueChanged<SubmissionResult>? onResult,
    String title = 'Report an Issue',
  }) {
    return showJiraCollectorBottomSheet(
      context,
      client: _client,
      prefillValues: prefillValues,
      hiddenFieldIds: hiddenFieldIds,
      fieldBuilder: fieldBuilder,
      layoutBuilder: layoutBuilder,
      onResult: onResult,
      title: title,
    );
  }

  /// Dispose the underlying HTTP client.
  void dispose() {
    _client.dispose();
  }
}
