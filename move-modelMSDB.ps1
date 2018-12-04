<#These functions move the MSDB and MODEL Databases and log files to a new location

It will first change the location in the database with the 'Change-ModelMSDB' function. The next function stops the services, moves the files
and starts the services again.

This can be run locally or remotely depending on whether you use the -computerName parameter. It will default to the local address.

Example: Move Model and MSDB databases and logFiles from bad C drive locations to New locations (best practice dictates a separate 
drive to the OS but you knew that). This example is being run locally (so not using the -ComputerName parameter)
:

1) Run change-modelMSDB change the location in SQL Server
change-modelMSDB -OldData 'C:\Wrong Place' -NewData 'E:\MSSQL\Data' -oldLog 'C:\WrongPlace' -NewLog 'L:\MSSQL\LOGS'


2) Run move-modelMSDB to stop SQL Services and physically move the files.
move-msdb -OldData 'C:\Wrong Place' -NewData 'E:\MSSQL\Data' -oldLog 'C:\WrongPlace' -NewLog 'L:\MSSQL\LOGS'

It would be quite simple to write another function to run both but i've left this in a more granular form. 

***PLEASE DOUBLE CHECK THE LOCATIONS BEFORE STARTING. SQL SERVER WILL NOT START PROPERLY IF IT CANNOT FIND THESE FILES AFTER THEY HAVE BEEN MOVED!***

#>





Function change-modelMSDB
{



[CmdletBinding()]

param
	(   
    [Parameter(Mandatory)]
	[ValidateNotNullOrEmpty()]
	[string]$ComputerName = $env:COMPUTERNAME,
    [Parameter(Mandatory)]
	[ValidateNotNullOrEmpty()]
	[string]$OldData,
    [Parameter(Mandatory)]
	[ValidateNotNullOrEmpty()]
	[string]$NewData,
    [Parameter(Mandatory)]
	[ValidateNotNullOrEmpty()]
	[string]$OldLog,
    [Parameter(Mandatory)]
	[ValidateNotNullOrEmpty()]
	[string]$NewLog 
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

    Try
        {

        Invoke-SQLCMD -Query “USE [master]” -ServerInstance $computerName
        Invoke-SQLCMD -Query “ALTER DATABASE model MODIFY FILE (NAME = 'modeldev', FILENAME ='$newdata\model.mdf')” -ServerInstance $computerName
        Invoke-SQLCMD -Query “ALTER DATABASE model MODIFY FILE (NAME = 'modellog', FILENAME ='$newlog\modellog.ldf')” -ServerInstance $computerName
        Invoke-SQLCMD -Query “ALTER DATABASE msdb MODIFY FILE (NAME = 'MSDBData', FILENAME ='$newdata\MSDBData.mdf')” -ServerInstance $computerName
        Invoke-SQLCMD -Query “ALTER DATABASE msdb MODIFY FILE (NAME = 'MSDBLog', FILENAME ='$newlog\MSDBLog.ldf')”-ServerInstance $computerName

        }

     Catch
        {
         $ErrorMessage = $_.Exception.Message
         Write-Error -Message $ErrorMessage

        }
    }

}
            



Function move-ModelMSDB
{
[CmdletBinding()]

param
	(   
    [Parameter(Mandatory)]
	[ValidateNotNullOrEmpty()]
	[string]$ComputerName = $env:COMPUTERNAME,
    [Parameter(Mandatory)]
	[ValidateNotNullOrEmpty()]
	[string]$OldData,
    [Parameter(Mandatory)]
	[ValidateNotNullOrEmpty()]
	[string]$NewData,
    [Parameter(Mandatory)]
	[ValidateNotNullOrEmpty()]
	[string]$OldLog,
    [Parameter(Mandatory)]
	[ValidateNotNullOrEmpty()]
	[string]$NewLog 
    )


 process
	{

    Try
        {



    #Get the Service

    [void][Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SMO")
    [void][Reflection.assembly]::LoadWithPartialName("Microsoft.SqlServer.SqlWmiManagement")



    $smowmi = New-Object Microsoft.SqlServer.Management.Smo.Server $sqlserver

    $computer = New-Object Microsoft.SqlServer.Management.Smo.Wmi.ManagedComputer $smowmi.ComputerNamePhysicalNetBIOS


    $sqlsvc = $computer.Services | Where-Object {$_.Name -like 'MSSQL*'}
    $sqlagt = $Computer.Services | Where-Object {$_.Name -like 'SQLAGENT*'}
    

    #Stop SQL Service, move files, start SQL
    $sqlsvc.Stop()
    Start-Sleep -s 15 #make sure services have completely stopped before moving files.

    
    Move-Item "$olddata\msdbData.mdf" "$newdata\msdbData.mdf"
    Move-Item "$oldlog\msdblog.ldf" "$newlog\msdblog.ldf"
    Move-Item "$oldData\model.mdf" "$newdata\model.mdf"
    Move-Item "$oldlog\modellog.ldf" "$newlog\modellog.ldf"
    

    <#
    $ServerName = $ComputerName.Split('\')[0]

    Invoke-Command -ComputerName $ServerName -ScriptBlock{Move-Item "$using:olddata\msdbData.mdf" "$using:newdata\msdbData.mdf"}
    Invoke-Command -ComputerName $ServerName -ScriptBlock{Move-Item "$using:oldlog\msdblog.ldf" "$using:newlog\msdblog.ldf"}
    Invoke-Command -ComputerName $ServerName -ScriptBlock{Move-Item "$using:oldData\model.mdf" "$using:newdata\model.mdf"}
    Invoke-Command -ComputerName $ServerName -ScriptBlock{Move-Item "$using:oldlog\modellog.ldf" "$using:newlog\modellog.ldf"}
    #>

    $sqlsvc.Start()
    $sqlagt.start()

        }
     Catch
        {
         $ErrorMessage = $_.Exception.Message
         Write-Error -Message $ErrorMessage

        }
    }

}