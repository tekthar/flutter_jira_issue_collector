/// Result of submitting an issue through the collector.
class SubmissionResult {
  /// Whether the submission was successful.
  final bool success;

  /// The created issue key (e.g. "PROJ-123"), if available.
  final String? issueKey;

  /// Error message if the submission failed.
  final String? errorMessage;

  /// The raw response body from the server.
  final String? rawResponse;

  /// HTTP status code of the response.
  final int? statusCode;

  const SubmissionResult({
    required this.success,
    this.issueKey,
    this.errorMessage,
    this.rawResponse,
    this.statusCode,
  });

  @override
  String toString() => success
      ? 'SubmissionResult(success, issue: $issueKey)'
      : 'SubmissionResult(failed: $errorMessage)';
}
