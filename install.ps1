# CONSTANTS
$REPO_NAME = "Choco-avd"
$GITHUB_REPO = "git@github.com:Henchway/$($REPO_NAME).git"

# Enable TLS 1.2 (required for connecting to Chocolatey repository)
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

function Install-Chocolatey {
    if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
        Write-Host "Installing Chocolatey..." -ForegroundColor Green
        Set-ExecutionPolicy Bypass -Scope Process -Force
        [System.Net.WebRequest]::DefaultWebProxy.Credentials = [System.Net.CredentialCache]::DefaultCredentials
        try {
            Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
            Write-Host "Chocolatey installation completed." -ForegroundColor Green
        }
        catch {
            Write-Host "[FATAL] Failed to install Chocolatey. Exiting script." -ForegroundColor Red
            exit 1
        }
    }
    else {
        Write-Host "Chocolatey is already installed." -ForegroundColor Yellow
    }
}

# Check if running as Administrator
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "[FATAL] You need to run this script as Administrator! Exiting script." -ForegroundColor Red
    exit 1
}

# Install Chocolatey if not already installed
Install-Chocolatey

# Install git
$GitInstallCommand = "choco install git -y --no-progress"
if ($env:TERM_PROGRAM -eq "vscode") {
    $GitInstallCommand += " --noop"
}
powershell.exe -Command $GitInstallCommand

# Load Git repo
if (Test-Path ".\$REPO_NAME") {
    Write-Host "Deleting repo folder"
    Remove-Item -Recurse -Force .\$REPO_NAME
}
git clone $GITHUB_REPO
Set-Location $REPO_NAME

# Import functions module
Import-Module "./functions.psm1"

# Parse YAML file
Install-Module -Name powershell-yaml -Force -Confirm:$false

try {
    $Apps = Get-Content -Path "./apps.yaml" -Raw | ConvertFrom-Yaml
}
catch {
    Write-Host "[FATAL] Failed to load apps.yaml, error message: $($_.Exception.Message)" -ForegroundColor Red
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
        powershell.exe -File $App.customInstallScript
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


