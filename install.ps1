# Enable TLS 1.2 (required for connecting to Chocolatey repository)
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Check if running as Administrator
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "You need to run this script as Administrator!" -ForegroundColor Red
    exit
}

# Install Chocolatey
Write-Host "Installing Chocolatey..." -ForegroundColor Green
Set-ExecutionPolicy Bypass -Scope Process -Force; `
    [System.Net.WebRequest]::DefaultWebProxy.Credentials = [System.Net.CredentialCache]::DefaultCredentials; `
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))


    

# # Refresh environment variables
# Write-Host "Refreshing environment variables..." -ForegroundColor Green
# Import-Module $env:ChocolateyInstall\helpers\chocolateyProfile.psm1
# refreshenv

# Define the URL of the CSV file in the GitHub repository
$csvUrl = "https://raw.githubusercontent.com/Henchway/Choco-avd/main/apps.csv"

# Define the path to save the CSV file locally
$localCsvPath = "$PSScriptRoot\apps.csv"

# Download the CSV file
Write-Host "Downloading CSV from $csvUrl..."
Invoke-WebRequest -Uri $csvUrl -OutFile $localCsvPath

# Load the CSV file
$apps = Import-Csv -Path $localCsvPath

# Loop through each app and print the app and version
foreach ($app in $apps) {
    Write-Host "App: $($app.name), Version: $($app.version)"
}

foreach ($app in $apps) {
    Write-Host "Installing $app..." -ForegroundColor Green
    if ($app.version -eq "") {
        choco install $app.name -y --version $app.version
    }
    else {
        choco install $app.name -y
    }
}

Write-Host "All applications have been installed successfully." -ForegroundColor Green
