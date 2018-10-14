function Get-LatestSqlCU
{
	[OutputType([pscustomobject])]
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[ValidateSet('2005','2008R2', '2012', '2014', '2016')]
		[string]$SqlServerVersion,
		
		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[ValidateRange(1, 5)]
		[int]$ServicePackNumber
	)
	process
	{
		try
		{
			(Import-Csv -Path "PathHere\sqlversions.csv").where({
				$_.MajorVersion -eq $SqlServerVersion -and $_.ServicePack -eq $ServicePackNumber
			}) | sort-object { [int]$_.cumulativeupdate } -Descending | Select-Object -first 1
		}
		catch
		{
			Write-Error -Message $_.Exception.Message
		}
	}
}



