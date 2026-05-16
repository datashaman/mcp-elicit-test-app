<?php

declare(strict_types=1);

namespace App\Mcp;

use Laravel\Mcp\Server;

class ElicitationServer extends Server
{
    protected array $tools = [
        NameTool::class,
    ];
}
