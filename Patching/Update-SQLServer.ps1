﻿Function Update-SQLServer
{
<#
	.SYNOPSIS
		This function attempts updates a server with the latest Service Pack and/or CU for SQL versions 2005-2016 (if required). 
        It will first check the current version, then check the latest version (information held in a .CSV file) 
        before copying the files to the server and attempting to install them.
	
    The main source of inspiration for this came from Adam Bertram and this blog post:
    https://4sysops.com/archives/update-multiple-sql-server-systems-with-powershell/
    My version is a lot more simple (but quite as robust!) to Adam's although I hope to improve this over time as my PowerShell
    skills improve. 
    For now this version will only update one Server at a time but a future revision will allow for multiple server updates.

    ****PLEASE TEST THIS BEFORE RUNNING IT ON ONE OF YOUR PRODUCTION ENVIRONMENTS!!!!!****

	.EXAMPLE
		PS> Update-SQLServerk -ComputerName SERVER1 -Source '\\UNCPath\SQLInstallers\SQL' -Credential 'ServerAdmin
	
		This example attempts to to install any updates for SERVER1 using the credential 'ServerAdmin'.
        the Source files for the SQL updates are stored in \\UNCPath\SQLInstallers\SQL
        The pre-requisites for this automated patch updates to work are the following


     .Pre-Requisites
     
        ********IMPORTANT********

        1) All your installaters should be sorted in folders called '2005, 2008, 2008R2, 2012, 2014, 2016' containing an extra folder 
        called 'Updates' which holds all of your SPs and CU. 


        2) The SPs and CUs must be renamed so that that use the following naming convention

        SQLServerXXXX-SPX-CUX-x64.exe

        example for SQL Server 2012 SP2 CU3
        SQLServer2012-SP2-CU3-X64.exe

        3) You must also have a .CSV file at the top of your Source folder called 'SQLServerVersions.csv' with all your SPs and CUs listed. 
        They should have the following columns:

        FullVersion, Year, ServicePack, CumulativeUpdate

        This will need to be periodaically updated when new SPs and CUs are released and you will need to download new SPs and CUs as they are released.

        An Example of the CSV file can be found at http:\\github\GPep\Update-SQLServer
        Alternatively if using a Central Management Server, you could load these details into a table to be queried.


        The following webpage can be used to keep track of any new SP or CU releases.
        https://buildnumbers.wordpress.com/sqlserver/
      
	
#>


	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[string]$ComputerName,
        [Parameter(Mandatory=$False)]
        [ValidateNotNullOrEmpty()]
		[string]$Source = "\\bhf-storage02\ServerTeam\ISOs Installs and Service Packs\SQL",
        [Parameter()]
        [validateNotNullOrEmpty()]
        [String]$credential ="$env:USERDOMAIN\$env:UserName"
    )
	process {
		try
		{
	    
        IF (!(Get-Module -Name pendingreboot))
    {
        Write-Host 'Loading pendingreboot Module' -ForegroundColor DarkYellow
        Push-Location
        Import-Module pendingreboot -DisableNameChecking
        Pop-Location
    }

        #Get Current SQL Version for instance

        $CurrentVersion = Get-SQLServerVersion -ComputerName $ComputerName
        $major = $CurrentVersion.split('.')[0]
        $minor = $CurrentVersion.split('.')[1]
        $build = $CurrentVersion.split('.')[2]
        write-host "Current Version: $currentVersion"
        
        $SQLversion = get-MajorVersion -version $major

        if($minor -ne '00' -and $major -eq '10')
        {
        $SQLVersion = $SQLVersion+"R2"
        }

 
                
        #Get latest SP available for this version
        $getLatestVersion = Get-LatestSqlSP -SqlServerVersion $SQLVersion -Source $source
        write-host "The latest version is" $getLatestVersion.fullversion
        write-host "The latest service pack is" $getlatestVersion.servicePack


        If ($CurrentVersion.split('.')[2] -eq $getlatestVersion.FUllVersion.split('.')[2] -or $CurrentVersion.split('.')[2] -gt $getlatestVersion.FUllVersion.split('.')[2] )
        {

        write-host 'Current SPs and CUs are up to date'

        }

        else
        {

        $latestBuild = $getlatestVersion.FUllVersion.split('.')[2]


        $SPrequired = $true

        if ($build.substring(0,1) -eq $latestBuild.substring(0,1))
        {
        $SPrequired = $false
        }


        #get installers for SP and CUs

        write-host 'SQL Server Requires Updating with'
        $spName = Find-SqlSP -SqlServerVersion $SQLVersion -source $source




        IF ($getLatestversion.CumulativeUpdate -ne '')
        {
        $CuName = Find-SqlCU -SqlServerVersion $SQLVersion -source $source -ServicePack $getLatestVersion.ServicePack

        write-host $CuName
        $CU = $true
        }
        Else
        {
        $Cu = $false
        write-host "No CUs need to be installed"
        }

        
        #Test if Reboot required before starting updates.

        #strip away instance name if this is a named instance
        
        $ServerName = $ComputerName.Split('\')[0]
        $rebootFirst = Test-PendingReboot $serverName

        if ($rebootfirst.isrebootPending -eq $true){
        Write-Host "$ComputerName Needs rebooting first before patches can be appied"
        return
        }

        else {


        write-host "Preparing to update $ComputerName"
        
        If ($sprequired -eq $true)
        {
        #Update SP (if required)
        $SPInstaller = "$source\$SQLVersion"+"\Updates\$spName"
        write-host $SPInstaller


        Install-SqlSP -ComputerName $ComputerName -installer $spInstaller -spName $SPname -restart $true -credential $credential

        }
        
        if ($cu -eq $true)
        {

        $CUInstaller = "$source\$SQLVersion"+"\Updates\$CUName"

        #Update CU (if required)
        Install-SqlCU -ComputerName $ComputerName -installer $CUInstaller -spName $CUname -restart $true -credential $credential

        }

        }

        }

        }

        Catch

        {
        Write-Error -Message $_.Exception.Message

        }

        Finally

        {
         write-host "SQL Server Patch and CU update completed"

        }


    }

}


