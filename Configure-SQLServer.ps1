function Configure-SQLServer
{
	[CmdletBinding()]
	param
	(
    [Parameter(Mandatory=$false)]
	[ValidateNotNullOrEmpty()]
	[string]$ComputerName=$env:COMPUTERNAME,
    [Parameter(Mandatory=$false)]
	[ValidateNotNullOrEmpty()]
	[string]$Source='\\bhf-storage02\ServerTeam\ISOs Installs and Service Packs\SQL\Automation\2014'
	)
	process
	{

        IF (!(Get-Module -Name sqlps))
    {
        Write-Host 'Loading SQLPS Module' -ForegroundColor DarkYellow
        Push-Location
        Import-Module sqlps -DisableNameChecking
        Pop-Location
    }
		try
		{
		$SQLSource = $Source + "\SQL"
        $Sql = Get-ChildItem $SQLSource | Where-Object {$_.Name -eq "SQL Server Deployment Configurations.sql"}  | sort-object -desc  
      
        Write-Host "Running Script : " $sql.Name -BackgroundColor DarkGreen -ForegroundColor White
        $script = $sql.FullName
        Invoke-Sqlcmd -ServerInstance $ComputerName -InputFile $script
        write-host "Post Configuration Changes Made" -BackgroundColor DarkGreen -ForegroundColor Yellow
		}
		catch
		{
            $ErrorMessage = $_.Exception.Message
            Write-Error -Message $ErrorMessage
		}
	}
}