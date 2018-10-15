function Install-SqlCU
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

			$connParams = @{
				'ComputerName' = $ComputerName
			}

			Write-Verbose -Message "Installing CU on [$($ComputerName)]"

				$spExtractPath = 'C:\Windows\Temp\SQLCU'
				Invoke-Program @invProgParams -FilePath $installer.FullName -ArgumentList "/extract:`"$spExtractPath`" /quiet"
				
				## Install the SP
				Invoke-Program @invProgParams -FilePath "$spExtractPath\setup.exe" -ArgumentList '/quiet /allinstances'
				
				if ($Restart.IsPresent)
				{
					Restart-Computer -ComputerName $ComputerName -Wait -For WinRm -Force
				}
				
		}
		catch
		{
			Write-Error -Message $_.Exception.Message
		}
	}
}