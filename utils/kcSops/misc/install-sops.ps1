# Check if the script is running with administrative privileges
if (-not ([bool] (New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))) {
    Write-Host "Please run this script as an administrator."
    exit 1
}

# Get the latest release tag from GitHub
try {
    $latest_release = (Invoke-RestMethod -Uri "https://api.github.com/repos/mozilla/sops/releases/latest").tag_name
} catch {
    Write-Host "Failed to retrieve the latest release tag."
    exit 1
}

$base_url = "https://github.com/mozilla/sops/releases/download/$latest_release"

# Determine the appropriate SOPS binary URL
$file = "sops-$latest_release.exe"
$url = "$base_url/$file"

# Create the destination directory if it doesn't exist
$destinationDir = "C:\Program Files\sops"
if (-Not (Test-Path -Path $destinationDir)) {
    try {
        New-Item -ItemType Directory -Path $destinationDir | Out-Null
    } catch {
        Write-Host "Failed to create directory $destinationDir."
        exit 1
    }
}

# Download and install SOPS
$destination = "$destinationDir\sops.exe"
Write-Host "Downloading $url"
try {
    Invoke-WebRequest -Uri $url -OutFile $destination
    # Ensure the file is executable
    [System.IO.File]::SetAttributes($destination, [System.IO.FileAttributes]::Normal)
    Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
} catch {
    Write-Host "Failed to download $url"
    exit 1
}

# Add SOPS to PATH for current session
$env:Path += ";$destinationDir"

# Add SOPS to the system PATH permanently
$oldPath = [System.Environment]::GetEnvironmentVariable("Path", [System.EnvironmentVariableTarget]::Machine)
if ($oldPath -notlike "*$destinationDir*") {
    try {
        [System.Environment]::SetEnvironmentVariable("Path", "$oldPath;$destinationDir", [System.EnvironmentVariableTarget]::Machine)
        Write-Host "Added $destinationDir to system PATH"
    } catch {
        Write-Host "Failed to add $destinationDir to system PATH"
        exit 1
    }
}

# Verify installation
& $destination --version
