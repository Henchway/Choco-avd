# CONSTANTS
$REPO_NAME = "Choco-avd"
$GITHUB_REPO = "git@github.com:Henchway/$($REPO_NAME).git"

# Enable TLS 1.2 (required for connecting to Chocolatey repository)
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Check if running as Administrator
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "[FATAL] You need to run this script as Administrator! Exiting script." -ForegroundColor Red
    exit 1
}

# Install Chocolatey if not already installed
Install-Chocolatey

# Install git
$GitInstallCommand = "choco install git -y"
if ($env:TERM_PROGRAM -eq "vscode") {
    $GitInstallCommand += " --noop"
}
powershell.exe -Command $GitInstallCommand

# Load Git repo
if (Test-Path ".\$REPO_NAME") {
    Write-Host "Deleting repo folder"
    Remove-Item -Recurse -Force .\$REPO_NAME
}
else {
    Write-Host "Repo does not exist, continuing."
}
git clone $GITHUB_REPO
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
foreach ($App in $Apps) {
    Write-Host "Installing $($App.name)..." -ForegroundColor Green

    if ($App.installType -eq 'choco') {
        try {
            Install-WithChoco($App)
        }
        catch {
            $SuccessfulAppCount -= 1
        }
    }
    else {
        
    }

}

Write-Host "[INFO] Successfully installed $($SuccessfulAppCount)/$($TotalAppCount) applications."
if ($SuccessfulAppCount -lt $TotalAppCount) {
    Write-Host "[FATAL] Not all apps were installed successfully, failing script."
    exit 1
}

# Uninstall Chocolatey
Uninstall-Chocolatey
