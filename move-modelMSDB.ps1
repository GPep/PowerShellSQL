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

    Try
        {

        Invoke-SQLCMD -Query “USE [master]”
        Invoke-SQLCMD -Query “ALTER DATABASE model MODIFY FILE (NAME = 'modeldev', FILENAME ='$newdata\model.mdf')”
        Invoke-SQLCMD -Query “ALTER DATABASE model MODIFY FILE (NAME = 'modellog', FILENAME ='$newlog\modellog.ldf')”
        Invoke-SQLCMD -Query “ALTER DATABASE msdb MODIFY FILE (NAME = 'MSDBData', FILENAME ='$newdata\MSDBData.mdf')”
        Invoke-SQLCMD -Query “ALTER DATABASE msdb MODIFY FILE (NAME = 'MSDBLog', FILENAME ='$newlog\MSDBLog.ldf')”

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

    $smowmi = New-Object Microsoft.SqlServer.Management.Smo.Wmi.ManagedComputer $ComputerName
    
    $sqlsvc = $smowmi.Services | Where-Object {$_.Name -like 'MSSQL*'}
    $sqlagt = $smowmi.Services['SQLSERVERAGENT']

    #Stop SQL Service, move files, start SQL
    $sqlsvc.Stop()
    Start-Sleep -s 15 #make sure services have completely stopped before moving files.

    <#
    Move-Item "$olddata\msdbData.mdf" "$newdata\msdbData.mdf"
    Move-Item "$oldlog\msdblog.ldf" "$newlog\msdblog.ldf"
    Move-Item "$oldData\model.mdf" "$newdata\model.mdf"
    Move-Item "$oldlog\modellog.ldf" "$newlog\modellog.ldf"
    #>

    Invoke-Command -ComputerName $ComputerName -ScriptBlock{Move-Item "$using:olddata\msdbData.mdf" "$using:newdata\msdbData.mdf"}
    Invoke-Command -ComputerName $ComputerName -ScriptBlock{Move-Item "$using:oldlog\msdblog.ldf" "$using:newlog\msdblog.ldf"}
    Invoke-Command -ComputerName $ComputerName -ScriptBlock{Move-Item "$using:oldData\model.mdf" "$using:newdata\model.mdf"}
    Invoke-Command -ComputerName $ComputerName -ScriptBlock{Move-Item "$using:oldlog\modellog.ldf" "$using:newlog\modellog.ldf"}


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