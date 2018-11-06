Function Change-SQLJobOwners {
<#
	.SYNOPSIS
    This function can change the SQL Agent Job owner for all jobs on a server. using the -whatif parameter simply creates a text file with the SQL script
		

    .EXAMPLE
    Change-SQLJobOwners -Server 'ServerName' -NewOwner 'SA'

    This will change all job owners to 'SA' where the owner is set to something else. An output file is saved to C:\Temp\servername - changeJobOwners.txt if the server has a list of jobs that need the owner changed.

    .PARAMETERS
    -Server 
    This is the server/instance name
    -NewOwner
    This is the login that you wish to be the new owner
    -Whatif 
    This parameter will not update the jobs. It will simply create the text file with the SQL script in it.



#>



    Param(
          [Parameter(Mandatory)]
          [string[]]$ComputerName,
          [Parameter(Mandatory=$false)]
          [ValidateLength(0,80)]
          [string]$newOwner='SA',
          [Parameter(Mandatory=$false)]
		  [ValidateNotNullOrEmpty()]
		  [switch]$WhatIf=$false
    )
    Process
    {


        try 
        {

        $obj = @()

        Foreach ($Comp in $ComputerName)
        {

        $nl = [Environment]::NewLine

        $ServerName = $Comp.replace('\','-')

        $logFile = "C:\Temp\$serverName - ChangeJobOwners.txt"
        IF (!(Test-Path $logFile))
        {
        new-item $logFile
        }
        else
        {
        Clear-Content -Path $logFile
        }

            $jobowners = get-dbaagentJob -SQLInstance $comp | where-object {$_.OwnerLoginName -ne $NewOwner}
            $obj += $jobowners

            Foreach($job in $jobOwners)
              {
                $sqlquery = "---- Current owner: " + $job.OwnerLoginName + $nl + "EXEC msdb.dbo.sp_update_job @job_id=N'" + $job.JobID + "'" + $nl + ", @owner_login_name=N'$newOwner'" 
                $sqlquery | out-file -filepath $logFile -append
                
                
                If ($whatif -eq $false)
                {
                Invoke-Sqlcmd -ServerInstance $comp -query $sqlquery
                }
              }
        }

        }
        Catch {

            $ErrorMessage = $_.Exception.Message
            Write-Error -Message $ErrorMessage
            $ErrorMessage| out-file $logFile -append
              }
        finally 
        {
        
        $obj | format-table -Property Name, OwnerLoginName, sqlinstance

        }
    }

}