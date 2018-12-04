Function change-masterConfig
{

<#These functions move the Master Database, log file and error log to a new location

It will first change the startup parameters (change-MasterConfig), then stop services, move the master data and log files to their 
new location and then start services again (move-master).

This can be run locally or remotely. It will default to the local address.

Example: Move master database, logFile and Error Log from bad C drive locations to New locations (best practice dictates a separate 
drive to the OS but you knew that).
:

Change-masterConfig -OldData 'C:\Wrong Place\Master.mdf' -NewData 'E:\MSSQL\Data\master.mdf' -oldLog 'C:\WrongPlace\mastlog.ldf'
-NewLog 'L:\MSSQL\LOGS\mastlog.ldf -oldError 'C:\Wrong place\log\ERRORLOG' -NewError 'E:\MSSQL\Log\ERRORLOG'

After this completes you can then run the following to move the files physically

Move-Master -OldData 'C:\Wrong Place\Master.mdf' -NewData 'E:\MSSQL\Data\master.mdf' -oldLog 'C:\WrongPlace\mastlog.ldf'
-NewLog 'L:\MSSQL\LOGS\mastlog.ldf -oldError 'C:\Wrong place\log\ERRORLOG'

It would be quite simple to write another function to run both but i've left this in a more granular form. 

***PLEASE DOUBLE CHECK THE LOCATIONS BEFORE STARTING. SQL SERVER WILL NOT START PROPERLY IF IT CANNOT FIND THESE FILES AFTER THEY HAVE BEEN MOVED!***


#>



[CmdletBinding()]

param
	(
    [Parameter(Mandatory=$false)]
	[ValidateNotNullOrEmpty()]
	[string]$ComputerName=$env:COMPUTERNAME, 
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
	[string]$NewLog,
    [Parameter(Mandatory)]
	[ValidateNotNullOrEmpty()]
	[string]$OldError,
    [Parameter(Mandatory)]
	[ValidateNotNullOrEmpty()]
	[string]$NewError
    )


 process
	{

    Try
        {


        #Set the params as a string array

        $params = @("-d$NewData","-e$NewError","-l$NewLog")

        $SQLServer = "$ComputerName"

        #Get the Service

        [void][Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SMO")
        [void][Reflection.assembly]::LoadWithPartialName("Microsoft.SqlServer.SqlWmiManagement")
        $smowmi = New-Object Microsoft.SqlServer.Management.Smo.Server $sqlserver


        $computer = New-Object Microsoft.SqlServer.Management.Smo.Wmi.ManagedComputer $smowmi.ComputerNamePhysicalNetBIOS



        $sqlsvc = $computer.Services | Where-Object {$_.Name -like 'MSSQL$*'}



        #Change the startup parameters
        $sqlsvc.StartupParameters = $params -join ';'
        $sqlsvc.Alter()

        }

    Catch
        {
         $ErrorMessage = $_.Exception.Message
         Write-Error -Message $ErrorMessage

        }
    }

}

Function move-Master
{
[CmdletBinding()]

param
	(   
    [Parameter(Mandatory=$false)]
	[ValidateNotNullOrEmpty()]
	[string]$ComputerName=$env:COMPUTERNAME,
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


        $SQLServer = "$ComputerName"

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
        Move-Item $OldData $NewData
        Move-Item $OldLog $NewLog
        #Invoke-Command -ComputerName $ComputerName -ScriptBlock{Move-Item "$using:OldData" "$using:NewData"}
        #Invoke-Command -ComputerName $ComputerName -ScriptBlock{Move-Item "$using:OldLog" "$using:NewLog"}
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

     



