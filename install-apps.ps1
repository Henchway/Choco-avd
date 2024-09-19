# CONSTANTS
$REPO_NAME = "Choco-avd"
$GITHUB_REPO = "https://github.com/Henchway/Choco-avd.git"

# Check if running as Administrator
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "[FATAL] You need to run this script as Administrator! Exiting script." -ForegroundColor Red
    exit 1
}

# Load Git repo
if (-not(Test-Path ".\$REPO_NAME")) {
    git clone $GITHUB_REPO
}
Set-Location $REPO_NAME

# Import functions module
Import-Module "./functions.psm1"

# Parse YAML file
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

# Remove any potential previously set scheduled tasks
Unregister-ScheduledTask -TaskName "ResumeAppInstallationAfterReboot" -Confirm:$false -ErrorAction SilentlyContinue

# Loop through each app and install it
for ($i = 0; $i -lt $Apps.Count; $i++) {
    $App = $Apps[$i]

    Write-Host "Installing $($App.name)..." -ForegroundColor Green

    if ($App.installType -eq 'choco') {
        try {
            Install-WithChoco($App)
            If($App.rebootRequired) {

                # Write away the apps not yet installed
                Import-Module PSYaml
                $yamlContent = ConvertTo-Yaml $Apps[$i+1..($Apps.Length - 1)]
                Set-Content -Path "./apps.yaml" -Value $yamlContent
                Write-Host "YAML file created successfully"

                # Start the script again after the reboot
                $taskAction = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-File `"$($MyInvocation.MyCommand.Path)`""
                $taskTrigger = New-ScheduledTaskTrigger -AtStartup
                Register-ScheduledTask -Action $taskAction -Trigger $taskTrigger -TaskName "ResumeAppInstallationAfterReboot"

                # Restart
                Restart-Computer -Force

            }
            
        }
        catch {
            $SuccessfulAppCount -= 1
        }
    }
    else {
        try {
            powershell.exe -File $App.customInstallScript
            
        } 
        catch {
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


