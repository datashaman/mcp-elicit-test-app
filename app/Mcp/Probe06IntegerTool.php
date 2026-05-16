<?php

declare(strict_types=1);

namespace App\Mcp;

use Laravel\Mcp\Server\Elicitation\ElicitSchema;

class Probe06IntegerTool extends SchemaProbeTool
{
    protected string $name = 'probe-06-integer';

    protected function fields(ElicitSchema $schema): array
    {
        return [
            'severity' => $schema->integer('Severity')->required(),
            'summary' => $schema->string('Summary')->required(),
        ];
    }
}
