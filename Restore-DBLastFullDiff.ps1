$FullDirectory = '\\BHF-STORAGE02\BackupShare\POC_Listener\DV-SQLCLN-91\Tools\FULL\'
$diffDirectory = '\\BHF-STORAGE02\BackupShare\POC_Listener\DV-SQLCLN-91\Tools\DIFF\'


$lastFull = get-childItem $FullDirectory | Sort-Object LastWriteTime -Descending | Select-Object -First 1
$lastDiff = Get-ChildItem $diffDirectory | Sort-Object LastWritetime -Descending | Select-Object -First 1


$FullBackup = $FullDirectory+$lastFull
$DiffBackup = $diffDirectory+$lastDiff


write-host $FullBackup
Write-host $DiffBackup

$sqlServerSnapinVersion = (Get-Command Restore-SqlDatabase).ImplementingType.Assembly.GetName().Version.ToString()

$assemblySqlServerSmoExtendedFullName = "Microsoft.SqlServer.SmoExtended, Version=$sqlServerSnapinVersion, Culture=neutral, PublicKeyToken=89845dcd8080cc91"

$RelocateData1 = New-Object "Microsoft.SqlServer.Management.Smo.RelocateFile,$assemblySqlServerSmoExtendedFullName"("Tools", "E:\MSSQL\DATA\Tools.mdf")
  
$RelocateLog = New-Object "Microsoft.SqlServer.Management.Smo.RelocateFile,$assemblySqlServerSmoExtendedFullName"("Tools_log", "L:\MSSQL\LOGS\Tools_log.ldf")

IF ($lastFull.LastWriteTime -gt $lastDiff.LastWriteTime)
{
Write-host "Differential Older than Last Full Backup"

Restore-SqlDatabase -ServerInstance DV-SQLCLN-91 -database Tools -BackupFile $FullBackup -ReplaceDatabase -RelocateFile @($RelocateData1, $RelocateLog)


}

else 
{

write-host "Differential will be restored after Full Backup"

Restore-SqlDatabase -ServerInstance DV-SQLCLN-91 -database Tools -BackupFile $FullBackup -ReplaceDatabase -NoRecovery -RelocateFile @($RelocateData1,$RelocateLog)

Restore-SqlDatabase -ServerInstance DV-SQLCLN-91 -Database Tools -BackupFile $DiffBackup


}
