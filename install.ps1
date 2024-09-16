# CONSTANTS
$GITHUB_URL="https://raw.githubusercontent.com/Henchway/Choco-avd/main"

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
$csvUrl = "$($GITHUB_URL)/apps.csv"

# Define the path to save the CSV file locally
$localCsvPath = ".\apps.csv"

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
    $installString = "choco install $($app.name) -y --no-progress --noop" 

    if ($app.pre_script -ne "") {
        powershell.exe  -c $installString
    }

    if ($app.version -ne "") {
        $installString += " --version $($app.version)"
    }
    if ($app.argumentString -ne "") {
        $installString += " --install-arguments='$($app.argumentString)'"
    }
    Write-Host "Executing the following command: '$installString'"
    powershell.exe -c $installString
}

Write-Host "All applications have been installed successfully." -ForegroundColor Green



function loadFileFromGithub {
    param (
        [string]$filePath
    )
    $invokeUrl = "$($GITHUB_URL)/$($filePath)"
    $fileName = ($filePath -split '/')[-1]
    Write-Host "Filename: $($fileName)"
    Invoke-WebRequest -Uri $invokeUrl -OutFile ".\$($fileName)"
    return $fileName
}