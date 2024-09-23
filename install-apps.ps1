# CONSTANTS
$REPO_NAME = "Choco-avd"
$GITHUB_REPO = "https://github.com/Henchway/Choco-avd.git"

# Check if running as Administrator
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "[FATAL] You need to run this script as Administrator!Exiting script." -ForegroundColor Red
    exit 1
}

# Load Git repo
if (-not(Test-Path ".\$REPO_NAME")) {
    git clone $GITHUB_REPO
}
Set-Location $REPO_NAME

# Import functions module
Import-Module "./functions.psm1"

# Parse JSON file
try {
    $Apps = Get-Content -Path "./apps.json" -Raw | ConvertFrom-Json
}
catch {
    Write-Host "[FATAL] Failed to load apps.json, error message: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Set counters for successful installation
$TotalAppCount = $Apps | Measure-Object | Select-Object -ExpandProperty Count
$SuccessfulAppCount = $TotalAppCount

# Loop through each app and install it
for ($i = 0; $i -lt $Apps.Count; $i++) {
    $App = $Apps[$i]
    Write-Host "Attempting to install app with following parameters: $App"
    Write-Host "Installing $($App.name)..." -ForegroundColor Green

    if ($App.installType -eq 'choco') {
        try {
            Install-WithChoco($App)            
        }
        catch {
            Write-Host "Encountered error: $_"
            $SuccessfulAppCount -= 1
        }
    }
    else {
        try {
            $pathExists = Test-Path $App.customInstallScript
            Write-Host "The path for $($App.name) exists: $pathExists"
            powershell.exe -File $App.customInstallScript
        } 
        catch {
            Write-Host "Encountered error: $_"
            $SuccessfulAppCount -= 1
        }
    }
}


Write-Host "[INFO] Successfully installed $($SuccessfulAppCount)/$($TotalAppCount) applications."
# Move back to root folder
Set-Location ".."

# Uninstall Chocolatey
Uninstall-Chocolatey

if ($SuccessfulAppCount -lt $TotalAppCount) {
    Write-Host "[FATAL] Not all apps were installed successfully, failing script."  -ForegroundColor Red
    exit 1
}
