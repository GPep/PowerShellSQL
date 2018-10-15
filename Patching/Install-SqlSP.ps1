function Install-SqlSP
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


			$connParams = @{
				'ComputerName' = $ComputerName
			}
				
			Write-Verbose -Message "Installing SP on [$($ComputerName)]"
            #extract SP to server
			$spExtractPath = 'C:\Windows\Temp\SQLSP'
			Invoke-Program @connParams -FilePath $installer.FullName -ArgumentList "/extract:`"$spExtractPath`" /quiet"
					
			## Install the SP
			Invoke-Program @connParams -FilePath "$spExtractPath\setup.exe" -ArgumentList '/q /allinstances'
				
			if ($Restart.IsPresent)
				{
					Restart-Computer @connParams -Wait -Force
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