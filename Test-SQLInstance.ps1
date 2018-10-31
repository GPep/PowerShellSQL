Function Test-SQLInstance 
{
<#
	.SYNOPSIS
    This functions tests your SQL Connections and confirms the last Service Restart. It can query multiple servers at once.
		

    .EXAMPLE



    .PARAMETERS




#>
[CmdletBinding()]
	param
	(
		[Parameter]
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
    $Check=Invoke-Sqlcmd -ServerInstance $computer -Database TempDB -Query $SQL -ErrorAction stop -connect
    $row.InstanceName = $Check.Name
    $row.StartupTime = $check.Create_Date
    }

    catch 
    {

    
    
    
    }
    Finally
    {

    $return += $row 
    }
}



}