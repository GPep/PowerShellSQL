Function Test-FileGrowth 
{
[CmdletBinding()]
	param
	(
		[Parameter(Mandatory)]
		[string[]]$ComputerName
    )
    
    Process
    
    {

    $obj = @()

    $logFile = "C:\Temp\Test-FileGrowth.txt"
        IF (!(Test-Path $logFile))
        {
        new-item $logFile
        }
        else
        {
        Clear-Content -Path $logFile
        }
    
    
    $a = @{Expression={$_.Database};Label="Database";width=25},@{Expression={$_.FileName};Label="FileName";width=60},
    @{expression={$_.FileSizeMB};Label="FileSizeMB";Width=15},
    @{expression={$_.FreeSpaceMB};Label="FreeSpaceMB";Width=15},@{expression={$_.PercentUsed};Label="PercentUsed";Width=15}, @{expression={$_.AutoGrowth};Label="AutoGrowth";Width=15},
    @{expression={$_.AutoGrowType};Label="AutoGrowType";Width=5},@{expression={$_.SQLInstance};Label="SQLInstance";Width=30}

    Try 
    {

    foreach ($comp in $computerName)
    {
     
    $databases = get-dbaDBSpace -SQLServer $Comp | where-object {$_.AutoGrowth -eq '0' -or $_.AutoGrowType -eq 'pct'}
    $obj += $databases
    $databases2 = get-dbaDBSpace -SQLServer $comp | Where-Object {$_.AutoGrowth -lt '200' -and $_.AutoGrowType -eq 'MB'}
    $Obj += $databases2

   
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

     "Database Filegrowth:"   | out-file $logFile -append
     $obj | format-table $a | out-file $logFile -append
     $obj | format-table $a
   } 
    
}

}