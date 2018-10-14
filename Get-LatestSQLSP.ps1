function Get-LatestSqlSP
{
	[OutputType([pscustomobject])]
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[ValidateSet('2005','2008R2', '2012', '2014', '2016')]
		[string]$SqlServerVersion
	)
	process
	{
		try
		{
			(Import-Csv -Path "PathHere\sqlversions.csv").where({ $_.MajorVersion -eq $SqlServerVersion }) | sort-object servicepack -Descending | Select-Object -first 1
		}
		catch
		{
			Write-Error -Message $_.Exception.Message
		}
	}
}