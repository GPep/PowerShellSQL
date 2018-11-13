Function Set-SimpleMode

<#
	.SYNOPSIS
    This function can change the Database owner for all Databases on a server. using the -whatif parameter simply creates a text file with the SQL script
    The script is created by default.
		

    .EXAMPLE
    set-DBOwner -ComputerName ServerName1, ServerName2 -NewOwner 'SA' 

    This will change all job owners to 'SA' where the owner is set to something else. An output file is saved to C:\Temp\servername - changeJobOwners.txt if the server has a list of jobs that need the owner changed.

    .PARAMETERS
    -Computer
    This is the server/instance name
    -NewOwner
    This is the login that you wish to be the new owner
    -NoChange
    This parameter is used to enter another login, so if any databases use this login, the script will ignore and not update them. 
    This is specifically if you have any databases where the owner should be something other than the main SA account.
    -Whatif 
    This parameter will not update the jobs. It will simply create the text file with the SQL script in it.



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
     $DBNames = get-dbadatabase -ServerInstance $Comp | where-object {$_.name -ne 'MSDB' -and $_.recoveryModel -ne 'SIMPLE'} 
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