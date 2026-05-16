<?php

declare(strict_types=1);

namespace App\Mcp;

use Laravel\Mcp\Server\Elicitation\ElicitSchema;

class Probe10DefaultsTool extends SchemaProbeTool
{
    protected string $name = 'probe-10-defaults';

    protected function fields(ElicitSchema $schema): array
    {
        return [
            'name' => $schema->string('Name')->default('Codex')->required(),
            'plan' => $schema->enum('Plan', ['free', 'team', 'enterprise'])->default('team')->required(),
            'canContact' => $schema->boolean('Can contact')->default(true),
        ];
    }
}
