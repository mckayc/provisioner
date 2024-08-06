@echo off
REM Download the PowerShell script
powershell -Command "Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/mckayc/provisioner/main/chocoGui.ps1' -OutFile 'chocoGui.ps1'"

REM Run the downloaded PowerShell script
powershell -ExecutionPolicy Bypass -File 'chocoGui.ps1'

REM Clean up by deleting the downloaded script
del 'chocoGui.ps1'
