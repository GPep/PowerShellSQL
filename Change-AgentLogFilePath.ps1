function change-AgentlogFilePath 

{
[CmdletBinding()]
	param
	(
    [Parameter(Mandatory)]
	[ValidateNotNullOrEmpty()]
	[string]$ComputerName = $env:COMPUTERNAME,
    [Parameter(Mandatory=$false)]
	[ValidateNotNullOrEmpty()]
	[string]$Source = '\\bhf-storage02\ServerTeam\ISOs Installs and Service Packs\SQL\Automation\2014'
	)
	process
	{
		try
		{
		$SQLSource = $Source + "\SQL"
        $Sql = Get-ChildItem $SQLSource | Where-Object {$_.Name -eq "ChangeAgentLogPath.sql"}  | sort-object -desc  


        
        Write-Host "Running Script : " $sql.Name -BackgroundColor DarkGreen -ForegroundColor White
        $script = $sql.FullName
        Invoke-Sqlcmd -ServerInstance $ComputerName -InputFile $script
        write-host "Agent Logfile path changed" -BackgroundColor DarkGreen -ForegroundColor Yellow
        
        [void][Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SMO")
        [void][Reflection.assembly]::LoadWithPartialName("Microsoft.SqlServer.SqlWmiManagement")



        $smowmi = New-Object Microsoft.SqlServer.Management.Smo.Server $sqlserver

        $computer = New-Object Microsoft.SqlServer.Management.Smo.Wmi.ManagedComputer $smowmi.ComputerNamePhysicalNetBIOS


        $sqlsvc = $computer.Services | Where-Object {$_.Name -like 'MSSQL*'}
        $sqlagt = $Computer.Services | Where-Object {$_.Name -like 'SQLAGENT*'}
    
        $sqlsvc.Stop()
        start-sleep -s 15
        $sqlsvc.Start()
        $sqlagt.start()
		}
		catch
		{
            $ErrorMessage = $_.Exception.Message
            Write-Error -Message $ErrorMessage
		}
	}
}