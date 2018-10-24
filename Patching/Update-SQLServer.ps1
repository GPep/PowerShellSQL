Function Update-SQLServer
{
<#
	.SYNOPSIS
		This function attempts updates a server with the latest Service Pack and/or CU for SQL versions 2005-2016 (if required). 
        It will first check the current version, then check the latest version (information held in a .CSV file) 
        before copying the files to the server and attempting to install them.
	
    The main source of inspiration for this came from Adam Bertram and this blog post:

    https://4sysops.com/archives/update-multiple-sql-server-systems-with-powershell/

    My version is a lot more simple (but not quite as robust!) to Adam's although I hope to improve this over time as my PowerShell
    skills improve. 
    I have used the same premise as him with the folder structure, naming conventions and CSV reference file. 

    For now this version will only update one Server at a time but a future revision will allow for multiple server updates.

    This is not cluster or AG aware so be careful that you do not run this on active (cluster) or Primary (AG) nodes. 
    Always run on the passive or Secondary nodes first before failing over and repeating the process on the other nodes.

    Another future version, Adam's will allow you to install any SP or CU you want but for now this will only install the latest SPs and CUs available.

    ****PLEASE TEST THIS BEFORE RUNNING IT ON ONE OF YOUR PRODUCTION ENVIRONMENTS!!!!!****

	.EXAMPLES
		PS> Update-SQLServerk -ComputerName SERVER1 -Source '\\UNCPath\SQLInstallers\SQL' -Credential 'ServerAdmin
	
		This example attempts to to install any updates for SERVER1 using the credential 'ServerAdmin'.
        the Source files for the SQL updates are stored in \\UNCPath\SQLInstallers\SQL
        The pre-requisites for this automated patch updates to work are the following

        PS> Update-SQLServer 'BHF-FOXTROT\foxtrot' -test

        This example will perform a test on the server. I.e. it will check whether new SPs or CU can be applied and whether a reboot is required.
        Adding the test Parameter means that it won't install any updates.


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

        An Example of the CSV file can be found at https://github.com/GPep/PowerShellSQL/tree/master/Patching
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
        <#[Parameter(mandatory=$false)]
        [validateNotNullOrEmpty()]
        [pscredential]$credential ="$env:USERDOMAIN\$env:UserName",#>
        [Parameter(Mandatory=$false)]
		[ValidateNotNullOrEmpty()]
		[switch]$Test
    )
	process {
		try
		{

        IF ($test -eq $true)
        {
        write-host "Checking for SPs and CUs only. No update will be completed." -BackgroundColor Yellow -ForegroundColor Red
	    }
        ELSE
        {
        write-host "Checking for SPs and CUs before attempting updates" -BackgroundColor Green -ForegroundColor Red

        }


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
        
        $SQLversion = get-MajorVersion -version $major

        if($minor -ne '00' -and $major -eq '10')
        {
        $SQLVersion = $SQLVersion+"R2"
        }

 
                
        #Get latest SP available for this version
        $getLatestVersion = Get-LatestSqlSP -SqlServerVersion $SQLVersion -Source $source

        ##Check to see if your server is up to date
        If ($CurrentVersion.split('.')[2] -eq $getlatestVersion.FUllVersion.split('.')[2] -or $CurrentVersion.split('.')[2] -gt $getlatestVersion.FUllVersion.split('.')[2] )
        {

        write-host "Current SPs and CUs are up to date for $computerName" -BackgroundColor Green -ForegroundColor white

        }

        else
        {

        $latestBuild = $getlatestVersion.FUllVersion.split('.')[2]

        

        #If your server has minor security fixes and releases installed, the build versions may not match but the SP will do.
        #Therefore this just checks to see if the SP is required.

        if ($build.substring(0,1) -eq $latestBuild.substring(0,1))
        {
        $SPrequired = $false
        write-host "Service Packs are up to date" -BackgroundColor Green -ForegroundColor white
        }
        else
        {
        $SPrequired = $true
        write-host "Service Packs need updating" -BackgroundColor red -ForegroundColor white

        }

        $spName = Find-SqlSP -SqlServerVersion $SQLVersion -source $source

        #get installers for SP and CUs - This gets the  name of the installer from your 'Updates' folder.



        #This checks as to whether a CU needs to be installed and if so, confirms which one.

        IF ($getLatestversion.CumulativeUpdate -ne '')
        {
        $CuName = Find-SqlCU -SqlServerVersion $SQLVersion -source $source -ServicePack $getLatestVersion.ServicePack
        $CU = $true
        write-host "Cumlative Updates Required: $CUName" -BackgroundColor red -ForegroundColor white
        }
        Else
        {
        $Cu = $false
        $getLatestVersion.CumulativeUpdate = 'None'
        write-host "No CUs need to be installed" -BackgroundColor Green -ForegroundColor white
        }

        
        #Test if Reboot required before starting updates.

        #strip away instance name if this is a named instance
        
        $ServerName = $ComputerName.Split('\')[0]

        $rebootFirst = Test-PendingReboot $serverName
        
        if ($rebootfirst.isrebootPending -eq $true){
        Write-Host "$ComputerName Needs rebooting first before patches can be appied" -BackgroundColor Black -ForegroundColor red
        return
        }

        else {

        IF ($test -eq $false)
        {

        
        write-host "Preparing to update $ComputerName" -BackgroundColor Blue -ForegroundColor green

        If ($sprequired -eq $true)
        {
        #Update SP (if required)
        $SPInstaller = "$source\$SQLVersion"+"\Updates\$spName"

        Install-SqlSP -ComputerName $ComputerName -installer $spInstaller -spName $SPname -restart $true

        }
        
        if ($cu -eq $true)
        {


        $CUInstaller = "$source\$SQLVersion"+"\Updates\$CUName"

        #Update CU (if required)
        Install-SqlCU -ComputerName $ComputerName -installer $CUInstaller -CUName $CUname -restart $true

        }

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

         $obj = new-object PSObject -Property @{ ServerName=$ComputerName; CurrentVersion=$CurrentVersion;LatestVersion=$getLatestVersion.fullversion;
         ServicePack=$getlatestVersion.servicePack; CumulativeUpdate=$getLatestVersion.CumulativeUpdate; SPRequired=$SPrequired; CURequired=$CU; 
         RebootFirst=$rebootfirst.isrebootPending}

         $obj | format-table ServerName, CurrentVersion, LatestVersion, ServicePack, CumulativeUpdate, SPRequired, CURequired, RebootFirst

         if ($test -eq $true -or $rebootfirst.isrebootPending -eq $true)
         {

         write-host "Checks completed. No updates were applied" -BackgroundColor Yellow -ForegroundColor Red
         }
         ELSE
         {
         write-host "SQL Server Patch and CU update completed" -BackgroundColor Green -ForegroundColor Red
         }
        }


    }

}


function Get-SQLServerVersion
{

<#
	.SYNOPSIS
    This function checks the current version of SQL Server running on a server

    .Example
    Get-SQLServerVersion -ComputerName 'Server1'

#>


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

<#
	.SYNOPSIS
    This takes the major build number and returns the major version year (2005, 2008, 2012 etc)

#>

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

<#
	.SYNOPSIS
    This checks the name of the latest SP and CUs available for your SQL Version.

#>
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

<#
	.SYNOPSIS
    This  confirms the name of the latest SP (stored in your source Folder) that needs to be installed



#>
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

<#
	.SYNOPSIS
    This  confirms the name of the latest CU (stored in your source Folder) that needs to be installed



#>
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

            return $cu.name
            


        }


        	catch
		{
			Write-Error -Message $_.Exception.Message
		}
	}
}


function Install-SqlSP
{

<#
	.SYNOPSIS
    This  will copy the SP from the source folders to the Remote Server and then start the install. 
    Your Server is set to restart after the install has completed.



#>


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

        [Parameter(mandatory=$false)]
        [validateNotNullOrEmpty()]
        [pscredential]$credential ="$env:USERDOMAIN\$env:UserName",

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
            Copy-Item -Tosession $targetSession –Path "$Installer" -Destination "$spExtractPath" -Force -PassThru -Verbose 


            #Invoke-command -session $targetSession -ScriptBlock { copy-item -Path $using:Installer -Destination $using:SPExtractPath -Force -PassThru -Verbose }
            

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
				Remove-Item -Path "\\$computerName\C$\windows\temp\$spName" -Recurse -Force -ErrorAction SilentlyContinue
                
		}
		}
}


function Install-SqlCU
{

<#

   	.SYNOPSIS
    This  will copy the SP from the source folders to the Remote Server and then start the install. 
    Your Server is set to restart after the install has completed.



#>


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

        [Parameter(mandatory=$false)]
        [validateNotNullOrEmpty()]
        [pscredential]$credential ="$env:USERDOMAIN\$env:UserName",

        [Parameter()]
        [validateNotNullOrEmpty()]
        [bool]$restart

	)
	process
	{
		try
		{

            write-host "copying CU to $computerName"
            #extract CU to server
			$CUExtractPath = "C:\windows\Temp\$CUName"
      
            $targetSession = New-PSSession -ComputerName $Computername -Credential $credential
            Copy-Item -Tosession $targetSession –Path "$Installer" -Destination "$CUExtractPath" -Force -PassThru -Verbose 

            #Invoke-command -session $targetSession -ScriptBlock { copy-item -Path $using:Installer -Destination $using:CUExtractPath -Force -PassThru -Verbose }
            

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
				Remove-Item -Path "\\$computerName\C$\windows\temp\$CUName" -Recurse -Force -ErrorAction SilentlyContinue
                
		}
		}
}
