## 0.2.0

- **Code generator** — new CLI tool `generate_collector` that fetches your collector's live fields and generates a type-safe Dart helper class with field ID constants, a `build()` factory, and a `createCollector()` factory
- **CSRF token handling** — `submitIssue()` now automatically fetches hidden form fields (`atl_token`, `pid`) and replays session cookies, fixing 403 XSRF rejections on Jira Data Center
- **`X-Atlassian-Token: no-check` header** — added as additional XSRF bypass for compatible Jira versions
- Updated example app to use the generated collector class
- Expanded README with code generator docs and real-world error reporting example

## 0.1.0

- Initial release
- Fetch issue collector fields dynamically from Jira
- Show customizable form UI with builder pattern
- Submit issues programmatically in the background
- Prefill and hide fields support
