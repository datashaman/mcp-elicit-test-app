<?php

declare(strict_types=1);

use App\Mcp\ElicitationServer;
use Laravel\Mcp\Facades\Mcp;

Mcp::local('elicit', ElicitationServer::class);
Mcp::web('/mcp/elicit', ElicitationServer::class);
