CD C:

$FullDirectory = 'E:\DBA\BACKUP\'

$diffDirectory = '\\BHF-STORAGE02\DPMSQLMigrations\OneCRM\Backup\PD-CRMSQL$OneCRM\BBEC_V4\DIFF\'


$lastFull = get-childItem $FullDirectory | Sort-Object LastWriteTime -Descending | Select-Object -First 1
$lastDiff = Get-ChildItem $diffDirectory | Sort-Object LastWritetime -Descending | Select-Object -First 1


$FullBackup = $FullDirectory+$lastFull
$DiffBackup = $diffDirectory+$lastDiff


$sqlServerSnapinVersion = (Get-Command Restore-SqlDatabase).ImplementingType.Assembly.GetName().Version.ToString()

$assemblySqlServerSmoExtendedFullName = "Microsoft.SqlServer.SmoExtended, Version=$sqlServerSnapinVersion, Culture=neutral, PublicKeyToken=89845dcd8080cc91"


$RelocateData = New-Object "Microsoft.SqlServer.Management.Smo.RelocateFile,$assemblySqlServerSmoExtendedFullName"("BBI_PRIM", "Z:\MSSQL\BBEC_V4.mdf")
$RelocateData1 = New-Object "Microsoft.SqlServer.Management.Smo.RelocateFile,$assemblySqlServerSmoExtendedFullName"("BBI_DEF1", "Z:\MSSQL\BBEC_V4_1.ndf")
$RelocateData2 = New-Object "Microsoft.SqlServer.Management.Smo.RelocateFile,$assemblySqlServerSmoExtendedFullName"("BBI_DEF2", "Z:\MSSQL\BBEC_V4_2.ndf")  
$RelocateData3 = New-Object "Microsoft.SqlServer.Management.Smo.RelocateFile,$assemblySqlServerSmoExtendedFullName"("BBI_DEF3", "Z:\MSSQL\BBEC_V4_3.ndf")
$RelocateData4 = New-Object "Microsoft.SqlServer.Management.Smo.RelocateFile,$assemblySqlServerSmoExtendedFullName"("BBI_DEF4", "Z:\MSSQL\BBEC_V4_4.ndf")
$RelocateData5 = New-Object "Microsoft.SqlServer.Management.Smo.RelocateFile,$assemblySqlServerSmoExtendedFullName"("BBI_IDX1", "Z:\MSSQL\BBEC_V4_5.ndf")
$RelocateData6 = New-Object "Microsoft.SqlServer.Management.Smo.RelocateFile,$assemblySqlServerSmoExtendedFullName"("BBI_IDX2", "Z:\MSSQL\BBEC_V4_6.ndf")
$RelocateData7 = New-Object "Microsoft.SqlServer.Management.Smo.RelocateFile,$assemblySqlServerSmoExtendedFullName"("BBI_IDX3", "Z:\MSSQL\BBEC_V4_7.ndf")
$RelocateData8 = New-Object "Microsoft.SqlServer.Management.Smo.RelocateFile,$assemblySqlServerSmoExtendedFullName"("BBI_IDX4", "Z:\MSSQL\BBEC_V4_8.ndf")
$RelocateData9 = New-Object "Microsoft.SqlServer.Management.Smo.RelocateFile,$assemblySqlServerSmoExtendedFullName"("BBI_OUTPUT1", "Z:\MSSQL\BBEC_V4_9.ndf")
$RelocateData10 = New-Object "Microsoft.SqlServer.Management.Smo.RelocateFile,$assemblySqlServerSmoExtendedFullName"("BBI_OUTPUT2", "Z:\MSSQL\BBEC_V4_10.ndf")
$RelocateData11 = New-Object "Microsoft.SqlServer.Management.Smo.RelocateFile,$assemblySqlServerSmoExtendedFullName"("BBI_OUTPUT3", "Z:\MSSQL\BBEC_V4_11.ndf")
$RelocateData12 = New-Object "Microsoft.SqlServer.Management.Smo.RelocateFile,$assemblySqlServerSmoExtendedFullName"("BBI_OUTPUT4", "Z:\MSSQL\BBEC_V4_12.ndf")
$RelocateData13 = New-Object "Microsoft.SqlServer.Management.Smo.RelocateFile,$assemblySqlServerSmoExtendedFullName"("BBI_AUDIT1", "Z:\MSSQL\BBEC_V4_13.ndf")
$RelocateData14 = New-Object "Microsoft.SqlServer.Management.Smo.RelocateFile,$assemblySqlServerSmoExtendedFullName"("BBI_AUDIT2", "Z:\MSSQL\BBEC_V4_14.ndf")
$RelocateData15 = New-Object "Microsoft.SqlServer.Management.Smo.RelocateFile,$assemblySqlServerSmoExtendedFullName"("BBI_AUDIT3", "Z:\MSSQL\BBEC_V4_15.ndf")
$RelocateData16 = New-Object "Microsoft.SqlServer.Management.Smo.RelocateFile,$assemblySqlServerSmoExtendedFullName"("BBI_AUDIT4", "Z:\MSSQL\BBEC_V4_16.ndf")
$RelocateData17 = New-Object "Microsoft.SqlServer.Management.Smo.RelocateFile,$assemblySqlServerSmoExtendedFullName"("BBI_TRAN1", "Z:\MSSQL\BBEC_V4_17.ndf")
$RelocateData18 = New-Object "Microsoft.SqlServer.Management.Smo.RelocateFile,$assemblySqlServerSmoExtendedFullName"("BBI_TRAN2", "Z:\MSSQL\BBEC_V4_18.ndf")
$RelocateData19 = New-Object "Microsoft.SqlServer.Management.Smo.RelocateFile,$assemblySqlServerSmoExtendedFullName"("BBI_TRAN3", "Z:\MSSQL\BBEC_V4_19.ndf")
$RelocateData20 = New-Object "Microsoft.SqlServer.Management.Smo.RelocateFile,$assemblySqlServerSmoExtendedFullName"("BBI_TRAN4", "Z:\MSSQL\BBEC_V4_20.ndf")
$RelocateData21 = New-Object "Microsoft.SqlServer.Management.Smo.RelocateFile,$assemblySqlServerSmoExtendedFullName"("BBI_TRANIDX1", "Z:\MSSQL\BBEC_V4_21.ndf")
$RelocateData22 = New-Object "Microsoft.SqlServer.Management.Smo.RelocateFile,$assemblySqlServerSmoExtendedFullName"("BBI_TRANIDX2", "Z:\MSSQL\BBEC_V4_22.ndf")
$RelocateData23 = New-Object "Microsoft.SqlServer.Management.Smo.RelocateFile,$assemblySqlServerSmoExtendedFullName"("BBI_TRANIDX3", "Z:\MSSQL\BBEC_V4_23.ndf")
$RelocateData24 = New-Object "Microsoft.SqlServer.Management.Smo.RelocateFile,$assemblySqlServerSmoExtendedFullName"("BBI_TRANIDX4", "Z:\MSSQL\BBEC_V4_24.ndf")
$RelocateData25 = New-Object "Microsoft.SqlServer.Management.Smo.RelocateFile,$assemblySqlServerSmoExtendedFullName"("BBI_BIO1", "Z:\MSSQL\BBEC_V4_25.ndf")
$RelocateData26 = New-Object "Microsoft.SqlServer.Management.Smo.RelocateFile,$assemblySqlServerSmoExtendedFullName"("BBI_BIO2", "Z:\MSSQL\BBEC_V4_26.ndf")
$RelocateData27 = New-Object "Microsoft.SqlServer.Management.Smo.RelocateFile,$assemblySqlServerSmoExtendedFullName"("BBI_BIOIDX1", "Z:\MSSQL\BBEC_V4_27.ndf")
$RelocateData28 = New-Object "Microsoft.SqlServer.Management.Smo.RelocateFile,$assemblySqlServerSmoExtendedFullName"("BBI_BIOIDX2", "Z:\MSSQL\BBEC_V4_28.ndf")  
  
