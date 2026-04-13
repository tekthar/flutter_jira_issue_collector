import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart';

import '../models/collector_field.dart';

/// Parses the HTML form returned by the Jira Issue Collector endpoint
/// into a list of [JiraCollectorField] models.
class FieldParser {
  /// Parse the full HTML response from the collector form endpoint.
  List<JiraCollectorField> parse(String htmlContent) {
    final document = html_parser.parse(htmlContent);
    final fields = <JiraCollectorField>[];

    // Find all form groups — Jira typically wraps fields in .field-group
    final fieldGroups = document.querySelectorAll('.field-group');

    if (fieldGroups.isNotEmpty) {
      for (final group in fieldGroups) {
        final field = _parseFieldGroup(group);
        if (field != null) {
          fields.add(field);
        }
      }
    }

    // Fallback: if no field-groups found, parse raw form inputs
    if (fields.isEmpty) {
      fields.addAll(_parseRawInputs(document));
    }

    return fields;
  }

  JiraCollectorField? _parseFieldGroup(Element group) {
    // Try to find the label
    final labelEl = group.querySelector('label');
    final label =
        labelEl?.text.trim().replaceAll(RegExp(r'\s*\*\s*$'), '') ?? '';

    // Determine if required
    final isRequired = group.querySelector('.required') != null ||
        group.querySelector('[required]') != null ||
        (labelEl?.text.contains('*') ?? false);

    // Find the input element
    final input = group.querySelector('input, textarea, select');
    if (input == null) return null;

    return _elementToField(input, label, isRequired);
  }

  JiraCollectorField? _elementToField(
      Element element, String label, bool isRequired) {
    final tagName = element.localName?.toLowerCase() ?? '';
    final name = element.attributes['name'] ?? element.attributes['id'] ?? '';
    final inputType = element.attributes['type']?.toLowerCase() ?? '';

    if (name.isEmpty) return null;

    // Use the label, or fall back to name
    final fieldLabel = label.isNotEmpty ? label : _humanize(name);

    switch (tagName) {
      case 'textarea':
        return JiraCollectorField(
          id: name,
          label: fieldLabel,
          type: FieldType.textarea,
          required: isRequired,
          defaultValue: element.text.trim(),
        );

      case 'select':
        final options = element
            .querySelectorAll('option')
            .map((o) => FieldOption(
                  value: o.attributes['value'] ?? o.text.trim(),
                  label: o.text.trim(),
                ))
            .where((o) => o.value.isNotEmpty)
            .toList();

        final isMulti = element.attributes.containsKey('multiple');

        return JiraCollectorField(
          id: name,
          label: fieldLabel,
          type: isMulti ? FieldType.multiSelect : FieldType.select,
          required: isRequired,
          options: options,
        );

      case 'input':
        return JiraCollectorField(
          id: name,
          label: fieldLabel,
          type: _mapInputType(inputType),
          required: isRequired || element.attributes.containsKey('required'),
          defaultValue: element.attributes['value'],
        );

      default:
        return null;
    }
  }

  List<JiraCollectorField> _parseRawInputs(Document document) {
    final fields = <JiraCollectorField>[];
    final seen = <String>{};

    for (final element
        in document.querySelectorAll('input, textarea, select')) {
      final name = element.attributes['name'] ?? element.attributes['id'] ?? '';
      if (name.isEmpty || seen.contains(name)) continue;
      seen.add(name);

      // Try to find a label that references this field
      final id = element.attributes['id'] ?? '';
      final labelEl =
          id.isNotEmpty ? document.querySelector('label[for="$id"]') : null;
      final label = labelEl?.text.trim() ?? '';

      final isRequired = element.attributes.containsKey('required') ||
          element.classes.contains('required');

      final field = _elementToField(element, label, isRequired);
      if (field != null) {
        fields.add(field);
      }
    }

    return fields;
  }

  FieldType _mapInputType(String htmlType) {
    switch (htmlType) {
      case 'text':
        return FieldType.text;
      case 'email':
        return FieldType.email;
      case 'number':
        return FieldType.number;
      case 'hidden':
        return FieldType.hidden;
      case 'checkbox':
        return FieldType.checkbox;
      case 'radio':
        return FieldType.radio;
      case 'file':
        return FieldType.file;
      default:
        return FieldType.text;
    }
  }

  String _humanize(String name) {
    return name
        .replaceAll(RegExp(r'[_\-.]'), ' ')
        .replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (m) => '${m[1]} ${m[2]}')
        .split(' ')
        .map(
            (w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
        .join(' ')
        .trim();
  }
}
