import-module webadministration

iisreset.exe /stop #stop IIS

#===================================================================================
$IISSite ="C:\inetpub\wwwroot"
$HIS = "C:\inetpub\wwwroot\HISWeb"
$SourcePath = "C:\HIS 1.1.2.0\Application"
$DestinationPath  = "C:\inetpub\wwwroot\HISWeb"
$AppName ="HISWeb"
$MainSiteName = "HIS"
$AppPoolName="HISWeb Pool"
$IISPath = "IIS:\Sites\$MainSiteName\$AppName"
$PoolUser= "IPC\jenishb"
$PoolPassword ="Nov#2022"
#===================================================================================

#1. AppPool

 if(Test-Path IIS:\AppPools\$AppPoolName)
    {
        Write-Host "AppPool $AppPoolName is already there"
    }
    else
    {
        Write-Host "AppPool $AppPoolName is not present"
        Write-Host "Creating new AppPool $AppPoolName"
        New-WebAppPool "$AppPoolName" -Force
        Set-ItemProperty -Path IIS:\AppPools\"$AppPoolName" managedRuntimeVersion "v4.0"
        Set-ItemProperty ("IIS:\AppPools\$AppPoolName") -Name processModel.idleTimeout -value ( [TimeSpan]::FromMinutes(1440))
        Set-ItemProperty ("IIS:\AppPools\$AppPoolName") -Name processModel.startupTimeLimit -Value ( [TimeSpan]::FromSeconds(900))
		Set-ItemProperty ("IIS:\AppPools\$AppPoolName") -Name "processModel.loadUserProfile" -Value "False"
        Set-ItemProperty ("IIS:\AppPools\$AppPoolName") -Name processModel -value @{userName="$PoolUser";password="$PoolPassword";identitytype=3}
    }

#====================================================================================================================================================================
#2. Copy the Application 

    Write-Host "To see if folder [$HIS]  exists"
    if (test-path -Path $HIS) { 
        Write-Host "Web path exists!" 

        Get-ChildItem "$IISSite\*HIS*.zip" -Recurse -File | Remove-Item -Force

        Compress-Archive -Path $HIS -DestinationPath ($HIS + (get-date -Format MMddyyyy) + '.zip')

        Remove-Item -Path $HIS -Recurse -exclude Web.config -Force
  
        robocopy $SourcePath $DestinationPath /MIR /NFL /NDL /TEE /NP /XF web.config

    } else {
        Write-Host "Path doesn't exist."
        If(!(test-path $HIS))
        {
            Get-ChildItem "$IISSite\*HIS*.zip" -Recurse -File | Remove-Item -Force
            New-Item -ItemType Directory -Force -Path $HIS

        }

        robocopy $SourcePath $DestinationPath /MIR /NFL /NDL /TEE /NP

    }
#========================================================================================================================================
#3 Creating site

    if (Test-Path $IISPath) 
    {
      Write-Host "$Site exists." 
      Remove-WebApplication -Name $AppName -Site $MainSiteName
    } 

    Write-Host "Creating site $Site " 
    New-WebApplication -Name $AppName -Site $MainSiteName -PhysicalPath $HIS -ApplicationPool $AppPoolName

iisreset.exe /start #start IIS

#==========================================================================================================================================