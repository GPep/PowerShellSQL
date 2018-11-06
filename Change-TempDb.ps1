function change-tempDB
<#This function will move resize the tempdb Databaseand logfile.

If you have more/less tempdb files you will need to add/remove extra invoke-sqlcmd commands. This version uses 4 files as default.
Best practice is to have the same number of tempdb files as CPUs as a start. The files should all be sized the same, with the same filegrowth, have
it's own dedicated drive and they should be sized to fill the drive so you don't get any performance hits when the data files have to increase the size. 
I normally leave around 12% free so it does have a bit of space to grow if required and I don't set of any alerts that my disk space is below 10%!

example:

change-tempDB -datasize 900000KB -logsize 100000KB -FileGrowth 200MB

This will resize each data file to 9GB, log file to 1GB and make filegrowth 200MB across all.



#>

{
[CmdletBinding()]

param
	(   
    [Parameter(Mandatory)]
	[ValidateNotNullOrEmpty()]
	[string]$ComputerName = $env:COMPUTERNAME,
    [Parameter(Mandatory)]
	[ValidateNotNullOrEmpty()]
	[string]$datasize,
    [Parameter(Mandatory)]
	[ValidateNotNullOrEmpty()]
	[string]$logsize,
    [Parameter(Mandatory)]
	[ValidateNotNullOrEmpty()]
	[string]$filegrowth
    )


 process
	{

    Try
        {

    $smowmi = New-Object Microsoft.SqlServer.Management.Smo.Wmi.ManagedComputer $ComputerName
    
    $sqlsvc = $smowmi.Services | Where-Object {$_.Name -like 'MSSQL*'}
    $sqlagt = $smowmi.Services['SQLSERVERAGENT']

        Invoke-SQLCMD -Query “USE [master]”
        Invoke-SQLCMD -Query “ALTER DATABASE tempdb MODIFY FILE ( NAME = N'tempdev', SIZE = $datasize, FILEGROWTH = $FileGrowth)"
        Invoke-SQLCMD -Query “ALTER DATABASE tempdb MODIFY FILE ( NAME = N'temp2', SIZE = $datasize, FILEGROWTH = $FileGrowth)"
        Invoke-SQLCMD -Query “ALTER DATABASE tempdb MODIFY FILE ( NAME = N'temp3', SIZE = $datasize, FILEGROWTH = $FileGrowth)"
        Invoke-SQLCMD -Query “ALTER DATABASE tempdb MODIFY FILE ( NAME = N'temp4',SIZE = $datasize, FILEGROWTH = $FileGrowth)"
        Invoke-SQLCMD -Query “ALTER DATABASE [tempdb] MODIFY FILE ( NAME = N'templog', SIZE = $logSize)"
        $sqlsvc.Stop()
        $sqlagt.Stop()
        Start-Sleep -s 15
        $sqlsvc.Start()
        $sqlagt.Start()

 }
     Catch
        {
         $ErrorMessage = $_.Exception.Message
         Write-Error -Message $ErrorMessage

        }
    }

}