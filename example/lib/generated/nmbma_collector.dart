// GENERATED FILE — DO NOT EDIT BY HAND
// ignore_for_file: use_null_aware_elements
//
// Re-generate with:
//   dart run flutter_jira_issue_collector:generate_collector \
//     --base-url https://jira.bpo-hq.com \
//     --collector-id 3e3ffaf3

import 'package:flutter_jira_issue_collector/flutter_jira_issue_collector.dart';

/// Type-safe helper for the Jira Issue Collector `3e3ffaf3`.
///
/// This class was generated from the live collector form at
/// `https://jira.bpo-hq.com`. It exposes a constant for every field ID and a
/// [build] factory that produces a validated field map ready
/// for [JiraIssueCollector.submitInBackground].
abstract final class NmbmaCollector {
  // ── Field IDs ───────────────────────────────────────────────────

  /// What went wrong? — textarea
  static const whatWentWrong = 'description';

  /// Attach file — file
  static const attachFile = 'screenshot';

  /// Name — text
  static const name = 'fullname';

  /// Email — text
  static const email = 'email';

  /// Web Info — textarea
  static const webInfo = 'webInfo';

  // ── Collector config ──────────────────────────────────────────────

  static const baseUrl = 'https://jira.bpo-hq.com';
  static const collectorId = '3e3ffaf3';

  /// Creates a pre-configured [JiraIssueCollector] instance.
  static JiraIssueCollector createCollector() {
    return JiraIssueCollector(
      config: const JiraCollectorConfig(
        baseUrl: baseUrl,
        collectorId: collectorId,
      ),
    );
  }

  /// Builds a field-value map suitable for
  /// [JiraIssueCollector.submitInBackground].
  ///
  /// Required fields are required parameters; optional fields
  /// are nullable and excluded from the map when null.
  static Map<String, dynamic> build({
    String? whatWentWrong,
    String? attachFile,
    String? name,
    String? email,
    String? webInfo,
  }) {
    return {
      if (whatWentWrong != null) 'description': whatWentWrong,
      if (attachFile != null) 'screenshot': attachFile,
      if (name != null) 'fullname': name,
      if (email != null) 'email': email,
      if (webInfo != null) 'webInfo': webInfo,
    };
  }
}
