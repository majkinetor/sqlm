function Get-Migrations() {
}

$config = @{
    Executor      = 'sqlite_shell'
    HistoryTable  = '_sqlflow_history'

    Directories     = @{
        Migrations = 'Patches'
        SqlDirs    = 'ddl', 'dml', 'plsql'
        PlSqlDir   = 'source\TrezorMaster\TrezorPlsq'
        Compile    = 'model\COMPILE'
    }

    Credentials    = @{
        admin = 'sys', 'eclaro'
        user  = 'mof', 'saga'
    }

    ConnectionStrings = @{
           user  = "${Hostname}:$Port/$Sid"
           admin = "${Hostname}:$Port/$Sid as sysdba" 
    }

    IncludeFiles    = '*.sql', '*.pls'
    ExcludeFiles    = '~.sql'
}
