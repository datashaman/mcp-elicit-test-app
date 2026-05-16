<?php

declare(strict_types=1);

namespace App\Mcp;

use Laravel\Mcp\Server\Elicitation\ElicitSchema;

class Probe03MinLengthTool extends SchemaProbeTool
{
    protected string $name = 'probe-03-min-length';

    protected function fields(ElicitSchema $schema): array
    {
        return [
            'name' => $schema->string('Name')
                ->minLength(2)
                ->required(),
            'summary' => $schema->string('Summary')->required(),
        ];
    }
}
