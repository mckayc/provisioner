# ChocolateyPackageManager.ps1

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Function to check if Chocolatey is installed and install if not
function Ensure-Chocolatey {
    if (!(Get-Command choco -ErrorAction SilentlyContinue)) {
        Write-Host "Chocolatey is not installed. Installing now..."
        Set-ExecutionPolicy Bypass -Scope Process -Force
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
        Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
    }
    else {
        Write-Host "Chocolatey is already installed."
    }
}

# Function to read CSV file (local or web)
function Read-CsvFile($path) {
    if ($path -like "http*") {
        $content = Invoke-WebRequest -Uri $path -UseBasicParsing | Select-Object -ExpandProperty Content
        $csv = ConvertFrom-Csv $content
    }
    else {
        $csv = Import-Csv $path
    }
    return $csv
}

# Function to get locally installed packages
function Get-LocalPackages {
    $installedPackages = choco list --id-only
    $filteredPackages = $installedPackages | Where-Object { $_ -notmatch '\.install' -and $_ -notmatch '\s' }
    return $filteredPackages
}

# Function to install package
function Install-ChocoPackage($package) {
    $output = "Installing $package..."
    Write-Host $output
    UpdateConsoleOutput $output
    $result = choco install $package -y
    UpdateConsoleOutput $result
}

# Function to uninstall package
function Uninstall-ChocoPackage($package) {
    $output = "Uninstalling $package..."
    Write-Host $output
    UpdateConsoleOutput $output
    $result = choco uninstall $package -y -a -x
    UpdateConsoleOutput $result
}

# Function to update console output
function UpdateConsoleOutput($text) {
    $consoleOutput.AppendText("$text`r`n")
    $consoleOutput.ScrollToCaret()
    $form.Refresh()
}

# Main form
$form = New-Object System.Windows.Forms.Form
$form.Text = "Chocolatey Package Manager"
$form.Size = New-Object System.Drawing.Size(800,600)
$form.StartPosition = "CenterScreen"
$form.Font = New-Object System.Drawing.Font("Segoe UI", 10)

# URL TextBox
$urlTextBox = New-Object System.Windows.Forms.TextBox
$urlTextBox.Location = New-Object System.Drawing.Point(10,10)
$urlTextBox.Size = New-Object System.Drawing.Size(500,20)
$urlTextBox.Text = "https://raw.githubusercontent.com/mckayc/McWindows/master/McChocolateyList.csv"
$form.Controls.Add($urlTextBox)

# Open Button
$openButton = New-Object System.Windows.Forms.Button
$openButton.Location = New-Object System.Drawing.Point(520,10)
$openButton.Size = New-Object System.Drawing.Size(75,23)
$openButton.Text = "Open"
$form.Controls.Add($openButton)

# Load Button
$loadButton = New-Object System.Windows.Forms.Button
$loadButton.Location = New-Object System.Drawing.Point(600,10)
$loadButton.Size = New-Object System.Drawing.Size(75,23)
$loadButton.Text = "Load"
$form.Controls.Add($loadButton)

# Execute Button
$executeButton = New-Object System.Windows.Forms.Button
$executeButton.Location = New-Object System.Drawing.Point(680,10)
$executeButton.Size = New-Object System.Drawing.Size(75,23)
$executeButton.Text = "Execute"
$form.Controls.Add($executeButton)

# Progress Bar
$progressBar = New-Object System.Windows.Forms.ProgressBar
$progressBar.Location = New-Object System.Drawing.Point(10,40)
$progressBar.Size = New-Object System.Drawing.Size(760,20)
$form.Controls.Add($progressBar)

# Console Output
$consoleOutput = New-Object System.Windows.Forms.RichTextBox
$consoleOutput.Location = New-Object System.Drawing.Point(10,70)
$consoleOutput.Size = New-Object System.Drawing.Size(760,100)
$consoleOutput.ReadOnly = $true
$consoleOutput.Font = New-Object System.Drawing.Font("Consolas", 8)
$form.Controls.Add($consoleOutput)

# Package List (ListView)
$packageList = New-Object System.Windows.Forms.ListView
$packageList.Location = New-Object System.Drawing.Point(10,180)
$packageList.Size = New-Object System.Drawing.Size(760,370)
$packageList.View = [System.Windows.Forms.View]::Details
$packageList.FullRowSelect = $true
$packageList.CheckBoxes = $true
$packageList.Columns.Add("Package", 200)
$packageList.Columns.Add("Category", 200)
$packageList.Columns.Add("Status", 100)
$packageList.GridLines = $true
$packageList.Groups.Add("InstallFirst", "Install First")
$packageList.ShowGroups = $true
$form.Controls.Add($packageList)

# Event handlers and main logic

