# MCP Elicitation Test App

Small Laravel app for testing `laravel/mcp` elicitation support from a real application.

The app installs `laravel/mcp` from the GitHub fork branch:

```bash
composer show laravel/mcp --locked --direct
```

Expected source:

```text
https://github.com/datashaman/mcp.git
dev-mcp_elicitations
```

## MCP Servers

The app registers one server in `routes/ai.php`:

```php
Mcp::local('elicit', ElicitationServer::class);
Mcp::web('/mcp/elicit', ElicitationServer::class);
```

It exposes a working support-request tool:

```text
triage-support-request
```

The tool sends a form elicitation for a realistic support request. It currently uses a minimal text-only schema so clients with early elicitation support render the actual fields reliably. It exercises:

- multiple required string fields
- field titles
- accepted content handling

The response summarizes the accepted request.

It also exposes schema probes for client compatibility testing:

```text
probe-01-text-only
probe-02-description
probe-03-min-length
probe-04-email-format
probe-05-enum
probe-06-integer
probe-07-integer-bounds
probe-08-number
probe-09-boolean
probe-10-defaults
probe-11-titled-enum
probe-12-multi-enum
```

Run the probes in order from an MCP client. The first probe that stops rendering editable form fields identifies the schema feature that client does not currently support.

## Codex Config

Codex reads `.codex/config.toml`:

```toml
[mcp_servers.elicit-local]
command = "php"
args = ["artisan", "mcp:start", "elicit"]

[mcp_servers.elicit-http]
url = "https://mcp-elicit-test-app.test/mcp/elicit"
```

Use `elicit-local` for stdio. Use `elicit-http` for streamable HTTP through Valet.

The committed HTTP config is already set up for the secured Valet URL:

```text
https://mcp-elicit-test-app.test/mcp/elicit
```

Claude Code also reads the project `.mcp.json` when it is launched from this project root. If the servers do not appear in `/mcp`, restart Claude Code from this directory and approve the project MCP config when prompted.

## Valet

From this app directory:

```bash
valet link mcp-elicit-test-app
valet secure mcp-elicit-test-app
```

HTTP MCP URL:

```text
https://mcp-elicit-test-app.test/mcp/elicit
```

## Smoke Tests

Run the Laravel test suite:

```bash
php artisan test
```

Run the HTTP elicitation smoke test against the default Valet URL:

```bash
node scripts/mcp-elicit-smoke.mjs
```

Test the 2025-11-25 protocol shape:

```bash
MCP_PROTOCOL_VERSION=2025-11-25 node scripts/mcp-elicit-smoke.mjs
```

Run every schema probe over HTTP:

```bash
node scripts/mcp-elicit-probes.mjs
MCP_PROTOCOL_VERSION=2025-11-25 node scripts/mcp-elicit-probes.mjs
```

Override the URL when needed:

```bash
MCP_TEST_URL=https://some-host.test/mcp/elicit node scripts/mcp-elicit-smoke.mjs
```

## Codex Elicitation Compatibility Report

Observed from Codex MCP tool calls on 2026-05-16.

### `elicit-http`

| Probe | Expected feature | Codex render behavior |
| --- | --- | --- |
| `probe-01-text-only` | Required string fields | Editable fields rendered correctly. |
| `probe-02-description` | Field descriptions | Editable fields rendered correctly. |
| `probe-03-min-length` | String `minLength` | Editable fields rendered correctly. |
| `probe-04-email-format` | String `format: email` | Editable fields rendered correctly. |
| `probe-05-enum` | String enum | Editable fields rendered correctly. |
| `probe-06-integer` | Integer field | Editable fields did not render; only the approval/decline prompt appeared. |
| `probe-07-integer-bounds` | Integer field with bounds | Editable fields did not render; only the approval/decline prompt appeared. |
| `probe-08-number` | Number field | Editable fields did not render; only the approval/decline prompt appeared. |
| `probe-09-boolean` | Boolean field | Editable boolean field rendered correctly. |
| `probe-10-defaults` | Default values | Editable fields rendered, but the string default for `name` did not appear. The other defaults could not be confirmed visually during this run. |
| `probe-11-titled-enum` | Enum values with titles | Editable fields rendered correctly. |
| `probe-12-multi-enum` | Multi-select enum array | Editable fields did not render; only the approval/decline prompt appeared. |

### `elicit-local`

All 12 local probe tools were exposed in Codex during the rerun.

