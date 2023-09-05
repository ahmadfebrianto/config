function Get-IP {
    Get-NetIPAddress -AddressFamily IPV4 | Select-Object InterfaceAlias, IPAddress, InterfaceIndex
}

function Remove-RF {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true, Position=0)]
        [ValidateNotNullOrEmpty()]
        [string]$Path
    )

    Process {
        Remove-Item -Path $Path -Force -Recurse
    }
}

function Get-WiFiPassword {
    $isElevated = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

    if (-not $isElevated) {
        Write-Host "This function requires administrative privileges to access WiFi passwords. Please run PowerShell as an administrator."
        return
    }

    (netsh wlan show profiles) | Select-String "\:(.+)$" | ForEach-Object {
        $name = $_.Matches.Groups[1].Value.Trim()
        $_
    } | ForEach-Object {
        (netsh wlan show profile name="$name" key=clear)
    }  | Select-String "Key Content\W+\:(.+)$" | ForEach-Object {
        $pass = $_.Matches.Groups[1].Value.Trim()
        $_
    } | ForEach-Object {
        [PSCustomObject]@{ PROFILE_NAME = $name; PASSWORD = $pass }
    } | Format-Table -AutoSize
}


function ClearReadlineHistory {
  $filePath = "$env:APPDATA\Microsoft\Windows\PowerShell\PSReadline\ConsoleHost_history.txt"
  if (Test-Path $filePath) {
    Remove-Item $filePath -Force -Recurse
  }
}

Set-Alias ip Get-IP
set-Alias rmrf Remove-RF
set-Alias wifipass Get-WiFiPassword
Set-Alias vi nvim
Set-PSReadLineOption -PredictionViewStyle ListView

ClearReadlineHistory
Invoke-Expression (&starship init powershell)
