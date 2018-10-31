Function Test-SQLInstance 
{
<#
	.SYNOPSIS
    This functions tests your SQL Connections and confirms the last Service Restart. It can query multiple servers at once.
		

    .EXAMPLE
    Test-SQLInstance -ComputerNmae Server1, Server2, Server3


    .PARAMETERS
    -ComputerName 
    Enter the Server/Computer names. Separate multiple names with commas.



#>
[CmdletBinding()]
	param
	(
		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[string[]]$ComputerName
    )
    $return = @()
    $SQL = "SELECT @@SERVERNAME as name, Create_Date FROM sys.databases WHERE name = 'TempDB'"
    foreach ($computer in $ComputerName)
    {
    try
    {
    $row = NeW-Object -TypeName PsObject -Property @{'InstanceName'=$computer; "StartUpTime"=$null}
    $Check = Invoke-Sqlcmd -ServerInstance $computer -Database TempDB -Query $SQL -ErrorAction stop -ConnectionTimeout 200
    $row.InstanceName = $Check.Name 
    $row.StartupTime = $check.Create_Date
    
    }

    catch 
    { 
    Write-Error -Message $_.Exception.Message
    }
    Finally
    {

    $return += $row 
    $return | format-table
    }
}



}