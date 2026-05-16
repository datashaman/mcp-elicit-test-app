<?php

declare(strict_types=1);

namespace App\Mcp;

use Laravel\Mcp\Server\Elicitation\ElicitSchema;

class Probe08NumberTool extends SchemaProbeTool
{
    protected string $name = 'probe-08-number';

    protected function fields(ElicitSchema $schema): array
    {
        return [
            'monthlySpend' => $schema->number('Monthly spend')->required(),
            'summary' => $schema->string('Summary')->required(),
        ];
    }
}
