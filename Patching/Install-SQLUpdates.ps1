function Install-SqlServerCumulativeUpdate
{
	[CmdletBinding(SupportsShouldProcess)]
	param
	(
		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[string]$ComputerName,
		
		[Parameter(Mandatory, ParameterSetName = 'Number')]
		[ValidateNotNullOrEmpty()]
		[int]$Number,
		
		[Parameter(Mandatory, ParameterSetName = 'Latest')]
		[ValidateNotNullOrEmpty()]
		[switch]$Latest,
		
		[Parameter()]
		[ValidateNotNullOrEmpty()]
		[switch]$Restart
	)
	process {
		try
		{
			if (Test-PendingReboot -ComputerName $ComputerName)
			{
				throw "The computer [$($ComputerName)] is pending a reboot. Reboot the computer before proceeding."
			}
			
			## Find the current version on the computer
			$currentVersion = Get-SQLServerVersion -ComputerName $ComputerName
			
			## Find the architecture of the computer
			##TODO: ADB - This should be a function
			$arch = (Get-CimInstance -ComputerName $ComputerName -ClassName 'Win32_ComputerSystem' -Property 'SystemType').SystemType
			if ($arch -eq 'x64-based PC')
			{
				$arch = 'x64'
			}
			else
			{
				$arch = 'x86'
			}
			
			## Find the installer to use
			$params = @{
				'Architecture' = $arch
				'SqlServerVersion' = $currentVersion.MajorVersion
				'ServicePackNumber' = $currentVersion.ServicePack
			}
			if ($PSBoundParameters.ContainsKey('Number'))
			{
				$params.CumulativeUpdateNumber = $Number
			}
			elseif ($Latest.IsPresent)
			{
				$params.CumulativeUpdateNumber = (Get-LatestSqlServerCumulativeUpdateVersion -SqlServerVersion $currentVersion.MajorVersion -ServicePackNumber $currentVersion.ServicePack).CumulativeUpdate
			}
			
			if ($currentVersion.CumulativeUpdate -eq $params.CumulativeUpdateNumber)
			{
				throw "The computer [$($ComputerName)] already has the specified (or latest) cumulative update installed."
			}
			
			if (-not ($installer = Find-SqlServerCumulativeUpdateInstaller @params))
			{
				throw "Could not find installer for cumulative update [$($params.CumulativeUpdateNumber)]"
			}
			
			## Apply SP
			if ($PSCmdlet.ShouldProcess($ComputerName, "Install cumulative update [$($installer.Name)] for SQL Server [$($currentVersion.MajorVersion)]"))
			{
				$invProgParams = @{
					'ComputerName' = $ComputerName
					'Credential' = $Credential
				}
				
				$spExtractPath = 'C:\Windows\Temp\SQLCU'
				Invoke-Program @invProgParams -FilePath $installer.FullName -ArgumentList "/extract:`"$spExtractPath`" /quiet"
				
				## Install the SP
				Invoke-Program @invProgParams -FilePath "$spExtractPath\setup.exe" -ArgumentList '/quiet /allinstances'
				
				if ($Restart.IsPresent)
				{
					Restart-Computer -ComputerName $ComputerName -Wait -For WinRm -Force
				}
				
			}
		}
		catch
		{
			Write-Error -Message $_.Exception.Message
		}
	}
}













function Install-SqlServerServicePack
{
	<#
	.SYNOPSIS
		This function attempts to install a service pack to a SQL instance. It discovers the current version of SQL
		installed, searches for the bits for the service pack and installs the service pack specified.
	
	.EXAMPLE
		PS> Install-SqlServicePack -ComputerName SERVER1 -Number 2
	
		This example attempts to install service pack 2 for whatever version of SQL that's installed on SERVER1.
	
	.EXAMPLE
		PS> Install-SqlServicePack -ComputerName SERVER1 -Latest
	
		This example will find the latest service pack that is downloaded and will attempt to install it on SERVER1.
	
	.PARAMETER ComputerName
		A mandatory string parameter representing the FQDN of the computer to run the function against. This must be
		a FQDN.
	
	.PARAMETER Number
		A mandatory integer parameter if Latest is not used. This represents the service pack to attempt to install.
	
	.PARAMETER Latest
		A mandatory switch parameter if Number is not used. Using this parameter will find the latest service pack
		that has been downloaded for the SQL server version installed on ComputerName that will be installed.
	
	.PARAMETER Restart
		An optional switch parameter. By default, ComputerName will not restart after service pack installation. If this parameter is used, it will
		restart after a successful install.
	
	.PARAMETER Credential
		An optional pscredential parameter representing a credential to use to connect to ComputerName. By default,
		this will be the pscredential for 'GENOMICHEALTH\svcOrchestrator' returned from the key store.
	
	#>
	[OutputType([void])]
	[CmdletBinding(SupportsShouldProcess, DefaultParameterSetName = 'Latest')]
	param
	(
		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[string]$ComputerName,
		
		[Parameter(Mandatory, ParameterSetName = 'Number')]
		[ValidateNotNullOrEmpty()]
		[ValidateRange(1, 5)]
		[int]$Number,
		
		[Parameter(Mandatory, ParameterSetName = 'Latest')]
		[ValidateNotNullOrEmpty()]
		[switch]$Latest,
		
		[Parameter()]
		[ValidateNotNullOrEmpty()]
		[switch]$Restart
	)
	process
	{
		try
		{
			## Find the current version on the computer
			$currentVersion = Get-SQLServerVersion -ComputerName $ComputerName
			
			## Figure out the service pack to use if -Latest was used instead of -Number.
			if ($Latest.IsPresent)
			{
				$Number = (Get-LatestSqlServerServicePackVersion -SqlServerVersion $currentVersion.MajorVersion).ServicePack
			}
			
			## Common Invoke-Command et al connection parameters
			$connParams = @{
				'ComputerName' = $ComputerName
			}
				
			Write-Verbose -Message "Installing SP on [$($ComputerName)]"
			
			## Find the architecture of the computer
			##TODO: ADB - This should be a function
			$arch = (Get-CimInstance -ComputerName $ComputerName -ClassName 'Win32_ComputerSystem' -Property 'SystemType').SystemType
			if ($arch -eq 'x64-based PC')
			{
				$arch = 'x64'
			}
			else
			{
				$arch = 'x86'
			}
			
			## Find the installer to use
			$params = @{
				'Architecture' = $arch
				'SqlServerVersion' = $currentVersion.MajorVersion
				'Number' = $Number
			}
			
			if (TestSqlServerServicePack -ComputerName $ComputerName -ServicePackNumber $Number)
			{
				Write-Verbose -Message "The computer [$($ComputerName)] already has the specified (or latest) service pack installed."
			}
			else
			{
				if (-not ($installer = Find-SqlServerServicePackInstaller @params))
				{
					throw "Could not find installer for service pack [$($Number)] for version [$($currentVersion.MajorVersion)]"
				}
				
				if (Test-PendingReboot @connParams)
				{
					throw "The computer [$($ComputerName)] is pending a reboot. Reboot the computer before proceeding."
				}
				
				## Apply SP
				if ($PSCmdlet.ShouldProcess($ComputerName, "Install service pack [$($installer.Name)] for SQL Server [$($currentVersion.MajorVersion)]"))
				{
					$spExtractPath = 'C:\Windows\Temp\SQLSP'
					Invoke-Program @connParams -FilePath $installer.FullName -ArgumentList "/extract:`"$spExtractPath`" /quiet"
					
					## Install the SP
					Invoke-Program @connParams -FilePath "$spExtractPath\setup.exe" -ArgumentList '/q /allinstances'
					
					if ($Restart.IsPresent)
					{
						Restart-Computer @connParams -Wait -Force
					}
				}
			}
		}
		catch
		{
			Write-Error -Message $_.Exception.Message
		}
		finally
		{
			if ((Test-Path -Path Variable:\spExtractPath) -and $spExtractPath)
			{
				## Cleanup the extracted SP
				Invoke-Command @connParams -ScriptBlock { Remove-Item -Path $using:spExtractPath -Recurse -Force -ErrorAction SilentlyContinue }
			}
		}
	}
}



