# CONSTANTS
$GITHUB_URL = "https://raw.githubusercontent.com/Henchway/Choco-avd/main"
$TempDirectory = ".\temp\"
$LocalJsonPath = Load-FileFromGithub "apps.json"

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
    if (-not (Test-Path $LocalFilePath)) {
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
    }
    else {
        Write-Host "Using cached file: $FileName"
    }
    return $LocalFilePath
}

# Enable TLS 1.2 (required for connecting to Chocolatey repository)
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Check if running as Administrator
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "You need to run this script as Administrator!" -ForegroundColor Red
    exit 1
}

# Install Chocolatey if not already installed
if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
    Write-Host "Installing Chocolatey..." -ForegroundColor Green
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.WebRequest]::DefaultWebProxy.Credentials = [System.Net.CredentialCache]::DefaultCredentials
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
}

# Load and parse the JSON file
try {
    $Apps = Get-Content -Path $LocalJsonPath -Raw | ConvertFrom-Json
}
catch {
    Write-Host "Error loading apps.json" -ForegroundColor Red
    exit 1
}

# Loop through each app and install it
foreach ($App in $Apps) {
    Write-Host "Installing $($App.name)..." -ForegroundColor Green
    $InstallCommand = "choco install $($App.name) -y --no-progress"
    
    if ($App.version) {
        $InstallCommand += " --version $($App.version)"
    }
    if ($App.argumentString) {
        $InstallCommand += " --install-arguments='$($App.argumentString)'"
    }

    # If pre-script is specified, run it
    if ($App.pre_script) {
        $PreScriptPath = Load-FileFromGithub $App.pre_script
        powershell.exe -File $PreScriptPath -GITHUB_URL $($GITHUB_URL)
    }

    Write-Host "Executing command: $InstallCommand"
    powershell.exe -Command $InstallCommand
}

Write-Host "All applications have been installed successfully." -ForegroundColor Green
