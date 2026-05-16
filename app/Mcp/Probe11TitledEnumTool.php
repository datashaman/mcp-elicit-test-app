<?php

declare(strict_types=1);

namespace App\Mcp;

use Laravel\Mcp\Server\Elicitation\ElicitSchema;

class Probe11TitledEnumTool extends SchemaProbeTool
{
    protected string $name = 'probe-11-titled-enum';

    protected function fields(ElicitSchema $schema): array
    {
        return [
            'plan' => $schema->enum('Plan', ['free', 'team', 'enterprise'])
                ->titled([
                    'free' => 'Free',
                    'team' => 'Team',
                    'enterprise' => 'Enterprise',
                ])
                ->required(),
            'summary' => $schema->string('Summary')->required(),
        ];
    }
}