function Get-SQLServerVersion
{
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[string]$ComputerName
	)
	process
	{
		try
		{

            [reflection.assembly]::LoadWithPartialName("Microsoft.SqlServer.Smo") | out-null
            $srv = New-Object "Microsoft.SqlServer.Management.Smo.Server" $ComputerName
   			if (-not $srv.version)
			{
				throw 'Cannot Connect to Server'
			}
            

		    else
			{
            $major = $srv.Version.Major
            $minor = $srv.version.minor
            $build = $srv.version.build
            $version = "$Major.$minor.$build"
            return $version
			}
		}
		catch
		{
			Write-Error -Message $_.Exception.Message
		}

	}
}


function get-MajorVersion

{
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory)]
		[ValidateSet('9', '10', '10.5', '11', '12','13','14')]
		[string]$version
	)
	process
	{
		try
		{

$MajorVersion = switch -regex ($version)
					{
                        "^13" { "2016"; break }
                        "^12" { "2014"; break }
						"^11"		{ "2012"; break }
						"^10\.5"	{ "2008R2"; break }
						"^10"		{ "2008"; break }
						"^9"		{ "2005"; break }
						"^8"		{ "2000"; break }
						default { "Unknown"; }
					}

Return $MajorVersion


		}
		catch
		{
			Write-Error -Message $_.Exception.Message
		}

	}
}


function Get-LatestSqlSP
{
	[OutputType([pscustomobject])]
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[ValidateSet('2005', '2008', '2008R2', '2012', '2014', '2016')]
		[string]$SqlServerVersion,
        [Parameter(Mandatory=$False)]
        [ValidateNotNullOrEmpty()]
		[string]$Source = $source
	)


	process
	{
		try
		{
			$latestSP = (Import-Csv -Path "$source\sqlserverversions.csv").where({ $_.MajorVersion -eq $SqlServerVersion }) | sort-object servicepack -Descending | Select-Object -first 1
            return $latestSP

		}
		catch
		{
			Write-Error -Message $_.Exception.Message
		}
	}
}


function Find-SqlSP
{
	[OutputType('System.IO.FileInfo')]
	param
	(
		[Parameter()]
		[ValidateNotNullOrEmpty()]
		[ValidateSet('2005', '2008', '2008R2', '2012', '2014', '2016')]
		[string]$SqlServerVersion,
		[Parameter()]
		[ValidateNotNullOrEmpty()]
		[string]$Source = $Source
		
	)
	process
	{
		try
		{


			$servicePacks = Get-ChildItem -Path "$source\$SQLServerVersion\Updates" -Filter 'SQLServer*-SP?-*.exe'
			
            $sp = $servicePacks | Sort-Object { $_.Name } -Descending | Select-Object -First 1
            
            return $sp.name

        }


        	catch
		{
			Write-Error -Message $_.Exception.Message
		}
	}
}