| Probe | Expected feature | Codex render behavior |
| --- | --- | --- |
| `probe-01-text-only` | Required string fields | Editable fields rendered correctly. |
| `probe-02-description` | Field descriptions | Editable fields rendered correctly. |
| `probe-03-min-length` | String `minLength` | Editable fields rendered, but min-length validation was not enforced. |
| `probe-04-email-format` | String `format: email` | Editable fields rendered, but email format validation was not enforced. |
| `probe-05-enum` | String enum | Editable fields rendered correctly. |
| `probe-06-integer` | Integer field | Editable fields did not render; only the approval/decline prompt appeared. |
| `probe-07-integer-bounds` | Integer field with bounds | Editable fields did not render; only the approval/decline prompt appeared. |
| `probe-08-number` | Number field | Editable fields did not render; only the approval/decline prompt appeared. |
| `probe-09-boolean` | Boolean field | Editable boolean field rendered correctly. |
| `probe-10-defaults` | Default values | Editable fields rendered, and the string default for `name` appeared. |
| `probe-11-titled-enum` | Enum values with titles | Editable fields rendered correctly. |
| `probe-12-multi-enum` | Multi-select enum array | Editable fields did not render; only the approval/decline prompt appeared. |

Summary: Codex renders basic string fields, string enums, titled string enums,
and booleans over HTTP and local stdio. Numeric schemas and multi-enum arrays
fall back to an approval/decline-only prompt. Default-valued fields render in
both transports, but the HTTP run did not show the `name` default while the local
stdio run did.

## Claude Code Elicitation Compatibility Report

Observed from Claude Code MCP tool calls on 2026-05-16.

### `elicit-http`

| Probe | Expected feature | Claude Code render behavior |
| --- | --- | --- |
| `probe-01-text-only` | Required string fields | Editable fields rendered correctly. |
| `probe-02-description` | Field descriptions | Editable fields rendered correctly. |
| `probe-03-min-length` | String `minLength` | Editable fields rendered correctly. |
| `probe-04-email-format` | String `format: email` | Editable fields rendered correctly. |
| `probe-05-enum` | String enum | Editable fields rendered correctly. |
| `probe-06-integer` | Integer field | Editable fields rendered correctly. |
| `probe-07-integer-bounds` | Integer field with bounds | Editable fields rendered correctly. |
| `probe-08-number` | Number field | Editable fields rendered correctly. |
| `probe-09-boolean` | Boolean field | Editable boolean field rendered correctly. |
| `probe-10-defaults` | Default values | Editable fields rendered with defaults pre-populated. |
| `probe-11-titled-enum` | Enum values with titles | Initially hung the client with no form; fixed in `laravel/mcp` (see below), then rendered editable fields correctly. |
| `probe-12-multi-enum` | Multi-select enum array | Editable fields rendered correctly. |

Summary: Claude Code renders every probe as editable form fields over HTTP,
including numeric, boolean, default-valued, titled-enum, and multi-enum
schemas — once the titled-enum bug was fixed.

### `elicit-local`

All 12 probe tools were exposed over stdio.

| Probe | Expected feature | Claude Code render behavior |
| --- | --- | --- |
| `probe-01-text-only` | Required string fields | Editable fields rendered correctly. |
| `probe-02-description` | Field descriptions | Editable fields rendered correctly. |
| `probe-03-min-length` | String `minLength` | Editable fields rendered correctly. |
| `probe-04-email-format` | String `format: email` | Editable fields rendered correctly. |
| `probe-05-enum` | String enum | Editable fields rendered correctly. |
| `probe-06-integer` | Integer field | Editable fields rendered correctly. |
| `probe-07-integer-bounds` | Integer field with bounds | Editable fields rendered correctly. |
| `probe-08-number` | Number field | Editable fields rendered correctly. |
| `probe-09-boolean` | Boolean field | Editable boolean field rendered correctly. |
| `probe-10-defaults` | Default values | Editable fields rendered with defaults pre-populated. |
| `probe-11-titled-enum` | Enum values with titles | Editable fields rendered correctly (with the `laravel/mcp` titled-enum fix applied). |
| `probe-12-multi-enum` | Multi-select enum array | Editable fields rendered correctly. |

Summary: Claude Code renders every probe as editable form fields over stdio
as well, matching its HTTP behavior.

### Titled-enum bug found and fixed

`probe-11-titled-enum` originally hung Claude Code: no form appeared and the
elicitation never completed.

Root cause was in `laravel/mcp` itself. `EnumField::buildTitledSchema()` and
`MultiEnumField::buildTitledItems()` emitted `oneOf`/`anyOf` with bare `const`
entries and no `type`. That construct is outside the restricted JSON Schema
subset the MCP elicitation spec permits, so a strict client cannot classify the
field and stalls.

The fix changes both builders to emit spec-compliant `type` + `enum` +
`enumNames`. It shipped on the `mcp_elicitations` branch of
`github.com/datashaman/mcp` (commit `4f64c57`). After `composer update
laravel/mcp`, `probe-11` renders correctly.

## Notes

HTTP elicitation needs concurrent request handling. Avoid single-worker `php artisan serve` for this path; use Valet or start `artisan serve` with multiple workers and `--no-reload`.
