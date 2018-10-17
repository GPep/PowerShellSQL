Function Install-SQLServer
{
<#
This script will install SQL Server - It currently defaults to 2016 Developer Edition but this can be amended.
This should be run locally on the server you are installing to. 


Example:
This command will install SQL Server 2016 Developer Edition to a local computer using the below service accounts.

Install-SQLServer -PackagePath '\\UNCPath\SQLInstalls\2016' -SQLAccount 'SVC_UT-serverName_SQL' -SQLAgent 'SVC_UT-SERVERNAME_AGT'


Parameters:

-ComputerName 
This defaults to the local computer.Even though this script should be run locally, I've put this here for future development.. Maybe.

-PackagePath
Put in the patch to the packages. This would normally be a UNC Path on your network but it can be installed from a local directory on your server.

-PackageName
Here is where you put the name of the package in. 
This script as been tested  with 2012, 2014 and 2016 versions and with Standard, Enterprise and Developer editions.

-InstanceName
This will default to the default instance but you can also install Named Instances.

-SQLAccount
This is mandatory. Please enter the Service Account you wish to use as for SQL Services

-SQLAgent 
This is mandatory. Please enter the Agent Account you wish to use for the SQL Agent

****DON'T FORGET to add your SQL Service, Agent and SA account passwords in the function Start-SQLInstall****



#>

    param (
        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [String]
        $ComputerName = $env:ComputerName,
        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [String]
        $PackagePath="Enter Package Path Here",
        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [String]
        $PackageName="en_sql_server_2016_developer_x64_dvd_8777069.iso",#change your package name here.
        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [String]
        $InstanceName = 'MSSQLSERVER',
        [Parameter(Mandatory=$True)]
        [ValidateNotNullOrEmpty()]
        [String]
        $SQLAccount,
        [Parameter(Mandatory=$True)]
        [ValidateNotNullOrEmpty()]
        [String]
        $SQLAgent
    )


 process
	{
		try
		{
 
        copy-item -Path "$PackagePath\$PackageName" -Destination "c:\temp\SQLServer.iso" -erroraction Stop

        copy-item -Path "$PackagePath\ConfigurationFile.ini" -Destination "C:\temp" -ErrorAction Stop

        ##Add Service Accounts to Configuration File

        $NewConfigFile = FindReplace-String -InputFile "C:\temp\ConfigurationFile.ini" -FindString '$SQLAccount$' -replaceString $SQLAccount
        
        $NewConfigFile | out-file  "C:\temp\ConfigurationFile.ini" -Force

        $NewConfigFile2 = FindReplace-String -InputFile "C:\temp\ConfigurationFile.ini" -FindString '$SQLAGENT$' -replaceString $SQLAgent 
        $NewConfigFile2 |out-file "C:\temp\ConfigurationFile.ini" -Force

        ##Add Instance Name to Configuration File If it is not the Default Instance
        IF ($InstanceName -ne 'MSSQLSERVER')
        {
        $NewConfigFile3 = FindReplace-String -InputFile "C:\temp\ConfigurationFile.ini" -FindString 'MSSQLSERVER' -replaceString $InstanceName
        $NewConfigFile3 |out-file "C:\temp\ConfigurationFile.ini" -Force
        }

        $TestExists = Test-SQLServerExists -InstanceName $InstanceName -ComputerName $ComputerName
        If ($TestExists -eq $true)
        {
        write-host "$instanceName is already in use. please choose a different SQL Instance Name"
        return
        }
        else
        {
        write-host "About to start the install of SQL Server"

        $IsoDrive = Mount-SQLIso

  

        If ($IsoDrive -ne $null)
        {
        #start-SQLInstall -ISODrive
        Write-Host "Ready to start the install from $IsoDrive, Dave"
        sleep -Seconds 5
        }

        }

        
        }

        Catch 

        {
         $ErrorMessage = $_.Exception.Message
         Write-Error -Message $ErrorMessage
        }

        finally
        {
        ##clean up files
        Dismount-DiskImage -ImagePath "c:\temp\SQLServer.iso"
        remove-item -Path "C:\temp\ConfigurationFile.ini"
        remove-item -Path "C:\temp\SQLServer.iso"
        }


     }
       
       
 }


 Function FindReplace-String

 {
  param (
        [Parameter(Mandatory=$True)]
        [ValidateNotNullOrEmpty()]
        [String]
        $InputFile,
        [Parameter(Mandatory=$True)]
        [ValidateNotNullOrEmpty()]
        [String]
        $FindString,
        [Parameter(Mandatory=$True)]
        [ValidateNotNullOrEmpty()]
        [String]
        $replaceString
    )

 process
	{
		try
		{

        (Get-Content $inputFile) | foreach {$_.replace($findString,$replaceString)}

        }

         Catch 

        {
         $ErrorMessage = $_.Exception.Message
         Write-Error -Message $ErrorMessage
        }

     }
       
       
 }


 Function Test-SQLServerExists

 {
  param (
        [Parameter(Mandatory=$True)]
        [ValidateNotNullOrEmpty()]
        [String]
        $InstanceName,
        [Parameter(Mandatory=$True)]
        [ValidateNotNullOrEmpty()]
        [String]
        $ComputerName
    )

 process
	{
        $InstanceExists = $false
		try
		{
            $sqlInstances = gwmi win32_service -computerName $ComputerName | ? { $_.Name -match "$InstanceName *" -and $_.PathName -match "sqlservr.exe" } | % { $_.Caption }
            $res = $sqlInstances -ne $null
            if ($res) {
                  Write-Verbose "SQL Server Instance $InstanceName is already installed"
                  $InstanceExists = $true
                  } else {
                  Write-Verbose "SQL Server Instance $instanceName is not installed"
                  $instanceExists = $false
                  }
        return $InstanceExists
        }
        Catch
        {
         $ErrorMessage = $_.Exception.Message
         Write-Error -Message $ErrorMessage
        }

    }

}

Function Mount-SQLIso

{
  param (

    )

 process
 	{
		try
        {
        $setupDriveLetter = (Mount-DiskImage -ImagePath c:\temp\SQLServer.iso -PassThru | Get-Volume).DriveLetter + ":"
        if ($setupDriveLetter -eq $null) {
                throw "Could not mount SQL install iso"
                }
        Write-Verbose "Drive letter for iso is: $setupDriveLetter"

        }
        Catch
        {
         $ErrorMessage = $_.Exception.Message
         Write-Error -Message $ErrorMessage

        }
        return $setupDriveLetter
    }

}


Function start-SQLInstall

{
  param (
        [Parameter(Mandatory=$True)]
        [ValidateNotNullOrEmpty()]
        [String]
        $ISODrive

    )

 process
 	{
		try
        {

        # run the installer using the ini file
        $cmd = "$IsoDrive\Setup.exe /ConfigurationFile=c:\temp\ConfigurationFile.ini /SQLSVCPASSWORD=P2ssw0rd /AGTSVCPASSWORD=P2ssw0rd /SAPWD=P2ssw0rd"
        Write-Verbose "Running SQL Install - check %programfiles%\Microsoft SQL Server\120\Setup Bootstrap\Log\ for logs..."
        Invoke-Expression $cmd | Write-Verbose
        #>

        }
        Catch
        {
         $ErrorMessage = $_.Exception.Message
         Write-Error -Message $ErrorMessage
         $Success = $false
        }
        $success=$true
    }

}