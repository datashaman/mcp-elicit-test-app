import { spawnSync } from 'node:child_process';

const tools = [
  'triage-support-request',
  'probe-01-text-only',
  'probe-02-description',
  'probe-03-min-length',
  'probe-04-email-format',
  'probe-05-enum',
  'probe-06-integer',
  'probe-07-integer-bounds',
  'probe-08-number',
  'probe-09-boolean',
  'probe-10-defaults',
  'probe-11-titled-enum',
  'probe-12-multi-enum',
];

for (const tool of tools) {
  const result = spawnSync(process.execPath, ['scripts/mcp-elicit-smoke.mjs'], {
    stdio: 'inherit',
    env: {
      ...process.env,
      MCP_TOOL_NAME: tool,
    },
  });

  if (result.status !== 0) {
    process.exit(result.status ?? 1);
  }
}
