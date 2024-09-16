# Define the URL of the CSV file in the GitHub repository
$url = "https://raw.githubusercontent.com/Henchway/Choco-avd/main/custom/uvnc/uvnc.inf"

# Define the path to save the CSV file locally
$localPath = "$PSScriptRoot\uvnc.inf"

# Download the CSV file
Write-Host "Downloading configuration file from $url..."
Invoke-WebRequest -Uri $url -OutFile $localPath
