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
    
    


    Try 
    {

    foreach ($comp in $computerName)
    {
     
    $databases = get-dbaDatabaseFreeSpace -SQLServer $Comp | where-object {$_.AutoGrowth -eq '0' -or $_.AutoGrowType -eq 'pct'}
    $obj += $databases
   
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
     $obj | format-table -Property Database,FileName, PhysicalName, FileSizeMB, FreeSpaceMB, AutoGrowth, AutoGrowType, ComputerName | out-file $logFile -append
   } 
    
}

}