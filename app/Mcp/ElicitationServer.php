<?php

declare(strict_types=1);

namespace App\Mcp;

use Laravel\Mcp\Server;

class ElicitationServer extends Server
{
    protected array $tools = [
        NameTool::class,
        Probe01TextOnlyTool::class,
        Probe02DescriptionTool::class,
        Probe03MinLengthTool::class,
        Probe04EmailFormatTool::class,
        Probe05EnumTool::class,
        Probe06IntegerTool::class,
        Probe07IntegerBoundsTool::class,
        Probe08NumberTool::class,
        Probe09BooleanTool::class,
        Probe10DefaultsTool::class,
        Probe11TitledEnumTool::class,
        Probe12MultiEnumTool::class,
    ];
}
