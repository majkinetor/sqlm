class sqlcmd_exe {
    [string] $Server    = 'localhost'
    [int]    $Port      = 1433
    [string] $Username
    [string] $Password
    [string] $Database
    [int]    $Timeout
    [bool]   $Trusted   = $false

    hidden [string] $tmpdir  = "$Env:TEMP/sqlflow/sqlcmd_exe"
    hidden [string] $exeName = 'sqlcmd'

    sqlcmd_exe( [HashTable] $Connection ) {
        if (!(gcm $this.exeName -ea 0)) { throw "$($this.exeName) not found on the PATH" }

        if (!$Connection.Database) { 'throw Database must be specified' }
        $sql_auth = !([string]::IsNullOrWhiteSpace($Connection.Username) -or [string]::IsNullOrWhiteSpace($Connection.Password))
        if ( !$sql_auth -and !$Connection.Trusted) { throw 'Either username/password or trusted connection must be set'}
        if ($Connection.Timeout -and $Connection.Timeout -isnot [int]) { throw 'Timeout must be integer between 0 and 65534' }
              
        if (![string]::IsNullOrWhiteSpace($Connection.Server)) { $this.Server = $Connection.Server.Trim() }
        if (![string]::IsNullOrWhiteSpace($Connection.Port))   { $this.Port = $Connection.Port }
        $this.Username = ($Connection.Username -as [string]).Trim()
        $this.Password = $Connection.Password
        $this.Database = ($Connection.Database -as [string]).Trim()
        $this.Timeout  = $Connection.Timeout
        if ($Connection.Trusted -is [bool]) { $this.Trusted = $Connection.Trusted } else {
            if (!$sql_auth) { $this.Trusted = $true }
        }
        
        Write-Verbose "Using sqlcmd with database $($this.Server):$($this.Port)\$($this.Database)"
        Write-Verbose $( if ($this.Trusted) { "Trusted connection" } else { "User: " + $this.Username } )

        mkdir -Force $this.tmpdir -ea 0 | Out-Null
    }

    # Run sql file on the connection
    # Return any output and errors in a array (out,err)
    [array] RunFile( [string] $SqlFilePath ) {

        $outFile = Join-Path $this.tmpdir "runfile.txt"
        $cmd = "{0} -S '{1},{2}' -d '{3}' -i '{4}' -o '{5}' -y0" -f  $this.exeName, $this.Server, $this.Port, $this.Database, $SqlFilePath, $outFile

        if ($this.Trusted) { $cmd += ' -E' } else { $cmd += " -U '{0}' -P '{1}'" -f $this.Username, $this.Password }
        if ($this.Timeout) { $cmd += "-t " + $this.Timeout }

        Write-Verbose "RunFile: $cmd"
        iex $cmd
        $out    = gc $outFile
        $errors = $out | sls 'msg .+, level .+, line' -Context 0,1
        return $out, $errors
    }

    # Runs migration history table sql on the connection. Used to insert/update history table.
    # Rows are separated by new lines and columns by spaces. There are no spaces in values.
    # No header should be present.
    # Throws on any error.
    [string] RunSql ( [string] $Sql ) {
        $Sql = "set nocount on;`n$Sql"
        $sqlFile = Join-Path $this.tmpdir "runsql.sql"
        [IO.File]::WriteAllLines($sqlFile, $Sql) # we don't want BOM
        $out, $err = $this.RunFile( $sqlFile )
        if ($err) { throw "Migration history error: $err" }
        return $out
    }
}