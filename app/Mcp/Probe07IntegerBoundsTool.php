<?php

declare(strict_types=1);

namespace App\Mcp;

use Laravel\Mcp\Server\Elicitation\ElicitSchema;

class Probe07IntegerBoundsTool extends SchemaProbeTool
{
    protected string $name = 'probe-07-integer-bounds';

    protected function fields(ElicitSchema $schema): array
    {
        return [
            'severity' => $schema->integer('Severity')
                ->min(1)
                ->max(5)
                ->required(),
            'summary' => $schema->string('Summary')->required(),
        ];
    }
}
