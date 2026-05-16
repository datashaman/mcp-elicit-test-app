<?php

declare(strict_types=1);

namespace App\Mcp;

use Laravel\Mcp\Server\Elicitation\ElicitSchema;

class Probe09BooleanTool extends SchemaProbeTool
{
    protected string $name = 'probe-09-boolean';

    protected function fields(ElicitSchema $schema): array
    {
        return [
            'canContact' => $schema->boolean('Can contact')->required(),
            'summary' => $schema->string('Summary')->required(),
        ];
    }
}
