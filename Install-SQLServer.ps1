Function Install-SQLServer
{
    param (
        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [String]
        $ComputerName = $env:ComputerName,
        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [String]
        $PackagePath="\\bhf-storage02\ServerTeam\ISOs Installs and Service Packs\SQL\2014",
        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [String]
        $PackageName="en_sql_server_2014_developer_edition_with_service_pack_1_x64_dvd_6668542.iso",
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
        $SQLAgent,
        [Parameter(Mandatory=$True)]
        [ValidateNotNullOrEmpty()]
        [String]
        $SQLPW,
        [Parameter(Mandatory=$True)]
        [ValidateNotNullOrEmpty()]
        [String]
        $AGTPW

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
        write-host $IsoDrive
        start-SQLInstall -ISODrive $IsoDrive
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
        Write-Host "Drive letter for iso is: $setupDriveLetter"

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
        write-host "Is this thing on?"
        # run the installer using the ini file
        $cmd = "$IsoDrive\Setup.exe /ConfigurationFile=c:\temp\ConfigurationFile.ini /SQLSVCPASSWORD=$SQLPW /AGTSVCPASSWORD=qtkkKq>CN[9U2FSb /SAPWD=$AGTPW"
        Write-Host "Running SQL Install - check %programfiles%\Microsoft SQL Server\120\Setup Bootstrap\Log\ for logs..."
        Invoke-Expression $cmd | Write-Verbose
       

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
