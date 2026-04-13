import 'package:dio/dio.dart';
import 'package:html/parser.dart' as html_parser;

import '../models/collector_config.dart';
import '../models/collector_field.dart';
import '../models/collector_result.dart';
import 'field_parser.dart';

/// HTTP client for interacting with the Jira Issue Collector REST API.
class JiraCollectorClient {
  final JiraCollectorConfig config;
  final Dio _dio;
  final FieldParser _parser;

  JiraCollectorClient({
    required this.config,
    Dio? dio,
    FieldParser? parser,
  })  : _dio = dio ?? Dio(),
        _parser = parser ?? FieldParser() {
    _dio.options.baseUrl = config.baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 15);
    _dio.options.receiveTimeout = const Duration(seconds: 15);
    _dio.options.headers['Accept'] = 'text/html, application/json';
  }

  /// Fetch the collector form HTML and parse it into field models.
  Future<List<JiraCollectorField>> fetchFields() async {
    try {
      final response = await _dio.get(
        '/rest/collectors/1.0/template/form/${config.collectorId}',
        queryParameters: {
          'os_authType': 'none',
          'locale': config.locale,
        },
        options: Options(
          responseType: ResponseType.plain,
        ),
      );

      if (response.statusCode == 200) {
        return _parser.parse(response.data as String);
      }

      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message: 'Failed to fetch collector form: ${response.statusCode}',
      );
    } on DioException {
      rethrow;
    }
  }

  /// Submit an issue to the collector.
  ///
  /// [fieldValues] should map field IDs to their values.
  ///
  /// This method first fetches the collector form to extract hidden fields
  /// like `atl_token` (CSRF token) and `pid` (project ID), which are
  /// required by Jira for the submission to succeed. The caller's
  /// [fieldValues] are merged on top — caller values win on conflict.
  Future<SubmissionResult> submitIssue(Map<String, dynamic> fieldValues) async {
    try {
      // Step 1: Fetch the form HTML to extract hidden fields and the
      // session cookie that the atl_token is bound to.
      final (:fields, :cookie) = await _fetchHiddenFields();

      // Step 2: Merge hidden fields with caller-provided values.
      // Caller values win on conflict (e.g. if they explicitly set pid).
      final mergedValues = <String, dynamic>{
        ...fields,
        ...fieldValues,
      };

      final response = await _dio.post(
        '/rest/collectors/1.0/template/form/${config.collectorId}',
        data: mergedValues,
        queryParameters: {
          'os_authType': 'none',
        },
        options: Options(
          contentType: 'application/x-www-form-urlencoded',
          responseType: ResponseType.plain,
          headers: {
            if (cookie != null) 'Cookie': cookie,
            // Belt-and-suspenders: some Jira versions accept this
            // header to skip the XSRF check entirely for REST calls.
            'X-Atlassian-Token': 'no-check',
          },
        ),
      );

      final body = response.data?.toString() ?? '';
      final statusCode = response.statusCode ?? 0;
      final success = statusCode >= 200 && statusCode < 300;

      // Try to extract issue key from response
      String? issueKey;
      final keyMatch = RegExp(r'([A-Z][A-Z0-9]+-\d+)').firstMatch(body);
      if (keyMatch != null) {
        issueKey = keyMatch.group(1);
      }

      return SubmissionResult(
        success: success,
        issueKey: issueKey,
        rawResponse: body,
        statusCode: statusCode,
        errorMessage: success ? null : 'HTTP $statusCode',
      );
    } on DioException catch (e) {
      return SubmissionResult(
        success: false,
        errorMessage: e.message ?? 'Network error',
        rawResponse: e.response?.data?.toString(),
        statusCode: e.response?.statusCode,
      );
    }
  }

  /// Fetches the collector form HTML and extracts all hidden `<input>`
  /// fields (name → value) **and** the session cookies set by Jira.
  ///
  /// Hidden fields typically include:
  /// - `atl_token` — Jira's CSRF protection token (required).
  /// - `pid` — the target project ID (required).
  /// - `collectorId` — echoed back for routing.
  ///
  /// The cookies are returned alongside the fields because the `atl_token`
  /// is only valid within the session that issued it — the POST must send
  /// the same session cookie back or Jira rejects it with 403 XSRF.
  Future<({Map<String, String> fields, String? cookie})>
      _fetchHiddenFields() async {
    try {
      final response = await _dio.get(
        '/rest/collectors/1.0/template/form/${config.collectorId}',
        queryParameters: {
          'os_authType': 'none',
          'locale': config.locale,
        },
        options: Options(responseType: ResponseType.plain),
      );

      if (response.statusCode != 200) {
        return (fields: <String, String>{}, cookie: null);
      }

      // Extract session cookies from the response so we can replay them
      // on the subsequent POST.
      final setCookieHeaders = response.headers['set-cookie'];
      String? cookie;
      if (setCookieHeaders != null && setCookieHeaders.isNotEmpty) {
        // Each set-cookie header may contain attributes (Path, HttpOnly,
        // etc.) — we only need the name=value part before the first ';'.
        cookie = setCookieHeaders.map((h) => h.split(';').first).join('; ');
      }

      final document = html_parser.parse(response.data as String);
      final hiddenInputs = document.querySelectorAll('input[type="hidden"]');

      final fields = <String, String>{};
      for (final input in hiddenInputs) {
        final name = input.attributes['name'];
        final value = input.attributes['value'];
        if (name != null && name.isNotEmpty && value != null) {
          fields[name] = value;
        }
      }
      return (fields: fields, cookie: cookie);
    } catch (_) {
      return (fields: <String, String>{}, cookie: null);
    }
  }

  /// Dispose the HTTP client.
  void dispose() {
    _dio.close();
  }
}
