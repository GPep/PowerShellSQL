Function Set-SimpleMode

<#
	.SYNOPSIS
    This function can change the Database recovery model to 'Simple'. using the -whatif parameter simply creates a text file with the SQL script
    The script is created by default.
		

    .EXAMPLE
    set-SimpleMode -ComputerName ServerName1, ServerName2

    This will change all databases on a server to the simple recovery model. 
    An output file is saved to C:\Temp\servername - SetSimpleMode.txt if the server has a list of databases that can be changed.

    .PARAMETERS
    -Computer
    This is the server/instance name
    -DatabaseName
    This parameter can be used if you only want to change the recovery model of one database. By default, this is $null and will be ignored.
    -Whatif 
    This parameter will not update the recovery model. It will simply create the text file with the SQL script in it.



#>

{

[CmdletBinding()]
	param
	(
		[Parameter(Mandatory)]
		[string[]]$ComputerName,
        [Parameter(Mandatory=$false)]
		[string]$DatabaseName =$null,
        [Parameter(Mandatory=$false)]
		[ValidateNotNullOrEmpty()]
		[switch]$WhatIf=$false

    )
    
    Process

    {

    $obj = @()

    
    
    
    
    Try 
    {

    foreach ($comp in $computerName)
    {
    
    $nl = [Environment]::NewLine

    #$srv = New-Object Microsoft.SqlServer.Management.Smo.Server($comp)

    $ServerName = $comp.replace('\','-')

    $logFile = "C:\Temp\$serverName - SetSimpleMode.txt"
    IF (!(Test-Path $logFile))
    {
    new-item $logFile
    }
    else
    {
    Clear-Content -Path $logFile
    }
    If (!$databaseName)
    {
     $DBNames = get-dbadatabase -ServerInstance $Comp | where-object {$_.recoveryModel -ne 'SIMPLE'} 
     $obj += $DBNames
      
     foreach ($DBName in $DBNames)
        
     {


                $sqlqry = "USE Master" + $nl + "ALTER DATABASE [" + $dbName.name + "] SET RECOVERY SIMPLE"
                $sqlqry | out-file -filepath $logFile -append

                If ($whatif -eq $false)
                {
                Invoke-Sqlcmd -ServerInstance $comp -query $sqlqry
                }


     }
    }      
    Else
    {
                
                $DBNames = get-dbadatabase -ServerInstance $Comp | where-object {$_.name -eq $DatabaseName} 
                $obj += $DBNames
                $sqlqry = "USE Master" + $nl + "ALTER DATABASE [$databaseName] SET RECOVERY SIMPLE"
                $sqlqry | out-file -filepath $logFile -append
        
                If ($whatif -eq $false)
                {
                Invoke-Sqlcmd -ServerInstance $comp -query $sqlqry
                }
    }
    }

    }
    Catch
    {
            $ErrorMessage = $_.Exception.Message
            Write-Error -Message $ErrorMessage
            $ErrorMessage| out-file $logFile -append
    }
    finally
    {

    If ($whatIf -eq $true)
       {
       Write-Host "WHATIF PARAMETER USED - NO UPDATES APPLIED" | out-file $logFile -Append
       $nl
       }


        $obj  | format-table -Property Name,status,owner,recoverymodel, ComputerName
    }

    

    }
    
    
}