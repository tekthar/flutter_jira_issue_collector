/// A Flutter package to connect to Jira Issue Collector — fetch fields
/// dynamically, show customizable forms, or submit issues programmatically
/// in the background.
library;

// Models
export 'src/models/collector_config.dart';
export 'src/models/collector_field.dart';
export 'src/models/collector_result.dart';

// Services
export 'src/services/jira_collector_client.dart';
export 'src/services/field_parser.dart';

// UI
export 'src/ui/jira_collector_page.dart'
    show JiraCollectorPage, FieldWidgetBuilder, FormLayoutBuilder;
export 'src/ui/jira_collector_dialog.dart'
    show showJiraCollectorDialog, showJiraCollectorBottomSheet;
export 'src/ui/default_field_builder.dart';

// Facade
export 'src/jira_issue_collector.dart';
