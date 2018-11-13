function create-SQLPath
{

#This function creates all necessary SQL paths and adds service account permissions to these folders

[CmdletBinding()]
	param
	(   
    [Parameter(Mandatory)]
	[ValidateNotNullOrEmpty()]
	[string]$SQLService,
    
    [Parameter(Mandatory)]
	[ValidateNotNullOrEmpty()]
	[string]$SQLAgent
    )

 process
	{

    Try
    {


    New-Item -ItemType Directory -Force -Path F:\MSSQL\Data
    New-Item -ItemType Directory -Force -Path F:\MSSQL\Log 
    New-Item -ItemType Directory -Force -Path F:\DBA\Logs
    New-Item -ItemType Directory -Force -Path M:\MSSQL\Logs
    New-Item -ItemType Directory -Force -Path U:\MSSQL\Data

    #Create network share for maintenance logs


    New-SMBShare –Name “DBA” –Path “E:\DBA"




    $DataFolders = Get-ChildItem F:\
    $LogFolders = Get-ChildItem M:\
    $TempDBFolders = Get-ChildItem U:\

    $Users = @($SQLService,$SQLAgent)

    foreach ($user in $Users)

        {


        Grant-SmbShareAccess -Name "DBA" -AccountName $User -AccessRight Full -Confirm:$false

        foreach ($DataFolder in $DataFolders) {

        $Path = $DataFolder.FullName
        $Acl = Get-Acl $Path
        $permission = "BHF-ADS\$user", "FullControl","ContainerInherit,ObjectInherit", "None", "Allow"
        $Ar = New-Object System.Security.AccessControl.FileSystemAccessRule $permission
        $Acl.SetAccessRule($Ar)
        $acl | Set-Acl -path $Path -Confirm:$false
        }

        
        foreach ($LogFolder in $LogFolders) {
        $Path = $LogFolder.FullName
        $Acl = Get-Acl $Path
        $permission = "BHF-ADS\$user", "FullControl","ContainerInherit,ObjectInherit", "None", "Allow"
        $Ar = New-Object System.Security.AccessControl.FileSystemAccessRule $permission
        $Acl.SetAccessRule($Ar)
        $acl | Set-Acl -path $Path -Confirm:$false
        }

        foreach ($TempDbFolder in $TempDBFolders) {
        $Path = $TempDBFolder.FullName
        $Acl = Get-Acl $Path
        $permission = "BHF-ADS\$user", "FullControl","ContainerInherit,ObjectInherit", "None", "Allow"
        $Ar = New-Object System.Security.AccessControl.FileSystemAccessRule $permission
        $Acl.SetAccessRule($Ar)
        $acl | Set-Acl -path $Path -Confirm:$false
        }
        
        }

        

    }

    catch

    {
    $ErrorMessage = $_.Exception.Message
    Write-Error -Message $ErrorMessage
    }

    }

}


