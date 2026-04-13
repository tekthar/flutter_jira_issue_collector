import 'package:flutter/material.dart';

import '../models/collector_field.dart';
import '../models/collector_result.dart';
import '../services/jira_collector_client.dart';
import 'default_field_builder.dart';

/// Signature for building a custom widget for a single field.
///
/// [defaultWidget] is the Material fallback — return it if you only want to
/// customize certain fields.
typedef FieldWidgetBuilder = Widget Function(
  BuildContext context,
  JiraCollectorField field,
  TextEditingController controller,
  ValueChanged<String> onChanged,
  Widget defaultWidget,
);

/// Signature for building a custom form layout around the field widgets.
typedef FormLayoutBuilder = Widget Function(
  BuildContext context,
  List<Widget> fieldWidgets,
  VoidCallback onSubmit,
  bool isSubmitting,
);

/// A full-page widget that renders the Jira Issue Collector form.
///
/// Fetches fields from the collector, renders them using [fieldBuilder]
/// (or default Material widgets), and submits the result.
class JiraCollectorPage extends StatefulWidget {
  final JiraCollectorClient client;

  /// Pre-filled values for specific fields.
  final Map<String, String> prefillValues;

  /// Field IDs that should be pre-filled and hidden from the user.
  final Set<String> hiddenFieldIds;

  /// Custom builder for individual fields. If null, uses default Material widgets.
  final FieldWidgetBuilder? fieldBuilder;

  /// Custom builder for the overall form layout. If null, uses a default
  /// scrollable column with a submit button.
  final FormLayoutBuilder? layoutBuilder;

  /// Called when submission completes (success or failure).
  final ValueChanged<SubmissionResult>? onResult;

  /// Title shown in the default layout's AppBar.
  final String title;

  const JiraCollectorPage({
    super.key,
    required this.client,
    this.prefillValues = const {},
    this.hiddenFieldIds = const {},
    this.fieldBuilder,
    this.layoutBuilder,
    this.onResult,
    this.title = 'Report an Issue',
  });

  @override
  State<JiraCollectorPage> createState() => _JiraCollectorPageState();
}

class _JiraCollectorPageState extends State<JiraCollectorPage> {
  final _formKey = GlobalKey<FormState>();
  final _controllers = <String, TextEditingController>{};
  final _selectValues = <String, String>{};

  List<JiraCollectorField>? _fields;
  bool _loading = true;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFields();
  }

  Future<void> _loadFields() async {
    try {
      final fields = await widget.client.fetchFields();
      if (!mounted) return;

      for (final field in fields) {
        final prefill =
            widget.prefillValues[field.id] ?? field.defaultValue ?? '';
        _controllers[field.id] = TextEditingController(text: prefill);
        if (field.type == FieldType.select ||
            field.type == FieldType.multiSelect) {
          _selectValues[field.id] = prefill;
        }
      }

      setState(() {
        _fields = fields;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _submitting = true);

    final values = <String, dynamic>{};
    for (final field in _fields!) {
      final controller = _controllers[field.id];
      if (controller != null) {
        values[field.id] = controller.text;
      }
      // For select fields, use the stored select value
      if (_selectValues.containsKey(field.id)) {
        values[field.id] = _selectValues[field.id] ?? '';
      }
    }

    final result = await widget.client.submitIssue(values);

    if (!mounted) return;
    setState(() => _submitting = false);

    widget.onResult?.call(result);

    if (result.success && mounted) {
      Navigator.of(context).pop(result);
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Failed to load form',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(_error!, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _loading = true;
                      _error = null;
                    });
                    _loadFields();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final visibleFields = _fields!
        .where((f) =>
            !widget.hiddenFieldIds.contains(f.id) && f.type != FieldType.hidden)
        .toList();

    final fieldWidgets = visibleFields.map((field) {
      final controller = _controllers[field.id]!;

      void onChanged(String value) {
        _selectValues[field.id] = value;
        controller.text = value;
      }

      final defaultWidget = DefaultFieldBuilder.build(
        field: field,
        controller: controller,
        onChanged: onChanged,
        selectedValue: _selectValues[field.id],
      );

      if (widget.fieldBuilder != null) {
        return widget.fieldBuilder!(
          context,
          field,
          controller,
          onChanged,
          defaultWidget,
        );
      }

      return defaultWidget;
    }).toList();

    if (widget.layoutBuilder != null) {
      return Form(
        key: _formKey,
        child: widget.layoutBuilder!(
          context,
          fieldWidgets,
          _submit,
          _submitting,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            ...fieldWidgets,
            const SizedBox(height: 24),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Submit'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
