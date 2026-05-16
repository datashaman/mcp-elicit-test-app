<?php

declare(strict_types=1);

namespace App\Mcp;

use Laravel\Mcp\Server\Elicitation\ElicitSchema;

class Probe02DescriptionTool extends SchemaProbeTool
{
    protected string $name = 'probe-02-description';

    protected function fields(ElicitSchema $schema): array
    {
        return [
            'name' => $schema->string('Name')
                ->description('Person to contact about this support request.')
                ->required(),
            'summary' => $schema->string('Summary')->required(),
        ];
    }
}
