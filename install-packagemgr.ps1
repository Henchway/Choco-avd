# Enable TLS 1.2 (required for connecting to Chocolatey repository)
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Check if running as Administrator
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "[FATAL] You need to run this script as Administrator! Exiting script." -ForegroundColor Red
    exit 1
}
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

# Install Chocolatey if not already installed
Install-Chocolatey

# Install git
$GitInstallCommand = "choco install git -y --no-progress"
if ($env:TERM_PROGRAM -eq "vscode") {
    $GitInstallCommand += " --noop"
}
Write-Host "Executing '$($GitInstallCommand)'"
powershell.exe -Command $GitInstallCommand


