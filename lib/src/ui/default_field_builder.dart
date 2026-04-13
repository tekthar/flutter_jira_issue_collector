import 'package:flutter/material.dart';

import '../models/collector_field.dart';

/// Builds a default Material widget for a [JiraCollectorField].
///
/// Used as the fallback when no custom [FieldWidgetBuilder] is provided.
class DefaultFieldBuilder {
  /// Build a widget for the given field.
  ///
  /// [controller] is pre-populated with any prefill value.
  /// [onChanged] should be called when the value changes (for select fields).
  static Widget build({
    required JiraCollectorField field,
    required TextEditingController controller,
    required ValueChanged<String> onChanged,
    String? selectedValue,
  }) {
    switch (field.type) {
      case FieldType.textarea:
        return _buildTextField(
          field: field,
          controller: controller,
          maxLines: 5,
        );

      case FieldType.select:
        return _buildDropdown(
          field: field,
          selectedValue: selectedValue ?? controller.text,
          onChanged: onChanged,
        );

      case FieldType.multiSelect:
        return _buildDropdown(
          field: field,
          selectedValue: selectedValue ?? controller.text,
          onChanged: onChanged,
        );

      case FieldType.checkbox:
        return _buildCheckbox(
          field: field,
          controller: controller,
          onChanged: onChanged,
        );

      case FieldType.email:
        return _buildTextField(
          field: field,
          controller: controller,
          keyboardType: TextInputType.emailAddress,
        );

      case FieldType.number:
        return _buildTextField(
          field: field,
          controller: controller,
          keyboardType: TextInputType.number,
        );

      case FieldType.hidden:
        return const SizedBox.shrink();

      case FieldType.text:
      case FieldType.radio:
      case FieldType.file:
      case FieldType.unknown:
        return _buildTextField(
          field: field,
          controller: controller,
        );
    }
  }

  static Widget _buildTextField({
    required JiraCollectorField field,
    required TextEditingController controller,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: field.label,
          hintText: field.label,
          border: const OutlineInputBorder(),
          suffixText: field.required ? '*' : null,
        ),
        validator: field.required
            ? (value) {
                if (value == null || value.trim().isEmpty) {
                  return '${field.label} is required';
                }
                return null;
              }
            : null,
      ),
    );
  }

  static Widget _buildDropdown({
    required JiraCollectorField field,
    required String selectedValue,
    required ValueChanged<String> onChanged,
  }) {
    final options = field.options ?? [];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<String>(
        initialValue:
            options.any((o) => o.value == selectedValue) ? selectedValue : null,
        decoration: InputDecoration(
          labelText: field.label,
          border: const OutlineInputBorder(),
          suffixText: field.required ? '*' : null,
        ),
        items: options
            .map((o) => DropdownMenuItem(
                  value: o.value,
                  child: Text(o.label),
                ))
            .toList(),
        onChanged: (value) {
          if (value != null) onChanged(value);
        },
        validator: field.required
            ? (value) {
                if (value == null || value.isEmpty) {
                  return '${field.label} is required';
                }
                return null;
              }
            : null,
      ),
    );
  }

  static Widget _buildCheckbox({
    required JiraCollectorField field,
    required TextEditingController controller,
    required ValueChanged<String> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: StatefulBuilder(
        builder: (context, setState) {
          final checked = controller.text == 'true';
          return CheckboxListTile(
            title: Text(field.label),
            value: checked,
            onChanged: (value) {
              setState(() {
                final newVal = (value ?? false).toString();
                controller.text = newVal;
                onChanged(newVal);
              });
            },
            controlAffinity: ListTileControlAffinity.leading,
          );
        },
      ),
    );
  }
}
