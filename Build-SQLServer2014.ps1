Function Build-SQLServer2014
{



process
	{

    Try
        {


    CD "\\bhf-storage02\ServerTeam\ISOs Installs and Service Packs\SQL\Automation\2014"


    ."\\bhf-storage02\ServerTeam\ISOs Installs and Service Packs\SQL\Automation\2014\Create-SQLPaths.ps1"
    create-SQLPath -SQLService 'svcPD01B_SQL' -SQLAgent 'svcPD01B_AGT'

    #Install SQL Server
    ."\\bhf-storage02\ServerTeam\ISOs Installs and Service Packs\SQL\Automation\2014\Install-SQLServer.ps1"
    Install-SQLServer -ComputerName $env:COMPUTERNAME -InstanceName 'SQL01B' -SQLAccount 'BHF-ADS\svcPD01B_SQL' -SQLAgent 'BHF-ADS\svcPD01B_AGT' -SQLPW 'RuK923/w#tkSm^H?' -AgtPW 'qtkkKq>CN[9U2FSb'


    #Install the DBA Tools module
    install-module dbaTools -Confirm:$false


    #Add SMO Library for SQL version 2014
    Write-Host "Adding SMO library for version $version"
    Add-Type -Path "D:\Program Files (x86)\Microsoft SQL Server\120\SDK\Assemblies\Microsoft.SqlServer.Smo.dll"

    Copy-Item 'D:\Program Files (x86)\Microsoft SQL Server\120\Tools\PowerShell\Modules\SQLPS' 'C:\Windows\system32\WindowsPowerShell\v1.0\Modules' -Recurse


    #move master database
    ."\\bhf-storage02\ServerTeam\ISOs Installs and Service Packs\SQL\Automation\2014\Move-MasterDB.ps1"

    Change-masterConfig -ComputerName 'BHF2-PD-SQL-01\SQL01B' -OldData 'F:\MSSQL\Data\MSSQL12.SQL01B\MSSQL\DATA\master.mdf' -NewData 'F:\MSSQL\Data\master.mdf' -oldLog 'F:\MSSQL\Data\MSSQL12.SQL01B\MSSQL\DATA\mastlog.ldf' -NewLog 'M:\MSSQL\LOGS\mastlog.ldf' -oldError 'F:\MSSQL\Data\MSSQL12.SQL01B\MSSQL\Log\ERRORLOG' -NewError 'F:\MSSQL\Log\ERRORLOG'

    Move-Master -ComputerName 'BHF2-PD-SQL-01\SQL01B' -OldData 'F:\MSSQL\Data\MSSQL12.SQL01B\MSSQL\DATA\master.mdf' -NewData 'F:\MSSQL\Data\master.mdf' -oldLog 'F:\MSSQL\Data\MSSQL12.SQL01B\MSSQL\DATA\mastlog.ldf' -NewLog 'M:\MSSQL\LOGS\mastlog.ldf'


    #Move Model and MSDB databases
    ."\\bhf-storage02\ServerTeam\ISOs Installs and Service Packs\SQL\Automation\2014\Move-ModelMSDB.ps1"
    change-modelMSDB -ComputerName 'BHF2-PD-SQL-01\SQL01B' -OldData 'F:\MSSQL\Data\MSSQL12.SQL01B\MSSQL\DATA\' -NewData 'F:\MSSQL\Data' -oldLog 'F:\MSSQL\Data\MSSQL12.SQL01B\MSSQL\DATA\' -NewLog 'M:\MSSQL\LOGS'
    move-Modelmsdb -ComputerName 'BHF2-PD-SQL-01\SQL01B' -OldData 'F:\MSSQL\Data\MSSQL12.SQL01B\MSSQL\DATA\' -NewData 'F:\MSSQL\Data' -oldLog 'F:\MSSQL\Data\MSSQL12.SQL01B\MSSQL\DATA\' -NewLog 'M:\MSSQL\LOGS'


    #Change Temp DB
    ."\\BHF-STORAGE02\ServerTeam\ISOs Installs and Service Packs\SQL\Automation\2014\Change-TempDb.ps1"
    change-tempDB -ComputerName 'BHF2-PD-SQL-01\SQL01B' -datasize 20971520KB -logsize 100000KB -FileGrowth 200MB


    #Change Agent Log file path
    ."\\bhf-storage02\ServerTeam\ISOs Installs and Service Packs\SQL\Automation\2014\Change-AgentLogFilePath.ps1"
    change-AgentlogFilePath -ComputerName 'BHF2-PD-SQL-01\SQL01B' -Source '\\bhf-storage02\ServerTeam\ISOs Installs and Service Packs\SQL\Automation\2014'

    #Run Post Deployment script for best practices
    ."\\bhf-storage02\ServerTeam\ISOs Installs and Service Packs\SQL\Automation\2014\Configure-SQLServer.ps1"
    Configure-SQLServer -ComputerName 'BHF2-PD-SQL-01\SQL01B' -Source '\\bhf-storage02\ServerTeam\ISOs Installs and Service Packs\SQL\Automation\2014'

    #Create Tools Monitoring Database.
    ."\\bhf-storage02\ServerTeam\ISOs Installs and Service Packs\SQL\ToolsDB\ps\Create-ToolsDb-Silent.ps1"
    Create-toolsDB  -ComputerName 'BHF2-PD-SQL-01\SQL01B' –Database ‘Tools’ –Source ‘\\bhf-storage02\ServerTeam\ISOs Installs and Service Packs\SQL\ToolsDB’ –SA ‘C4rb0n’


    }

    CATCH {

            $ErrorMessage = $_.Exception.Message
            Write-Error -Message $ErrorMessage

           }


    }


}