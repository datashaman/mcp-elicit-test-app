<?php

declare(strict_types=1);

namespace App\Mcp;

use Laravel\Mcp\Request;
use Laravel\Mcp\Response;
use Laravel\Mcp\Server\Elicitation\Elicitation;
use Laravel\Mcp\Server\Elicitation\ElicitSchema;
use Laravel\Mcp\Server\Tool;

abstract class SchemaProbeTool extends Tool
{
    protected string $description = 'Probe a single MCP elicitation schema feature.';

    public function handle(Request $request, Elicitation $elicitation): Response
    {
        $result = $elicitation->form("Schema probe: {$this->name}", fn (ElicitSchema $schema): array => $this->fields($schema));

        return Response::text(sprintf(
            '%s action=%s content=%s',
            $this->name,
            $result->action(),
            json_encode($result->all(), JSON_THROW_ON_ERROR),
        ));
    }

    /**
     * @return array<string, mixed>
     */
    abstract protected function fields(ElicitSchema $schema): array;
}
