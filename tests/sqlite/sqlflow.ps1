$config = @{
    Runner         = 'sqlite_shell'
    HistoryTable   = '_sqlflow_table'

    Directories = @(
        'migrations'
    )

    Files = @{
        Include  = '*.sql'
        Exclude  = '~*'
    }

    # Migrations = {
    #      ls -Directory $config.Directories
    # }

    Connections = [ordered]@{
        test = "test.db"
    }
}

import-module -force ..\..\sqlflow.psm1
$VerbosePreference = 'continue'

pushd $PSScriptRoot
rm test.db -ea 0
Invoke-Flow -FlowConfig $config