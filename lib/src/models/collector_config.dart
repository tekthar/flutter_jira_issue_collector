/// Configuration for connecting to a Jira Issue Collector.
class JiraCollectorConfig {
  /// Base URL of the Jira instance (e.g. "https://jira.example.com").
  final String baseUrl;

  /// The collector ID from the issue collector setup (e.g. "3e3ffaf3").
  final String collectorId;

  /// Locale for the collector form (e.g. "en_US").
  final String locale;

  const JiraCollectorConfig({
    required this.baseUrl,
    required this.collectorId,
    this.locale = 'en_US',
  });

  /// The URL to fetch the collector form HTML.
  String get formUrl =>
      '$baseUrl/rest/collectors/1.0/template/form/$collectorId';
}
