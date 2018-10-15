Function Update-SQLServer

{
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[string]$ComputerName,
        [Parameter(Mandatory=$False)]
        [ValidateNotNullOrEmpty()]
		[string]$Source = "\\bhf-storage02\ServerTeam\ISOs Installs and Service Packs\SQL"

    )
	process {
		try
		{
	

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
        write-host $SQLVersion
        }

 
                
        #Get latest SP available for this version
        $getLatestVersion = Get-LatestSqlSP -SqlServerVersion $SQLVersion -Source $source
        write-host "The latest version is" $getLatestVersion.fullversion
        write-host "The latest service pack is" $getlatestVersion.servicePack




        write-host "The Current Service Pack is:" $currentSP

        If ($CurrentVersion.split('.')[2] -eq $getlatestVersion.FUllVersion.split('.')[2])
        {

        write-host 'Current SPs and CUs are up to date'

        }

        else
        {

        write-host $build
        $latestBuild = $getlatestVersion.FUllVersion.split('.')[2]

        write-host $build.substring(0,1)
        write-host $latestbuild.substring(0,1)

        $SPrequired = $true

        if ($build.substring(0,1) -eq $latestBuild.substring(0,1))
        {
        $SPrequired = $false
        }


        #get installers for SP and CUs

        write-host 'SQL Server Requires Updating with'
        $spName = Find-SqlSP -SqlServerVersion $SQLVersion -source $source

        write-host $spName


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
        $rebootFirst = Test-PendingReboot $ComputerName
        if ($rebootfirst -eq $true){
        Write-Host "$ComputerName Needs rebooting first before patches can be appied"
        }

        else {


        write-host "lets update this motherfucker"
        
        If ($sprequired -eq $true)
        {
        #Update SP (if required)
        write-host "service pack required"
        }
        
        if ($cu -eq $true)
        {
        #Update CU (if required)

        write-host "CU pack required"
        }

        }

        }

        }

        Catch

        {
        Write-Error -Message $_.Exception.Message

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


function Test-PendingReboot
{
	<#

	#>
    [OutputType([bool])]
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[string]$ComputerName
		
	)
	process {
    
    #strip away instance name if this is a named instance
    $ServerName = $ComputerName.Split('\')[0]

    IF (Invoke-Command -ComputerName $serverName -ea 0 -ScriptBlock { Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager" -Name PendingFileRenameOperations -EA Ignore } ) { return $true }
    IF (Invoke-Command -ComputerName $serverName -ea 0 -ScriptBlock { Get-Item "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired"}) { return $true }
    IF (Invoke-Command -ComputerName $serverName -ea 0 -ScriptBlock { Get-ChildItem "HKLM:\Software\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending"}) { return $true }

    try { 
        $util = [wmiclass]"\\.\root\ccm\clientsdk:CCM_ClientUtilities"
        $status = $util.DetermineIfRebootPending()
        if(($status -ne $null) -and $status.RebootPending){
        return $true
        } 
 

	    }
		catch
		{
		    Write-Error -Message $_.Exception.Message
		}
        return $false
	}
}