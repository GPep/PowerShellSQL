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
            write-host $srv.Version
            $major = $srv.Version.Major
            $minor = $srv.version.minor
            $build = $srv.version.build
            $version = "$major.$minor.$build"
            return $version

			}
		}
		catch
		{
			Write-Error -Message $_.Exception.Message
		}

	}
}