# Open Button Click Event
$openButton.Add_Click({
    $openFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $openFileDialog.Filter = "CSV Files (*.csv)|*.csv"
    if ($openFileDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $urlTextBox.Text = $openFileDialog.FileName
    }
})

# Load Button Click Event
$loadButton.Add_Click({
    $packageList.Items.Clear()
    $packageList.Groups.Clear()
    $packageList.Groups.Add("InstallFirst", "Install First")
    
    $csv = Read-CsvFile $urlTextBox.Text
    $localPackages = Get-LocalPackages

    UpdateConsoleOutput "Loading packages..."

    # Add "Install First" category at the top
    $installFirstPackages = $csv | Where-Object { $_.Category -eq "Install First" } | Sort-Object Package
    foreach ($package in $installFirstPackages) {
        $item = New-Object System.Windows.Forms.ListViewItem($package.Package)
        $item.SubItems.Add($package.Category)
        $item.Group = $packageList.Groups["InstallFirst"]
        if ($localPackages -contains $package.Package) {
            $item.Checked = $true
            $item.BackColor = [System.Drawing.Color]::LightBlue
            $item.SubItems.Add("Installed")
        } else {
            $item.SubItems.Add("Not Installed")
        }
        $packageList.Items.Add($item)
    }

    # Add other categories
    $categories = $csv | Where-Object { $_.Category -ne "Install First" } | Select-Object -ExpandProperty Category -Unique | Sort-Object
    foreach ($category in $categories) {
        $packageList.Groups.Add($category, $category)
        $packages = $csv | Where-Object { $_.Category -eq $category } | Sort-Object Package
        foreach ($package in $packages) {
            $item = New-Object System.Windows.Forms.ListViewItem($package.Package)
            $item.SubItems.Add($package.Category)
            $item.Group = $packageList.Groups[$category]
            if ($localPackages -contains $package.Package) {
                $item.Checked = $true
                $item.BackColor = [System.Drawing.Color]::LightBlue
                $item.SubItems.Add("Installed")
            } else {
                $item.SubItems.Add("Not Installed")
            }
            $packageList.Items.Add($item)
        }
    }

    # Add "Other Installed Software" category at the bottom
    $packageList.Groups.Add("OtherInstalled", "Other Installed Software")
    $otherInstalledSoftware = $localPackages | Where-Object { $_ -notin $csv.Package } | Sort-Object
    foreach ($package in $otherInstalledSoftware) {
        $item = New-Object System.Windows.Forms.ListViewItem($package)
        $item.SubItems.Add("Other Installed Software")
        $item.Group = $packageList.Groups["OtherInstalled"]
        $item.Checked = $true
        $item.BackColor = [System.Drawing.Color]::LightBlue
        $item.SubItems.Add("Installed")
        $packageList.Items.Add($item)
    }

    UpdateConsoleOutput "Packages loaded successfully."
})

# Package List Item Check Event
$packageList.Add_ItemCheck({
    param($sender, $e)
    $item = $sender.Items[$e.Index]
    if ($e.NewValue -eq [System.Windows.Forms.CheckState]::Checked) {
        if ($item.SubItems[2].Text -eq "Installed") {
            $item.BackColor = [System.Drawing.Color]::LightBlue
        } else {
            $item.BackColor = [System.Drawing.Color]::LightGreen
        }
    } else {
        if ($item.SubItems[2].Text -eq "Installed") {
            $item.BackColor = [System.Drawing.Color]::LightCoral
        } else {
            $item.BackColor = [System.Drawing.SystemColors]::Window
        }
    }
})

# Execute Button Click Event
$executeButton.Add_Click({
    $totalPackages = $packageList.Items.Count
    $currentPackage = 0

    foreach ($item in $packageList.Items) {
        $currentPackage++
        $progressBar.Value = ($currentPackage / $totalPackages) * 100

        if ($item.Checked -and $item.BackColor -eq [System.Drawing.Color]::LightGreen) {
            Install-ChocoPackage $item.Text
            $item.BackColor = [System.Drawing.Color]::LightBlue
            $item.SubItems[2].Text = "Installed"
        } elseif (-not $item.Checked -and $item.BackColor -eq [System.Drawing.Color]::LightCoral) {
            Uninstall-ChocoPackage $item.Text
            $item.BackColor = [System.Drawing.SystemColors]::Window
            $item.SubItems[2].Text = "Not Installed"
        }
    }

    $progressBar.Value = 0
    UpdateConsoleOutput "Execution completed."
})

# Set Chocolatey timeout
choco config set commandExecutionTimeoutSeconds 600

# Ensure Chocolatey is installed
Ensure-Chocolatey

# Start the application
[System.Windows.Forms.Application]::Run($form)
