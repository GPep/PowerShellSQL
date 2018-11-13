CD "\\bhf-storage02\ServerTeam\ISOs Installs and Service Packs\SQL\Automation\2016"


."\\bhf-storage02\ServerTeam\ISOs Installs and Service Packs\SQL\Automation\2016\Create-SQLPaths.ps1"
create-SQLPath -SQLService 'Enter SQL Service Account' -SQLAgent 'Enter Agent Account'

#.\apply account local policies
#Enter Command Here

#Install SQL Server
."\\bhf-storage02\ServerTeam\ISOs Installs and Service Packs\SQL\Automation\2016\\Install-SQLServer.ps1"
Install-SQLServer -ComputerName $env:COMPUTERNAME -PackagePath "\\bhf-storage02\ServerTeam\ISOs Installs and Service Packs\SQL\2014" -PackageName "en_sql_server_2016_developer_x64_dvd_8777069.iso" -InstanceName 'NewInstance' -SQLAccount 'EnterAccountName Here' -SQLAgent 'Enter Agent Account Here'


#Install the DBA Tools module
install-module dbaTools -Confirm:$false


#Add SMO Library for SQL version 2014
Write-Host "Adding SMO library for version $version"
Add-Type -Path "D:\Program Files\Microsoft SQL Server\120\SDK\Assemblies\Microsoft.SqlServer.Smo.dll"


#move master database
."\\bhf-storage02\ServerTeam\ISOs Installs and Service Packs\SQL\Automation\2014\Move-MasterDB.ps1"

Change-masterConfig -OldData 'F:\MSSQL\Data\MSSQL12.MSSQLSERVER\MSSQL\DATA\master.mdf' -NewData 'F:\MSSQL\Data\master.mdf' -oldLog 'F:\MSSQL\Data\MSSQL12.MSSQLSERVER\MSSQL\DATA\mastlog.ldf'
-NewLog 'M:\MSSQL\LOGS\mastlog.ldf' -oldError 'C:\Wrong place\log\ERRORLOG' -NewError 'F:\MSSQL\Log\ERRORLOG'

Move-Master -OldData 'F:\MSSQL\Data\MSSQL12.MSSQLSERVER\MSSQL\DATA\master.mdf' -NewData 'F:\MSSQL\Data\master.mdf' -oldLog 'F:\MSSQL\Data\MSSQL12.MSSQLSERVER\MSSQL\DATA\mastlog.ldf'
-NewLog 'M:\MSSQL\LOGS\mastlog.ldf'


#Move Model and MSDB databases
."\\bhf-storage02\ServerTeam\ISOs Installs and Service Packs\SQL\Automation\2014\Move-ModelMSDB.ps1"
change-modelMSDB -OldData 'C:\Wrong Place' -NewData 'F:\MSSQL\Data' -oldLog 'C:\WrongPlace' -NewLog 'M:\MSSQL\LOGS'
move-Modelmsdb -OldData 'C:\Wrong Place' -NewData 'F:\MSSQL\Data' -oldLog 'C:\WrongPlace' -NewLog 'M:\MSSQL\LOGS'


#Change Temp DB
."\\bhf-storage02\ServerTeam\ISOs Installs and Service Packs\SQL\Automation\2014\ChangeTempDb.ps1"
change-tempDB -datasize 900000KB -logsize 100000KB -FileGrowth 200MB


#Change Agent Log file path
."\\bhf-storage02\ServerTeam\ISOs Installs and Service Packs\SQL\Automation\2014\ChangeAgentLogFilePath.ps1"
change-AgentlogFilePath 

#Run Post Deployment script for best practices
."\\bhf-storage02\ServerTeam\ISOs Installs and Service Packs\SQL\Automation\2014\Configure-SQLServer.ps1"
Configure-SQLServer -ComputerName $env:COMPUTERNAME

#Create Tools Monitoring Database.
."\\bhf-storage02\ServerTeam\ISOs Installs and Service Packs\SQL\ToolsDB\ps\Create-ToolsDb-Silent.ps1"
Create-toolsDB  -ComputerName $env:ComputerName –Database ‘Tools’ –Source ‘\\bhf-storage02\ServerTeam\ISOs Installs and Service Packs\SQL\ToolsDB’ –SA ‘C4rb0n’


#.\Install-SQLSP
#Enter  Command here

#.\Install-SQLCU
#Enter Command here