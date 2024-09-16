# Enable TLS 1.2 (required for connecting to Chocolatey repository)
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Check if running as Administrator
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))
{
    Write-Host "You need to run this script as Administrator!" -ForegroundColor Red
    exit
}

# Install Chocolatey
Write-Host "Installing Chocolatey..." -ForegroundColor Green
Set-ExecutionPolicy Bypass -Scope Process -Force; `
    [System.Net.WebRequest]::DefaultWebProxy.Credentials = [System.Net.CredentialCache]::DefaultCredentials; `
    iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# Refresh environment variables
Write-Host "Refreshing environment variables..." -ForegroundColor Green
RefreshEnv

# Install applications
$packages = @(
    "7zip",
    "googlechrome",
    "filezilla",
    "putty"
)

foreach ($package in $packages) {
    Write-Host "Installing $package..." -ForegroundColor Green
    choco install $package -y
}

Write-Host "All applications have been installed successfully." -ForegroundColor Green
