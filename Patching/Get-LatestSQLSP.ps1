function Get-LatestSqlSP
{
	[OutputType([pscustomobject])]
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[ValidateSet('2005','2008R2', '2012', '2014', '2016')]
		[string]$SqlServerVersion,
        [Parameter(Mandatory=$False)]
        [ValidateNotNullOrEmpty()]
		[string]$Source
	)


	process
	{
		try
		{
			(Import-Csv -Path "$source\sqlversions.csv").where({ $_.MajorVersion -eq $SqlServerVersion }) | sort-object servicepack -Descending | Select-Object -first 1
		}
		catch
		{
			Write-Error -Message $_.Exception.Message
		}
	}
}