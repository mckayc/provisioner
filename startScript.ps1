# setup.boxstarter

# Install Boxstarter if it's not already installed
if (-not (Get-Command boxstarter -ErrorAction SilentlyContinue)) {
    Install-PackageProvider -Name NuGet -Force -Scope CurrentUser
    Install-Module -Name Boxstarter -Force -Scope CurrentUser
}

# Run the specified PowerShell script
Install-ChocolateyPackage 'chocoGui' -Source 'https://raw.githubusercontent.com/mckayc/provisioner/main/chocoGui.ps1' -PackageType 'powershell' -Parameters '-ExecutionPolicy Bypass'
