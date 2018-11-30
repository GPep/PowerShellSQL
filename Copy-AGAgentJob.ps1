Function Copy-AGAgentJob 
{
    
    Process

    {


    $DBServer = $env:computername
    #$DBServer = 'DV-SQLCLN-02'
    $databasename = "master"
    $Connection = new-object system.data.sqlclient.sqlconnection #Set new object to connect to sql database
    $Connection.ConnectionString ="server=$DBServer;database=$databasename;trusted_connection=True" # Connectiongstring setting for local machine database with window authentication
    Write-host "Connection Information:"  -foregroundcolor yellow -backgroundcolor black
    $Connection #List connection information

    ### Connect to Database and Run Query

    $SqlCmd = New-Object System.Data.SqlClient.SqlCommand #setting object to use sql commands

    $SqlQuery = "
    SELECT Replica_server_name FROM sys.availability_replicas WHERE Replica_Server_name NOT IN (select primary_replica FROM sys.dm_hadr_name_id_map nim inner join sys.dm_hadr_availability_group_states ags on nim.ag_id = ags.group_id)
    "
    $SQLQuery2 ="
    SELECT name FROM tools.dbo.AgentJobsToCopy
    "

    $Connection.open()

    Write-host "Connection to database successful." -foregroundcolor green -backgroundcolor black
    
    try{
    
    $SqlCmd.CommandText = $SqlQuery
    $SqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter
    $SqlAdapter.SelectCommand = $SqlCmd
    $SqlCmd.Connection = $Connection
    $DataSet = New-Object System.Data.Datatable
    $SqlAdapter.Fill($DataSet)
    $serverArray = @($DataSet)

    $SqlCmd.CommandText = $SqlQuery2
    $SqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter
    $SqlAdapter.SelectCommand = $SqlCmd
    $SqlCmd.Connection = $Connection
    $Jobs = New-Object System.Data.Datatable
    $SqlAdapter.Fill($Jobs)
    $JobArray = @($jobs)
    $Connection.Close()


    foreach ($Job in $Jobarray.name)
    { 
    $AgentJob = $Job
    
    foreach ($Row in $ServerArray.replica_server_name)
    { 
    $DestServer = $Row
    Copy-DBAAgentJob -Source $DBServer -Destination $DestServer -Job $AgentJob -Force
    }
    }

    }
    catch
    {
    $ErrorMessage = $_.Exception.Message
    Write-Error -Message $ErrorMessage
    }

    }

    
}

Copy-AGAgentJob