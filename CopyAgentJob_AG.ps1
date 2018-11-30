$DBServer = $env:computername
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
$SqlCmd.CommandText = $SqlQuery
$SqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter
$SqlAdapter.SelectCommand = $SqlCmd
$SqlCmd.Connection = $Connection
$DataSet = New-Object System.Data.DataSet
$SqlAdapter.Fill($DataSet)


$SqlCmd.CommandText = $SqlQuery2
$SqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter
$SqlAdapter.SelectCommand = $SqlCmd
$SqlCmd.Connection = $Connection
$Jobs = New-Object System.Data.DataSet
$SqlAdapter.Fill($Jobs)
$Connection.Close()

foreach ($Job in $Jobs.Tables[0].Rows)
{ 
$AgentJob = $($Job[0])
foreach ($Row in $DataSet.Tables[0].Rows)
{ 
  $DestServer = $($Row[0])
  Copy-DBAAgentJob -Source $DBServer -Destination $DestServer -Job $AgentJob -Force
}

}

