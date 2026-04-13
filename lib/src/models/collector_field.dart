/// The type of a form field in the issue collector.
enum FieldType {
  text,
  textarea,
  select,
  multiSelect,
  hidden,
  email,
  number,
  checkbox,
  radio,
  file,
  unknown,
}

/// A single option in a select/radio field.
class FieldOption {
  final String value;
  final String label;

  const FieldOption({
    required this.value,
    required this.label,
  });

  @override
  String toString() => 'FieldOption($value: $label)';
}

/// Represents a form field parsed from the Jira Issue Collector.
class JiraCollectorField {
  /// The HTML name/id of the field (e.g. "summary", "description", "email").
  final String id;

  /// Human-readable label for the field.
  final String label;

  /// The type of input control.
  final FieldType type;

  /// Whether this field is required for submission.
  final bool required;

  /// Available options for select/radio/multiSelect fields.
  final List<FieldOption>? options;

  /// Default value if any.
  final String? defaultValue;

  const JiraCollectorField({
    required this.id,
    required this.label,
    required this.type,
    this.required = false,
    this.options,
    this.defaultValue,
  });

  @override
  String toString() =>
      'JiraCollectorField($id, type: $type, required: $required)';
}
