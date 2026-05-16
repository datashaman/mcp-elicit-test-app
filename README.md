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

It exposes a single tool:

```text
ask-name
```

The tool sends a form elicitation asking for `name`, then returns `Hello, <name>!`.

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

Override the URL when needed:

```bash
MCP_TEST_URL=https://some-host.test/mcp/elicit node scripts/mcp-elicit-smoke.mjs
```

## Notes

HTTP elicitation needs concurrent request handling. Avoid single-worker `php artisan serve` for this path; use Valet or start `artisan serve` with multiple workers and `--no-reload`.
