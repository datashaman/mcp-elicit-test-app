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
            'requesterName' => $schema->string('Requester name')->required(),
            'contactEmail' => $schema->string('Contact email')->required(),
            'accountId' => $schema->string('Account ID')->required(),
            'summary' => $schema->string('Request summary')->required(),
        ]);

        return Response::text(sprintf(
            'Created support request for %s (%s) on account %s: %s',
            $result->get('requesterName', 'unknown requester'),
            $result->get('contactEmail', 'unknown email'),
            $result->get('accountId', 'unknown account'),
            $result->get('summary', 'no summary provided'),
        ));
    }
}
