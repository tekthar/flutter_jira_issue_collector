import 'package:flutter/material.dart';

import '../models/collector_result.dart';
import '../services/jira_collector_client.dart';
import 'jira_collector_page.dart';

/// Shows the Jira Issue Collector form as a modal bottom sheet.
///
/// Returns a [SubmissionResult] if the issue was submitted, or null if
/// the user dismissed the sheet.
Future<SubmissionResult?> showJiraCollectorBottomSheet(
  BuildContext context, {
  required JiraCollectorClient client,
  Map<String, String> prefillValues = const {},
  Set<String> hiddenFieldIds = const {},
  FieldWidgetBuilder? fieldBuilder,
  FormLayoutBuilder? layoutBuilder,
  ValueChanged<SubmissionResult>? onResult,
  String title = 'Report an Issue',
  bool isDismissible = true,
  bool isScrollControlled = true,
}) {
  return showModalBottomSheet<SubmissionResult>(
    context: context,
    isDismissible: isDismissible,
    isScrollControlled: isScrollControlled,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) => DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (context, scrollController) => JiraCollectorPage(
        client: client,
        prefillValues: prefillValues,
        hiddenFieldIds: hiddenFieldIds,
        fieldBuilder: fieldBuilder,
        layoutBuilder: layoutBuilder,
        onResult: onResult,
        title: title,
      ),
    ),
  );
}

/// Shows the Jira Issue Collector form as a full-screen dialog.
///
/// Returns a [SubmissionResult] if the issue was submitted, or null if
/// the user closed the dialog.
Future<SubmissionResult?> showJiraCollectorDialog(
  BuildContext context, {
  required JiraCollectorClient client,
  Map<String, String> prefillValues = const {},
  Set<String> hiddenFieldIds = const {},
  FieldWidgetBuilder? fieldBuilder,
  FormLayoutBuilder? layoutBuilder,
  ValueChanged<SubmissionResult>? onResult,
  String title = 'Report an Issue',
}) {
  return Navigator.of(context).push<SubmissionResult>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (context) => JiraCollectorPage(
        client: client,
        prefillValues: prefillValues,
        hiddenFieldIds: hiddenFieldIds,
        fieldBuilder: fieldBuilder,
        layoutBuilder: layoutBuilder,
        onResult: onResult,
        title: title,
      ),
    ),
  );
}
