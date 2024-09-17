# CONSTANTS
$GITHUB_URL = "https://raw.githubusercontent.com/Henchway/Choco-avd/main"
$TempDirectory = ".\temp\"

# Ensure temp directory exists
if (-not (Test-Path $TempDirectory)) {
    New-Item -Path $TempDirectory -ItemType Directory | Out-Null
}

# Function to download file from GitHub
function Load-FileFromGithub {
    param (
        [string]$FilePath
    )
    $FileName = ($FilePath -split '/')[-1]
    $LocalFilePath = "$TempDirectory$FileName"
    
    # Check if file already exists in temp directory
    try {
        $UniquenessParameter = [guid]::NewGuid()
        $InvokeUrl = "$($GITHUB_URL)/$($FilePath)?token=$($UniquenessParameter)"
        Invoke-WebRequest -Uri $InvokeUrl -OutFile $LocalFilePath -ErrorAction Stop
        Write-Host "Downloaded: $FileName"
    }
    catch {
        Write-Host "Error downloading $FileName from $InvokeUrl" -ForegroundColor Red
        exit 1
    }
    return $LocalFilePath
}

# Enable TLS 1.2 (required for connecting to Chocolatey repository)
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Check if running as Administrator
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "[FATAL] You need to run this script as Administrator! Exiting script." -ForegroundColor Red
    exit 1
}

# Install Chocolatey if not already installed
if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
    Write-Host "Installing Chocolatey..." -ForegroundColor Green
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.WebRequest]::DefaultWebProxy.Credentials = [System.Net.CredentialCache]::DefaultCredentials
    try {
        Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    }
    catch {
        Write-Host "[FATAL] Failed to install Chocolatey. Exiting script."  -ForegroundColor Red
        exit 1
    }
}

# Load and parse the JSON file
$LocalJsonPath = Load-FileFromGithub "apps.json"
try {
    $Apps = Get-Content -Path $LocalJsonPath -Raw | ConvertFrom-Json
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
    $InstallCommand = "choco install $($App.name) -y --no-progress"
    
    # Ensures to not install any applications when running in vscode
    if ($env:TERM_PROGRAM -eq "vscode") {
        $InstallCommand += " --noop"
    }

    if ($App.version) {
        $InstallCommand += " --version $($App.version)"
    }
    if ($App.argumentString) {
        $InstallCommand += " --install-arguments='$($App.argumentString)'"
    }

    # If pre-script is specified, run it
    if ($App.pre_script) {
        $PreScriptPath = Load-FileFromGithub $App.pre_script
        try {
            powershell.exe -File $PreScriptPath -GITHUB_URL $($GITHUB_URL)
        }
        catch {
            Write-Host "[ERROR] Failed to execute pre-script for app $($App.name), error message: $($_.Exception.Message)"  -ForegroundColor Red
        }
    }

    Write-Host "Executing command: $InstallCommand"
    try {
        powershell.exe -Command $InstallCommand
        Write-Host "[INFO] Successfully installed $($App.name)"  -ForegroundColor Green
    }
    catch {
        Write-Host "[ERROR] Failed to install $($App.name), error message: $($_.Exception.Message)"  -ForegroundColor Red
        $SuccessfulAppCount -= 1
    }
}

Write-Host "[INFO] Successfully installed $($SuccessfulAppCount)/$($TotalAppCount) applications."
if ($SuccessfulAppCount -lt $TotalAppCount) {
    Write-Host "[FATAL] Not all apps were installed successfully, failing script."
    exit 1
}

