<?php

declare(strict_types=1);

namespace App\Mcp;

use Laravel\Mcp\Server\Elicitation\ElicitSchema;

class Probe01TextOnlyTool extends SchemaProbeTool
{
    protected string $name = 'probe-01-text-only';

    protected function fields(ElicitSchema $schema): array
    {
        return [
            'name' => $schema->string('Name')->required(),
            'summary' => $schema->string('Summary')->required(),
        ];
    }
}
