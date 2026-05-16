<?php

declare(strict_types=1);

namespace App\Mcp;

use Laravel\Mcp\Server\Elicitation\ElicitSchema;

class Probe12MultiEnumTool extends SchemaProbeTool
{
    protected string $name = 'probe-12-multi-enum';

    protected function fields(ElicitSchema $schema): array
    {
        return [
            'areas' => $schema->multiEnum('Affected areas', ['api', 'billing', 'auth']),
            'summary' => $schema->string('Summary')->required(),
        ];
    }
}