function Find-SqlCU
{
	[OutputType('System.IO.FileInfo')]
	param
	(
		[Parameter()]
		[ValidateNotNullOrEmpty()]
		[ValidateSet('2005', '2008R2', '2012', '2014', '2016')]
		[string]$SqlServerVersion,
		[Parameter()]
		[ValidateNotNullOrEmpty()]
		[string]$Source = $Source,
		[Parameter(Mandatory=$False)]
        [ValidateNotNullOrEmpty()]
		[ValidateSet('SP1','SP2', 'SP3', 'SP4', 'SP5')]
        [string]$ServicePack
	)
	process
	{
		try
		{


			$CUUpdates = Get-ChildItem -Path "$source\$SQLServerVersion\Updates" -Filter "SQLServer*-$ServicePack-CU?*"

            $CU = $CuUpdates | Sort-Object { $_.Name } -Descending | Select-Object -First 1
            
            write-host $CU


        }


        	catch
		{
			Write-Error -Message $_.Exception.Message
		}
	}
}


function Install-SqlSP
{


	param
	(
		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[string]$ComputerName,

		[Parameter()]
		[ValidateNotNullOrEmpty()]
		[string]$installer,

        [Parameter()]
        [validateNotNullOrEmpty()]
        [String]$spName,

        [Parameter()]
        [validateNotNullOrEmpty()]
        [String]$credential,

        [Parameter()]
        [validateNotNullOrEmpty()]
        [bool]$restart

	)
	process
	{
		try
		{

            write-host "copying SP to $computerName"
            #extract SP to server
			$spExtractPath = "C:\windows\Temp\$spName"
      
            $targetSession = New-PSSession -ComputerName $Computername -Credential $credential
            Copy-Item -tosession $targetSession –Path "$Installer" -Destination "$spExtractPath" -recurse -Force -PassThru -Verbose 
            

            #invoke-command -ComputerName $ComputerName -Credential $credential -ScriptBlock{ Copy-Item –Path "$Using:Installer" -Destination "$using:spExtractPath" -Force -PassThru -Verbose}

			## Install the SP
            $argumentsList = '/q /allinstances'
			
            Invoke-Command -Session $targetsession -ScriptBlock {& cmd.exe /C "$using:SpExtractPath /q /allinstances /IAcceptSQLServerLicenseTerms"} -Verbose
			

            remove-psSession $targetSession
            
            if ($restart -eq $true)
            {
            
            Restart-Computer $ComputerName -Wait -Force

            }
        
		}
		catch
		{
			Write-Error -Message $_.Exception.Message
		}
		finally
		{
				## Cleanup the extracted SP
				Remove-Item -Path "\\$computerName\C$\temp\$spName" -Recurse -Force -ErrorAction SilentlyContinue
                
		}
		}
}


function Install-SqlCU
{


	param
	(
		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[string]$ComputerName,

		[Parameter()]
		[ValidateNotNullOrEmpty()]
		[string]$installer,

        [Parameter()]
        [validateNotNullOrEmpty()]
        [String]$CUName,

        [Parameter()]
        [validateNotNullOrEmpty()]
        [String]$credential,

        [Parameter()]
        [validateNotNullOrEmpty()]
        [bool]$restart

	)
	process
	{
		try
		{

            write-host "copying CU to $computerName"
            #extract SP to server
			$CUExtractPath = "C:\windows\Temp\$spName"
      
            $targetSession = New-PSSession -ComputerName $Computername -Credential $credential
            Copy-Item -tosession $targetSession –Path "$Installer" -Destination "$CUExtractPath" -recurse -Force -PassThru -Verbose 
            

            #invoke-command -ComputerName $ComputerName -Credential $credential -ScriptBlock{ Copy-Item –Path "$Using:Installer" -Destination "$using:spExtractPath" -Force -PassThru -Verbose}

			## Install the SP
            $argumentsList = '/q /allinstances'
			
            Invoke-Command -Session $targetsession -ScriptBlock {& cmd.exe /C "$using:CUExtractPath /q /allinstances /IAcceptSQLServerLicenseTerms"} -Verbose
			

            remove-psSession $targetSession
            
            if ($restart -eq $true)
            {
            
            Restart-Computer $ComputerName -Wait -Force

            }
        
		}
		catch
		{
			Write-Error -Message $_.Exception.Message
		}
		finally
		{
				## Cleanup the extracted SP
				Remove-Item -Path "\\$computerName\C$\temp\$CUName" -Recurse -Force -ErrorAction SilentlyContinue
                
		}
		}
}