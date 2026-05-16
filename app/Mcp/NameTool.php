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
    protected string $name = 'triage-support-request';

    protected string $description = 'Collect details for a realistic support request triage.';

    public function handle(Request $request, Elicitation $elicitation): Response
    {
        $result = $elicitation->form('Please provide the support request details.', fn (ElicitSchema $schema): array => [
            'name' => $schema->string('Requester name')
                ->description('The person we should contact about this request.')
                ->minLength(2)
                ->required(),
            'email' => $schema->string('Contact email')
                ->description('Used for follow-up and status updates.')
                ->format('email')
                ->required(),
            'plan' => $schema->enum('Plan', ['free', 'team', 'enterprise'])
                ->default('team')
                ->required(),
            'severity' => $schema->integer('Severity')
                ->description('1 is low impact; 5 is production blocked.')
                ->min(1)
                ->max(5)
                ->default(3)
                ->required(),
            'affectedArea' => $schema->enum('Affected area', ['api', 'billing', 'auth', 'dashboard'])
                ->default('api')
                ->required(),
            'monthlySpend' => $schema->number('Approximate monthly spend')
                ->description('A rough amount in USD.')
                ->min(0)
                ->default(99.0),
            'canContact' => $schema->boolean('May we contact you?')
                ->default(true),
        ]);

        return Response::text(sprintf(
            'Created %s support request for %s (%s) affecting %s.',
            $result->get('plan'),
            $result->get('name'),
            $result->get('email'),
            $result->get('affectedArea'),
        ));
    }
}
