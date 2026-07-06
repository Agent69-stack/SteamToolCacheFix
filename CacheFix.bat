@echo off
setlocal
set "SCRIPT_DIR=%~dp0"

powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -Command ^
  "& {" ^
  "  $ErrorActionPreference = 'Stop';" ^
  "  [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12;" ^
  "  $url = 'https://raw.githubusercontent.com/Agent69-stack/SteamToolCacheFix/main/Cache';" ^
  "  $expectedHash = 'B3BB00449B24A116EE36F9051378A63C884433D5983B635DFDF5490FBC506AAC';" ^
  "  $roots = @($env:SCRIPT_DIR, (Get-Location).Path);" ^
  "  $userSteam = Get-ItemProperty -LiteralPath 'HKCU:\Software\Valve\Steam' -ErrorAction SilentlyContinue;" ^
  "  if ($userSteam.SteamPath) { $roots += $userSteam.SteamPath };" ^
  "  $machineSteam = Get-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\WOW6432Node\Valve\Steam' -ErrorAction SilentlyContinue;" ^
  "  if ($machineSteam.InstallPath) { $roots += $machineSteam.InstallPath };" ^
  "  $programFilesX86 = [Environment]::GetEnvironmentVariable('ProgramFiles(x86)');" ^
  "  if ($programFilesX86) { $roots += (Join-Path $programFilesX86 'Steam') };" ^
  "  if ($env:ProgramFiles) { $roots += (Join-Path $env:ProgramFiles 'Steam') };" ^
  "  $cacheDir = $roots | Where-Object { $_ } | Select-Object -Unique | ForEach-Object {" ^
  "    $candidate = Join-Path $_ 'appcache\httpcache\3a';" ^
  "    if (Test-Path -LiteralPath $candidate -PathType Container) { (Resolve-Path -LiteralPath $candidate).Path }" ^
  "  } | Select-Object -First 1;" ^
  "  if (-not $cacheDir) { throw 'Could not find appcache\httpcache\3a.' };" ^
  "  $target = Get-ChildItem -LiteralPath $cacheDir -File -Force | Where-Object { $_.Name -match '^[0-9A-Fa-f]{16}$' } | Sort-Object LastWriteTime -Descending | Select-Object -First 1;" ^
  "  if (-not $target) { throw ('No 16-character hexadecimal cache file found in ' + $cacheDir) };" ^
  "  $temp = $target.FullName + '.download';" ^
  "  try {" ^
  "    Write-Host ('Downloading cache for ' + $target.Name + '...');" ^
  "    Invoke-WebRequest -UseBasicParsing -Uri $url -OutFile $temp;" ^
  "    $actualHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $temp).Hash;" ^
  "    if ($actualHash -ne $expectedHash) { throw ('Downloaded cache hash mismatch: ' + $actualHash) };" ^
  "    Move-Item -LiteralPath $temp -Destination $target.FullName -Force;" ^
  "    Write-Host ('Cache replaced successfully: ' + $target.FullName);" ^
  "  } finally {" ^
  "    if (Test-Path -LiteralPath $temp) { Remove-Item -LiteralPath $temp -Force };" ^
  "  }" ^
  "}"

if errorlevel 1 (
  echo Cache fix failed.
  exit /b 1
)

exit /b 0
