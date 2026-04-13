import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_jira_issue_collector/flutter_jira_issue_collector.dart';

void main() {
  late FieldParser parser;

  setUp(() {
    parser = FieldParser();
  });

  group('FieldParser', () {
    test('parses text input from field-group', () {
      const html = '''
        <div class="field-group">
          <label for="summary">Summary <span class="required">*</span></label>
          <input type="text" id="summary" name="summary" required />
        </div>
      ''';

      final fields = parser.parse(html);

      expect(fields, hasLength(1));
      expect(fields[0].id, 'summary');
      expect(fields[0].label, 'Summary');
      expect(fields[0].type, FieldType.text);
      expect(fields[0].required, isTrue);
    });

    test('parses textarea field', () {
      const html = '''
        <div class="field-group">
          <label for="description">Description</label>
          <textarea id="description" name="description">Default text</textarea>
        </div>
      ''';

      final fields = parser.parse(html);

      expect(fields, hasLength(1));
      expect(fields[0].id, 'description');
      expect(fields[0].type, FieldType.textarea);
      expect(fields[0].defaultValue, 'Default text');
    });

    test('parses select field with options', () {
      const html = '''
        <div class="field-group">
          <label for="priority">Priority</label>
          <select id="priority" name="priority">
            <option value="">-- Select --</option>
            <option value="1">High</option>
            <option value="2">Medium</option>
            <option value="3">Low</option>
          </select>
        </div>
      ''';

      final fields = parser.parse(html);

      expect(fields, hasLength(1));
      expect(fields[0].id, 'priority');
      expect(fields[0].type, FieldType.select);
      expect(fields[0].options, hasLength(3));
      expect(fields[0].options![0].value, '1');
      expect(fields[0].options![0].label, 'High');
    });

    test('parses email input', () {
      const html = '''
        <div class="field-group">
          <label for="email">Email</label>
          <input type="email" id="email" name="email" />
        </div>
      ''';

      final fields = parser.parse(html);

      expect(fields, hasLength(1));
      expect(fields[0].type, FieldType.email);
    });

    test('parses hidden input', () {
      const html = '''
        <div class="field-group">
          <label for="projectKey">Project</label>
          <input type="hidden" id="projectKey" name="projectKey" value="PROJ" />
        </div>
      ''';

      final fields = parser.parse(html);

      expect(fields, hasLength(1));
      expect(fields[0].type, FieldType.hidden);
      expect(fields[0].defaultValue, 'PROJ');
    });

    test('parses multiple fields', () {
      const html = '''
        <form>
          <div class="field-group">
            <label for="summary">Summary *</label>
            <input type="text" id="summary" name="summary" />
          </div>
          <div class="field-group">
            <label for="description">Description</label>
            <textarea id="description" name="description"></textarea>
          </div>
          <div class="field-group">
            <label for="email">Email</label>
            <input type="email" id="email" name="email" />
          </div>
        </form>
      ''';

      final fields = parser.parse(html);

      expect(fields, hasLength(3));
      expect(fields.map((f) => f.id), ['summary', 'description', 'email']);
    });

    test('falls back to raw input parsing when no field-groups found', () {
      const html = '''
        <form>
          <input type="text" id="summary" name="summary" />
          <textarea id="description" name="description"></textarea>
        </form>
      ''';

      final fields = parser.parse(html);

      expect(fields, hasLength(2));
    });

    test('detects required from asterisk in label', () {
      const html = '''
        <div class="field-group">
          <label for="summary">Summary *</label>
          <input type="text" id="summary" name="summary" />
        </div>
      ''';

      final fields = parser.parse(html);
      expect(fields[0].required, isTrue);
    });

    test('returns empty list for empty HTML', () {
      final fields = parser.parse('');
      expect(fields, isEmpty);
    });
  });
}
