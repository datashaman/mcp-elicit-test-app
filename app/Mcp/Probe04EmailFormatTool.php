<?php

declare(strict_types=1);

namespace App\Mcp;

use Laravel\Mcp\Server\Elicitation\ElicitSchema;

class Probe04EmailFormatTool extends SchemaProbeTool
{
    protected string $name = 'probe-04-email-format';

    protected function fields(ElicitSchema $schema): array
    {
        return [
            'email' => $schema->string('Email')
                ->format('email')
                ->required(),
            'summary' => $schema->string('Summary')->required(),
        ];
    }
}
