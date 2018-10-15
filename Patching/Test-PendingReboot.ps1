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