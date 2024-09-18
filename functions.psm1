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

function Uninstall-Chocolatey {
    if (Get-Command choco -ErrorAction SilentlyContinue) {
        Write-Host "Uninstalling Chocolatey..." -ForegroundColor Yellow
        try {
            # Uninstall Chocolatey using the built-in uninstall command
            & "C:\ProgramData\chocolatey\choco.exe" uninstall chocolatey -y

            # Optionally remove the Chocolatey folder and registry keys
            Remove-Item -Recurse -Force "C:\ProgramData\chocolatey" -ErrorAction SilentlyContinue
            Remove-Item -Recurse -Force "$env:ChocolateyInstall" -ErrorAction SilentlyContinue

            # Clean up environment variables
            [System.Environment]::SetEnvironmentVariable('ChocolateyInstall', $null, [System.EnvironmentVariableTarget]::Machine)

            Write-Host "Chocolatey uninstalled successfully." -ForegroundColor Green
        }
        catch {
            Write-Host "[ERROR] Failed to uninstall Chocolatey." -ForegroundColor Red
        }
    }
    else {
        Write-Host "Chocolatey is not installed." -ForegroundColor Yellow
    }
}

function Install-WithChoco {
    param (
        [object]$App
    )
    $InstallCommand = "choco install $($App.name) -y --no-progress"

    # Ensures to not install any applications when running in vscode
    if ($env:TERM_PROGRAM -eq "vscode") {
        $InstallCommand += " --noop"
    }

    if ($App.chocoVersion) {
        $InstallCommand += " --version $($App.chocoVersion)"
    }
    if ($App.chocoArgumentString) {
        $InstallCommand += " --install-arguments='$($App.chocoArgumentString)'"
    }

    # If pre-script is specified, run it
    if ($App.chocoPreScript) {
        try {
            powershell.exe -File $App.chocoPreScript
        }
        catch {
            Write-Host "[ERROR] Failed to execute pre-script for app $($App.name), error message: $($_.Exception.Message)"  -ForegroundColor Red
        }
    }

    Write-Host "Executing command: $InstallCommand"
    try {
        powershell.exe -Command $InstallCommand
        
        $installedPackages = choco list --local-only
        if ($installedPackages -notcontains "$($App.name)") {
            throw
        }
        Write-Host "[INFO] Successfully installed $($App.name)"  -ForegroundColor Green
    }
    catch {
        Write-Host "[ERROR] Failed to install $($App.name), error message: $($_.Exception.Message)"  -ForegroundColor Red
        exit 1
    }
}

