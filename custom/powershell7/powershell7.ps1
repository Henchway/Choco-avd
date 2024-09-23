$App = "Powershell7"
$MsiUrl = "https://github.com/PowerShell/PowerShell/releases/download/v7.4.5/PowerShell-7.4.5-win-x64.msi"
$TempFolderPath = "C:\Temp"
$MsiPath = "$TempFolderPath\PowerShell-7.4.5-win-x64.msi"

if (!(Test-Path $TempFolderPath)) {
    mkdir $TempFolderPath
}

# Import functions
Import-Module -name ".\functions.psm1"

# Load Powershell
Write-Host "Attempting to load file from $MsiUrl to $MsiPath"
Load-WebFile $MsiUrl $MsiPath

# Install Powershell
# $MuiLang = "en-US" # adjust to your desired language
$Switches = "/quiet /norestart"
Write-Host "Installing Powershell7"
Start-Process -Wait -FilePath "C:\Windows\System32\msiexec.exe" -ArgumentList "/i", "$MsiPath", "$Switches"

# Error Handling
if ($LASTEXITCODE -ne 0) {
    $message = $_
    Write-Host "[ERROR] Error installing $($App): $message"
    throw
}
else {
    Write-Host "[INFO] $($App) installed successfully"
}
