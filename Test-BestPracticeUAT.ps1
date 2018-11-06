Function Test-BestPracticeUAT

<#
	.SYNOPSIS
    This function checks for some UAT best Practices across an SQL Estate. Primarliy it checks for the database owner, recovery model (should be simple)
    and also the current job owners.
		

    .EXAMPLE
    Test-BestPracticeUAT -ComputerName ServerName1, ServerName2 -NewOwner 'SA' 

    This will return a list of all databases where the owners are not SA, where the  recovery model is set to Full and also where the job owners are not set to 'SA'

    .PARAMETERS
    -Computer
    This is the server/instance name
    -NewOwner
    This is the login you wish to check is the owner of your databases and Agent Jobs. This is not mandatory and can be set to whatever you want. I default mine to 'SA'
 

#>

{

[CmdletBinding()]
	param
	(
		[Parameter(Mandatory)]
		[string[]]$ComputerName,
        [Parameter(Mandatory=$false)]
        [String]$Owner='C4rb0n'

    )
    
    Process

    {

    $obj = @()
    $obj2=@()
    $obj3=@()
    
    $logFile = "C:\Temp\UATBestPractice.txt"
        IF (!(Test-Path $logFile))
        {
        new-item $logFile
        }
        else
        {
        Clear-Content -Path $logFile
        }
    
    
    Try 
    {

    foreach ($comp in $computerName)
    {
     
    $owners = get-dbadatabase -ServerInstance $Comp | where-object {$_.owner -ne $Owner}
    $obj += $owners

    

    $model = get-dbadatabase -ServerInstance $comp -RecoveryModel full
    $obj2 += $model   


    #Test for Incorrect Job Owners

    $jobowners = get-dbaagentJob -SQLInstance $comp | where-object {$_.OwnerLoginName -ne $Owner}
    $obj3 += $jobowners
 
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

     "Databases where owner is not $Owner :"   | out-file $logFile -append
     $obj | format-table -Property Name, owner, ComputerName | out-file $logFile -append

     "Databases where recovery model is set to FULL"  | out-file $logFile -append

     $obj2 | format-table -Property Name, RecoveryModel, ComputerName | out-file $logfile -append

     "SQL Jobs where owner is not $Owner :" | out-file $logFile -append

     $obj3 | format-table -Property Name, OwnerLoginName, sqlinstance | out-file $logfile -append
    }
   } 
    
}