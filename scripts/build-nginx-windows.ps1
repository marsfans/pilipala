<#
PowerShell build script for NGINX on Windows (example).
Note: Building NGINX on Windows commonly requires:
 - Visual Studio with MSVC & nmake
 - Windows-compatible builds of OpenSSL, zlib, PCRE (or use bundled sources)
This script demonstrates the steps to download the source and attempt a build using MSVC toolchain.
You may need to adapt paths to OpenSSL/zlib/pcre builds for your environment.
#>

param()

$ErrorActionPreference = "Stop"

if (-not $env:NGINX_VERSION) {
  Write-Error "NGINX_VERSION environment variable must be set"
  exit 1
}

$version = $env:NGINX_VERSION
$workdir = Resolve-Path .
$distdir = Join-Path $workdir "dist"
New-Item -ItemType Directory -Force -Path $distdir | Out-Null

$tgz = "nginx-$version.tar.gz"
$url = "http://nginx.org/download/$tgz"
$builddir = Join-Path $workdir "build"
New-Item -ItemType Directory -Force -Path $builddir | Out-Null
Set-Location $builddir

if (-not (Test-Path $tgz)) {
  Write-Host "Downloading $url"
  Invoke-WebRequest -Uri $url -OutFile $tgz
}

if (-not (Test-Path "nginx-$version")) {
  Write-Host "Extracting $tgz"
  # Windows runner should have tar
  tar -xzf $tgz
}

Set-Location "nginx-$version"

# NOTE: The official windows build flow uses 'auto/tools/msvc' and Visual Studio tools;
# here we provide a simple attempt that may need adjustments.
Write-Host "Attempting to build with nmake (MSVC) if available..."

# Try to find vcvarsall or use VS Developer Command Prompt
$vswhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
if (Test-Path $vswhere) {
  $vsPath = & $vswhere -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
  if ($vsPath) {
    $vcvars = Join-Path $vsPath "VC\Auxiliary\Build\vcvarsall.bat"
    if (Test-Path $vcvars) {
      Write-Host "Found vcvarsall: $vcvars"
      & cmd /c "`"$vcvars`" x64 && nmake /f Makefile.msvc" 
    } else {
      Write-Warning "vcvarsall.bat not found; you may need to run this script from a Developer Command Prompt"
      Write-Warning "Attempting nmake anyway..."
      & nmake /f Makefile.msvc
    }
  } else {
    Write-Warning "Visual Studio with VC tools not found; build will likely fail."
    Write-Warning "You may want to prepare dependencies (OpenSSL/zlib/pcre) and run in Developer Command Prompt."
    & nmake /f Makefile.msvc
  }
} else {
  Write-Warning "vswhere not found. Trying nmake directly..."
  & nmake /f Makefile.msvc
}

# After build, copy the compiled nginx.exe and conf to dist
$arch = (Get-CimInstance Win32_OperatingSystem).OSArchitecture
$outname = "nginx-$version-windows-$arch"
$outpath = Join-Path $distdir $outname
New-Item -ItemType Directory -Force -Path $outpath | Out-Null

# Common nginx windows build places built files in objs or src
# Copy what we can find
if (Test-Path "objs\nginx.exe") {
  Copy-Item -Path "objs\nginx.exe" -Destination $outpath -Force
}
# copy conf and html
if (Test-Path "objs\nginx.exe") {
  Copy-Item -Path "conf" -Destination $outpath -Recurse -Force
  Copy-Item -Path "html" -Destination $outpath -Recurse -Force
}

# Create zip
Push-Location $distdir
$zipname = "$outname.zip"
if (Test-Path $zipname) { Remove-Item $zipname -Force }
Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::CreateFromDirectory($outpath, $zipname)
Write-Host "Packaged: $distdir\$zipname"
Pop-Location
