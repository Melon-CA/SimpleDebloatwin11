# =========================
# Windows 11 Debloat Script (EN)
# =========================

# Admin check
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "Run as Administrator!" -ForegroundColor Red
    exit
}

Write-Host "Starting debloat..." -ForegroundColor Green

# =========================
# DARK MODE
# =========================
Write-Host "Enabling dark mode..."

New-ItemProperty -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize -Name AppsUseLightTheme -Value 0 -Type Dword -Force
New-ItemProperty -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize -Name SystemUsesLightTheme -Value 0 -Type Dword -Force

# =========================
# AUTO ACCENT COLOR
# =========================
Write-Host "Setting accent color..."

Set-ItemProperty -Path HKCU:\Software\Microsoft\Windows\DWM -Name ColorPrevalence -Value 1
Set-ItemProperty -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize -Name ColorPrevalence -Value 1

# =========================
# START MENU LEFT
# =========================
Write-Host "Aligning Start menu left..."

Set-ItemProperty -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name TaskbarAl -Value 0

# =========================
# REMOVE UWP APPS
# =========================
Write-Host "Removing UWP apps..."

$apps = @(
    "Microsoft.Windows.Photos"
    "Microsoft.ZuneMusic"
    "Microsoft.ZuneVideo"
    "Microsoft.BingWeather"
    "Microsoft.BingNews"
    "Microsoft.GetHelp"
    "Microsoft.Getstarted"
    "Microsoft.People"
    "Microsoft.WindowsFeedbackHub"
    "Microsoft.Todos"
    "Microsoft.MicrosoftStickyNotes"
    "Microsoft.SolitaireCollection"
    "Clipchamp.Clipchamp"
)

foreach ($app in $apps) {
    Get-AppxPackage -Name $app -AllUsers | Remove-AppxPackage -ErrorAction SilentlyContinue
    Get-AppxProvisionedPackage -Online | Where-Object DisplayName -EQ $app | Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue
}

# =========================
# REMOVE ONEDRIVE
# =========================
Write-Host "Removing OneDrive..."

taskkill /f /im OneDrive.exe 2>$null
Start-Sleep 2

$onedriveSetup = "$env:SystemRoot\SysWOW64\OneDriveSetup.exe"
if (Test-Path $onedriveSetup) {
    Start-Process $onedriveSetup "/uninstall" -NoNewWindow -Wait
}

Remove-Item "$env:UserProfile\OneDrive" -Recurse -Force -ErrorAction SilentlyContinue

# =========================
# REMOVE EDGE (UNSUPPORTED)
# =========================
Write-Host "Removing Edge (unsupported)..."

$edgePath = "C:\Program Files (x86)\Microsoft\Edge\Application"
if (Test-Path $edgePath) {
    $edgeExe = Get-ChildItem $edgePath -Recurse -Filter setup.exe | Select-Object -First 1
    if ($edgeExe) {
        Start-Process $edgeExe.FullName "--uninstall --system-level --force-uninstall" -Wait
    }
}

# =========================
# INSTALL APPS (WINGET)
# =========================
Write-Host "Installing apps via winget..."

if (Get-Command winget -ErrorAction SilentlyContinue) {
    winget install --id Google.Chrome -e --accept-source-agreements --accept-package-agreements
    winget install --id IrfanSkiljan.IrfanView -e --accept-source-agreements --accept-package-agreements
    winget install --id VideoLAN.VLC -e --accept-source-agreements --accept-package-agreements
} else {
    Write-Host "Winget not found!" -ForegroundColor Yellow
}

# =========================
# RESTART EXPLORER
# =========================
Write-Host "Restarting Explorer..."

Stop-Process -Name explorer -Force
Start-Process explorer

Write-Host "Done." -ForegroundColor Green