$RelocateLog = New-Object "Microsoft.SqlServer.Management.Smo.RelocateFile,$assemblySqlServerSmoExtendedFullName"("BBI_LOG1", "Z:\MSSQL\BBEC_V4_29.ldf")

IF ($lastFull.LastWriteTime -gt $lastDiff.LastWriteTime)
{
Write-host "Differential Older than Last Full Backup"

Restore-SqlDatabase -ServerInstance UT-CRMSQL-02 -database BBECStage_V43 -BackupFile $FullBackup -ReplaceDatabase -RelocateFile @($RelocateData, $RelocateData1,$RelocateData2,$RelocateData3,$RelocateData4,$RelocateData5,$RelocateData6,
$RelocateData7, $RelocateData8, $RelocateData9, $RelocateData10, $relocateData11, $Relocatedata12, $RelocateData13, $RelocateData14, $RelocateData15, $RelocateData16, $RelocateData17, $RelocateData18, $RelocateData19, $RelocateData20,
$RelocateData21, $RelocateData22, $RelocateData23, $RelocateData24, $RelocateData25, $RelocateData26, $RelocateData27, $RelocateData28, $RelocateLog)


}

else 
{



Restore-SqlDatabase -ServerInstance UT-CRMSQL-02 -database BBECStage_V43 -BackupFile $FullBackup -ReplaceDatabase -NoRecovery -RelocateFile @($RelocateData1, $RelocateData1,$RelocateData2,$RelocateData3,$RelocateData4,$RelocateData5,$RelocateData6,
$RelocateData7, $RelocateData8, $RelocateData9, $RelocateData10, $relocateData11, $Relocatedata12, $RelocateData13, $RelocateData14, $RelocateData15, $RelocateData16, $RelocateData17, $RelocateData18, $RelocateData19, $RelocateData20,
$RelocateData21, $RelocateData22, $RelocateData23, $RelocateData24, $RelocateData25, $RelocateData26, $RelocateData27, $RelocateData28, $RelocateLog)

Restore-SqlDatabase -ServerInstance UT-CRMSQL-02 -Database BBECStage_V43 -BackupFile $DiffBackup


}
