<?php

declare(strict_types=1);

namespace App\Mcp;

use Laravel\Mcp\Server\Elicitation\ElicitSchema;

class Probe05EnumTool extends SchemaProbeTool
{
    protected string $name = 'probe-05-enum';

    protected function fields(ElicitSchema $schema): array
    {
        return [
            'plan' => $schema->enum('Plan', ['free', 'team', 'enterprise'])->required(),
            'summary' => $schema->string('Summary')->required(),
        ];
    }
}
