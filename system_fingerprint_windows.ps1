$ErrorActionPreference = "SilentlyContinue"

$ts = Get-Date -Format "yyyyMMdd_HHmmss"
$out = "system_fingerprint_windows_$ts.txt"

Start-Transcript -Path $out

Write-Host "=================================================="
Write-Host " WINDOWS SYSTEM FINGERPRINT REPORT"
Write-Host " Generated: $(Get-Date)"
Write-Host "==================================================`n"

Write-Host "===== HOST ====="
hostname
Write-Host ""

Write-Host "===== OS ====="
Get-ComputerInfo | Select-Object OsName, OsVersion, WindowsVersion, OsArchitecture, CsManufacturer, CsModel
Write-Host ""

Write-Host "===== CPU ====="
Get-CimInstance Win32_Processor | Select-Object Name, NumberOfCores, NumberOfLogicalProcessors, MaxClockSpeed
Write-Host ""

Write-Host "===== MEMORY ====="
"{0:N2} GB RAM" -f ((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB)
Write-Host ""

Write-Host "===== STORAGE ====="
Get-CimInstance Win32_DiskDrive | Select-Object Model, @{N="Size(GB)";E={[math]::Round($_.Size/1GB,2)}}
Write-Host ""

Write-Host "===== GPU ====="
Get-CimInstance Win32_VideoController | Select-Object Name, DriverVersion, AdapterRAM
Write-Host ""

Write-Host "===== NVIDIA / CUDA ====="
if (Get-Command nvidia-smi -ErrorAction SilentlyContinue) {
    nvidia-smi
} else {
    Write-Host "NVIDIA GPU or drivers not detected"
}
Write-Host ""

Write-Host "===== DOCKER ====="
docker version || Write-Host "Docker not installed"
Write-Host ""

Write-Host "===== WSL ====="
wsl --status || Write-Host "WSL not installed"
Write-Host ""

Write-Host "===== PYTHON ====="
python --version || Write-Host "Python not installed"
Write-Host ""

Write-Host "===== AUTO CLASSIFICATION ====="
$gpu = (Get-CimInstance Win32_VideoController | Select-Object -First 1 -ExpandProperty Name)
if ($gpu -match "NVIDIA") {
    Write-Host "GPU Type: NVIDIA (CUDA-capable)"
} else {
    Write-Host "GPU Type: Non-NVIDIA"
}
Write-Host "Architecture: x86_64"

Write-Host ""
Write-Host "=================================================="
Write-Host " END OF REPORT"
Write-Host " Saved as: $out"
Write-Host "=================================================="

Stop-Transcript
