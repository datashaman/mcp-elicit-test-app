const baseUrl = process.env.MCP_TEST_URL ?? 'https://mcp-elicit-test-app.test/mcp/elicit';
const protocolVersion = process.env.MCP_PROTOCOL_VERSION ?? '2025-06-18';

const jsonHeaders = {
  'content-type': 'application/json',
};

function message(id, method, params = {}) {
  return {
    jsonrpc: '2.0',
    id,
    method,
    params,
  };
}

async function postJson(body, headers = {}) {
  return fetch(baseUrl, {
    method: 'POST',
    headers: {
      ...jsonHeaders,
      ...headers,
    },
    body: JSON.stringify(body),
  });
}

async function initialize() {
  const response = await postJson(message(1, 'initialize', {
    protocolVersion,
    capabilities: {
      elicitation: protocolVersion === '2025-11-25'
        ? { form: true, url: true }
        : {},
    },
    clientInfo: {
      name: 'laravel-mcp-smoke-test',
      version: '1.0.0',
    },
  }), {
    accept: 'application/json, text/event-stream',
  });

  if (!response.ok) {
    throw new Error(`initialize failed: HTTP ${response.status} ${await response.text()}`);
  }

  const sessionId = response.headers.get('mcp-session-id');
  const body = await response.json();

  if (!sessionId) {
    throw new Error('initialize response did not include MCP-Session-Id');
  }

  await postJson({
    jsonrpc: '2.0',
    method: 'notifications/initialized',
    params: {},
  }, {
    'mcp-session-id': sessionId,
    accept: 'application/json, text/event-stream',
  });

  return { sessionId, body };
}

async function answerElicitation(sessionId, id) {
  const response = await postJson({
    jsonrpc: '2.0',
    id,
    result: {
      action: 'accept',
      content: {
        name: 'Codex',
        email: 'codex@example.com',
        plan: 'enterprise',
        severity: 4,
        affectedArea: 'api',
        monthlySpend: 250.5,
        canContact: true,
      },
    },
  }, {
    'mcp-session-id': sessionId,
  });

  if (response.status !== 202) {
    throw new Error(`elicitation response failed: HTTP ${response.status} ${await response.text()}`);
  }
}

function parseSseBuffer(buffer) {
  const messages = [];
  const events = buffer.split('\n\n');
  const rest = events.pop() ?? '';

  for (const event of events) {
    const data = event
      .split('\n')
      .filter((line) => line.startsWith('data: '))
      .map((line) => line.slice(6))
      .join('\n');

    if (data !== '') {
      messages.push(JSON.parse(data));
    }
  }

  return { messages, rest };
}

async function callTool(sessionId) {
  const response = await fetch(baseUrl, {
    method: 'POST',
    headers: {
      ...jsonHeaders,
      accept: 'text/event-stream',
      'mcp-session-id': sessionId,
    },
    body: JSON.stringify(message(2, 'tools/call', {
      name: 'triage-support-request',
      arguments: {},
    })),
  });

  if (!response.ok) {
    throw new Error(`tools/call failed: HTTP ${response.status} ${await response.text()}`);
  }

  const reader = response.body.getReader();
  const decoder = new TextDecoder();
  let buffer = '';
  const seen = [];

  while (true) {
    const { value, done } = await reader.read();

    if (done) {
      break;
    }

    buffer += decoder.decode(value, { stream: true });
    const parsed = parseSseBuffer(buffer);
    buffer = parsed.rest;

    for (const rpc of parsed.messages) {
      seen.push(rpc);

      if (rpc.method === 'elicitation/create') {
        if (protocolVersion === '2025-06-18' && Object.hasOwn(rpc.params, 'mode')) {
          throw new Error('2025-06-18 elicitation unexpectedly included mode');
        }

        await answerElicitation(sessionId, rpc.id);
      }

      if (rpc.id === 2 && rpc.result) {
        return seen;
      }
    }
  }

  throw new Error(`stream ended before tools/call result; saw ${JSON.stringify(seen)}`);
}

const { sessionId, body } = await initialize();
const messages = await callTool(sessionId);
const final = messages.at(-1);
const text = final?.result?.content?.[0]?.text;

if (text !== 'Created enterprise support request for Codex (codex@example.com) affecting api.') {
  throw new Error(`unexpected final response: ${JSON.stringify(final)}`);
}

console.log(JSON.stringify({
  initialized: body.result.protocolVersion,
  sessionId,
  messages: messages.map((rpc) => ({
    id: rpc.id,
    method: rpc.method ?? null,
    text: rpc.result?.content?.[0]?.text ?? null,
    hasMode: Object.hasOwn(rpc.params ?? {}, 'mode'),
    fieldCount: Object.keys(rpc.params?.requestedSchema?.properties ?? {}).length || null,
  })),
}, null, 2));
