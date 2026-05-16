<?php

declare(strict_types=1);

namespace App\Mcp;

use Laravel\Mcp\Request;
use Laravel\Mcp\Response;
use Laravel\Mcp\Server\Elicitation\Elicitation;
use Laravel\Mcp\Server\Elicitation\ElicitSchema;
use Laravel\Mcp\Server\Tool;

class NameTool extends Tool
{
    protected string $name = 'ask-name';

    protected string $description = 'Ask the user for their name and greet them.';

    public function handle(Request $request, Elicitation $elicitation): Response
    {
        $result = $elicitation->form('What is your name?', fn (ElicitSchema $schema): array => [
            'name' => $schema->string('Your Name')->required(),
        ]);

        return Response::text('Hello, '.$result->get('name').'!');
    }
}