function Update-SqlServer
{
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[string]$ComputerName,
		
		[Parameter()]
		[ValidateNotNullOrEmpty()]
		[ValidateSet(1, 2, 3, 4, 5, 'Latest')]
		[string]$ServicePack = 'Latest',
		
		[Parameter()]
		[ValidateNotNullOrEmpty()]
		[ValidateSet(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 'Latest')]
		[string]$CumulativeUpdate = 'Latest',
		
		[Parameter()]
		[ValidateNotNullOrEmpty()]
		[pscredential]$Credential
	)
	process {
		try
		{
			$spParams = @{
				'ComputerName' = $ComputerName
				'Restart' = $true	
			}
			if ($ServicePack -eq 'Latest')
			{
				$spParams.Latest = $true
			}
			else
			{
				$spParams.Number = $ServicePack	
			}
			Install-SqlServerServicePack @spParams
				
			$cuParams = @{
				'ComputerName' = $ComputerName
				'Restart' = $true
			}
			if ($CumulativeUpdate -eq 'Latest')
			{
				$cuParams.Latest = $true
			}
			else
			{
				$cuParams.Number = $CumulativeUpdate
			}
			Install-SqlServerCumulativeUpdate @cuParams
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
		.SYNOPSIS
			This function tests various registry values to see if the local computer is pending a reboot
		.NOTES
			Inspiration from: https://gallery.technet.microsoft.com/scriptcenter/Get-PendingReboot-Query-bdb79542
		.EXAMPLE
			PS> Test-PendingReboot
			
			This example checks various registry values to see if the local computer is pending a reboot.
	#>
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[string]$ComputerName,
		
		[Parameter()]
		[ValidateNotNullOrEmpty()]
		[pscredential]$Credential
	)
	process {
		try
		{
			$icmParams = @{
				'ComputerName' = $ComputerName
			}
			if ($PSBoundParameters.ContainsKey('Credential')) {
				$icmParams.Credential = $Credential
			}
			
			$OperatingSystem = Get-CimInstance -ComputerName $ComputerName -ClassName Win32_OperatingSystem -Property BuildNumber, CSName
			
			# If Vista/2008 & Above query the CBS Reg Key
			If ($OperatingSystem.BuildNumber -ge 6001)
			{
				$PendingReboot = Invoke-Command @icmParams -ScriptBlock { Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing' -Name 'RebootPending' -ErrorAction SilentlyContinue }
				if ($PendingReboot)
				{
					Write-Verbose -Message 'Reboot pending detected in the Component Based Servicing registry key'
					return $true
				}
			}
			
			# Query WUAU from the registry
			$PendingReboot = Invoke-Command @icmParams -ScriptBlock { Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update' -Name 'RebootRequired' -ErrorAction SilentlyContinue }
			if ($PendingReboot)
			{
				Write-Verbose -Message 'WUAU has a reboot pending'
				return $true
			}
			
			# Query PendingFileRenameOperations from the registry
			$PendingReboot = Invoke-Command @icmParams -ScriptBlock { Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager' -Name 'PendingFileRenameOperations' -ErrorAction SilentlyContinue }
			if ($PendingReboot -and $PendingReboot.PendingFileRenameOperations)
			{
				Write-Verbose -Message 'Reboot pending in the PendingFileRenameOperations registry value'
				return $true
			}
		}
		catch
		{
			Write-Error -Message $_.Exception.Message
		}
	}
}



$getCred = Get-Credential 'Domain99UserName99'
$servers = "Server1","Server2";
$Jobsession = New-PSSession -Computername $servers -Credential $getCred;
## - display the sessions:


$Jobsession
## - Submit jobs to background process on selected servers:


Invoke-Command -Session $Jobsession -AsJob -JobName 'TestBackgroundInstall' -ScriptBlock {
new-psdrive -name SQLInstallDrive -psprovider FileSystem -root \\WIN8Server1\install;
cd SQLInstallDrive:;
& ./SQLServer2008R2SP1-KB2528583-x64-ENU.exe /allinstances;
};
## To Display jobs:


get-job
## - To Close PS Sessions and remove variabler:


remove-PSSession $Jobsession
Remove-Variable $Jobsession
