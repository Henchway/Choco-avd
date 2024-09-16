$GITHUB_URL=$args[0]

# Define file name
$filename = "uvnc.inf"

# Define the URL of the file in the GitHub repository
$url = "$($GITHUB_URL)/custom/uvnc/$($filename)"

# Define the path to save the CSV file locally
$localPath = ".\$($filename)"

# Download the CSV file
Write-Host "Downloading configuration file from $url..."
Invoke-WebRequest -Uri $url -OutFile $localPath
