param(
  [Parameter(Position=0)][string]$Folder,
  [switch]$setup,
  [switch]$a,
  [switch]$t,
  [switch]$p,
  [switch]$w,
  [switch]$s,
  [switch]$c
)

# Doka-ScreenShotTool v1.1 - Optimized Version
# Consolidated, production-ready version with robust ImageMagick setup and auto heuristics
# Made for Doka by ezellhof - https://github.com/Ezellhof/DOKA-ScreenShotTool

# ═══════════════════════════════════════════════════════════════════════════════
# GLOBALS & CONSTANTS
# ═══════════════════════════════════════════════════════════════════════════════

$script:Config = @{
  ToolName = "Doka-ScreenShotTool"
  Version = "v1.1"
  Portable = Join-Path $env:LOCALAPPDATA "ImageMagick-Portable"
  FallbackUrl = "https://download.imagemagick.org/ImageMagick/download/binaries/ImageMagick-7.1.1-32-portable-Q16-x64.zip"
  InstallDir = Join-Path $env:LOCALAPPDATA "Doka-ScreenShotTool"
  
  # DOKA Brand Colors
  Colors = @{
    DokaYellow = "#ffdd00"
    DokaBlue = "#004588"
    DarkBg = "#1e1e1e"
    LightBg = "#e6e6e6"
  }
  
  # Border Settings
  Border = @{
    YellowWidth = 5    # Inner yellow (thin)
    BlueWidth = 5      # Outer blue (thick - will show both colors)
    Spacing = 12
  }
  
  # Icon Files
  IconFiles = @("Auto.ico", "Wide.ico", "Port.ico", "Stack.ico", "Caro.ico", "Test.ico")
  
  # Montage Types
  MontageTypes = @{
    Auto = @{ Switch = "a"; Name = "Auto Montage"; Number = "1" }
    Wide = @{ Switch = "w"; Name = "Wide Montage"; Number = "2" }
    Portrait = @{ Switch = "p"; Name = "Portrait Montage"; Number = "3" }
    Stack = @{ Switch = "s"; Name = "Stack (Horizontal)"; Number = "4" }
    Carousel = @{ Switch = "c"; Name = "Carousel (Vertical)"; Number = "5" }
    Test = @{ Switch = "t"; Name = "Test Mode"; Number = "6" }
  }
}

# ═══════════════════════════════════════════════════════════════════════════════
# UTILITY FUNCTIONS
# ═══════════════════════════════════════════════════════════════════════════════

function Show-Footer {
  param(
    [bool]$success = $true,
    [string[]]$Lines,
    [System.ConsoleColor]$ContentForeground,
    [System.ConsoleColor]$ContentBackground,
    [bool]$DrawSeparator = $false
  )
  $title = "  $($script:Config.ToolName) - $($script:Config.Version)"
  $defaultMsg = if ($success) { "  Montage assembled successfully" } else { "  Assembly FAILED - check errors" }
  $content = if ($Lines -and $Lines.Count -gt 0) { $Lines } else { @($defaultMsg) }
  
  $inner = ($content + $title | ForEach-Object { $_.Length } | Measure-Object -Maximum).Maximum + 2
  $top = '+' + ('-' * $inner) + '+'
  $bottom = '+' + ('-' * $inner) + '+'
  
  Write-Host ""
  Write-Host $top -ForegroundColor Cyan
  Write-Host ('|' + (' ' + $title).PadRight($inner) + '|') -ForegroundColor Blue
  
  $separatorDrawn = $false
  foreach($c in $content){
    $textCentered = ' ' + $c.PadRight($inner - 1)
    
    if(($c -match '@' -or $c -match '^\.*[@.]') -and $ContentBackground){
      if($DrawSeparator -and -not $separatorDrawn) {
        $separator = '+' + ('-' * $inner) + '+'
        Write-Host $separator -ForegroundColor Cyan
        $separatorDrawn = $true
      }
      
      $trimmed = $c.TrimEnd()
      $artLine = ' ' + $trimmed + ' '
      $padding = $inner - $artLine.Length
      $leftPad = ' ' * [math]::Floor($padding / 2)
      $rightPad = ' ' * ($padding - $leftPad.Length)
      
      Write-Host '|' -NoNewline -ForegroundColor Cyan
      Write-Host $leftPad -NoNewline
      Write-Host $artLine -NoNewline -ForegroundColor $ContentForeground -BackgroundColor $ContentBackground
      Write-Host $rightPad -NoNewline
      Write-Host '|' -ForegroundColor Cyan
    } else {
      $line = '|' + $textCentered + '|'
      if ($ContentForeground) {
        Write-Host $line -ForegroundColor $ContentForeground
      } elseif ($success) {
        Write-Host $line -ForegroundColor Green
      } else {
        Write-Host $line -ForegroundColor Red
      }
    }
  }
  Write-Host $bottom -ForegroundColor Cyan
  Write-Host ""
}

function Add-ToUserPath([string]$Path){
  try{
    $CurrentPath = [Environment]::GetEnvironmentVariable("Path","User")
    if(-not $CurrentPath){ $CurrentPath = '' }
    if(-not ($CurrentPath -split ';' | Where-Object { $_.TrimEnd('\') -ieq $Path.TrimEnd('\') })){
      [Environment]::SetEnvironmentVariable("Path",($CurrentPath.TrimEnd(';') + ';' + $Path),"User")
      $env:Path += ";$Path"
    }
  } catch {}
}

function Get-Images($Directory){ 
  # Common image extensions supported by ImageMagick
  $imageExtensions = @(
    '*.png', '*.jpg', '*.jpeg', '*.gif', '*.bmp', '*.tiff', '*.tif', 
    '*.webp', '*.ico', '*.svg', '*.psd', '*.xcf', '*.raw', '*.cr2', 
    '*.nef', '*.arw', '*.dng', '*.orf', '*.rw2', '*.pef', '*.sr2',
    '*.heic', '*.heif', '*.avif', '*.jxl', '*.jp2', '*.j2k', '*.jpx',
    '*.pcx', '*.tga', '*.exr', '*.hdr', '*.pbm', '*.pgm', '*.ppm',
    '*.xbm', '*.xpm', '*.cut', '*.emf', '*.wmf', '*.fig', '*.jng',
    '*.mng', '*.wbmp', '*.fits', '*.fts', '*.sgi', '*.sun', '*.ras'
  )
  
  $allImages = @()
  foreach($ext in $imageExtensions) {
    $found = Get-ChildItem -Path $Directory -Filter $ext -File -ErrorAction SilentlyContinue
    if($found) { $allImages += $found }
  }
  
  return $allImages | Sort-Object Name
}

# ═══════════════════════════════════════════════════════════════════════════════
# IMAGEMAGICK MANAGEMENT
# ═══════════════════════════════════════════════════════════════════════════════

function Get-InstalledVersion {
  try {
    $cmd = Get-Command magick -ErrorAction Stop
    $line = & $cmd.Source --version 2>$null | Select-Object -First 1
    if($line -match "ImageMagick (\d+\.\d+\.\d+-\d+)"){
      return @{ Version=$matches[1]; Path=$cmd.Source; Available=$true }
    }
  } catch {}
  $portableExe = Join-Path $script:Config.Portable "magick.exe"
  if(Test-Path $portableExe){
    try{
      $line = & $portableExe --version 2>$null | Select-Object -First 1
      if($line -match "ImageMagick (\d+\.\d+\.\d+-\d+)"){
        return @{ Version=$matches[1]; Path=$portableExe; Available=$true }
      }
    } catch {}
  }
  return @{ Available=$false }
}

function Get-LatestVersion {
  try{
    $Response = Invoke-WebRequest -Uri "https://imagemagick.org/script/download.php#windows" -UseBasicParsing -TimeoutSec 10
    if($Response.Content -match "ImageMagick-(\d+\.\d+\.\d+-\d+)-portable-Q16-HDRI-x64\.zip"){
      $Version = $matches[1]
      return @{ Version=$Version; DownloadUrl="https://imagemagick.org/archive/binaries/ImageMagick-$Version-portable-Q16-HDRI-x64.zip"; Available=$true }
    }
  } catch {}
  return @{ Available=$false }
}

function Install-ImageMagickPortable([string]$DownloadUrl,[string]$Version){
  if(-not (Test-Path $script:Config.Portable)){ New-Item -ItemType Directory -Path $script:Config.Portable | Out-Null }
  $ZipFile = Join-Path $env:TEMP "ImageMagick-$Version.zip"
  $ExtractPath = Join-Path $script:Config.Portable "_extract"
  try{
    Write-Host "Downloading ImageMagick $Version..." -ForegroundColor Cyan
    Invoke-WebRequest -Uri $DownloadUrl -OutFile $ZipFile -TimeoutSec 60
    if(Test-Path $ExtractPath){ Remove-Item $ExtractPath -Recurse -Force -ErrorAction SilentlyContinue }
    Expand-Archive -Path $ZipFile -DestinationPath $ExtractPath -Force
    $MagickExe = Get-ChildItem -Path $ExtractPath -Recurse -Filter magick.exe | Select-Object -First 1
    if(-not $MagickExe){ throw "magick.exe not found in archive" }
    $SourceRoot = $MagickExe.DirectoryName
    Copy-Item -Path (Join-Path $SourceRoot '*') -Destination $script:Config.Portable -Recurse -Force
    
    Get-ChildItem -Path $script:Config.Portable -Directory -ErrorAction SilentlyContinue |
      Where-Object { $_.Name -like 'ImageMagick-*-portable-*' } |
      Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item $ExtractPath -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item $ZipFile -Force -ErrorAction SilentlyContinue
    $FinalMagick = Join-Path $script:Config.Portable "magick.exe"
    if(Test-Path $FinalMagick){ Add-ToUserPath $script:Config.Portable; return $FinalMagick }
    throw "Installation failed"
  } catch {
    Write-Host "Install failed: $($_.Exception.Message)" -ForegroundColor Yellow
    if(Test-Path $ExtractPath){ Remove-Item $ExtractPath -Recurse -Force -ErrorAction SilentlyContinue }
    if(Test-Path $ZipFile){ Remove-Item $ZipFile -Force -ErrorAction SilentlyContinue }
    return $null
  }
}

function Initialize-ImageMagick([bool]$ForceUpdate=$false){
  Write-Host "Checking ImageMagick..." -ForegroundColor Cyan
  $Installed = Get-InstalledVersion
  $Latest = Get-LatestVersion
  if($Installed.Available -and -not $ForceUpdate){
    if($Latest.Available){
      if($Installed.Version -eq $Latest.Version){
        Write-Host ("ImageMagick is on the latest version {0}" -f $Installed.Version) -ForegroundColor Green
      } else {
        Write-Host ("Update available ({0} -> {1})" -f $Installed.Version,$Latest.Version) -ForegroundColor Yellow
      }
    } else {
      Write-Host ("Using installed ImageMagick {0}" -f $Installed.Version) -ForegroundColor Green
    }
    return $Installed.Path
  }
  $DownloadUrl = if($Latest.Available){ $Latest.DownloadUrl } else { $script:Config.FallbackUrl }
  $Version = if($Latest.Available){ $Latest.Version } else { "fallback" }
  $MagickPath = Install-ImageMagickPortable -DownloadUrl $DownloadUrl -Version $Version
  return $MagickPath
}

# ═══════════════════════════════════════════════════════════════════════════════
# REGISTRY & INSTALLATION MANAGEMENT
# ═══════════════════════════════════════════════════════════════════════════════

function New-RegistryFiles {
  param([string]$InstallPath, [string]$IconPath, [string]$ScriptRoot)
  
  try {
    $ScriptPathEsc = (Join-Path $InstallPath "$($script:Config.ToolName).ps1") -replace '\\', '\\'
    $IconPathEsc = if($IconPath) { $IconPath -replace '\\', '\\' } else { '' }
    
    $AssetsPath = Join-Path $ScriptRoot "assets"
    $IconPaths = @{}
    
    # Generate icon paths for all montage types
    foreach($IconFile in $script:Config.IconFiles) {
      $BaseName = [System.IO.Path]::GetFileNameWithoutExtension($IconFile).ToUpper()
      $IconPaths["${BaseName}_ICON_PATH"] = if(Test-Path (Join-Path $AssetsPath $IconFile)) { 
        (Join-Path $InstallPath $IconFile) -replace '\\', '\\' 
      } else { 
        $IconPathEsc 
      }
    }
    
    $InstallTemplate = Join-Path $AssetsPath "Install_Context_Menu.reg.template"
    $UninstallTemplate = Join-Path $AssetsPath "Uninstall_Context_Menu.reg.template"
    
    if(Test-Path $InstallTemplate) {
      $InstallContent = Get-Content -Path $InstallTemplate -Raw -Encoding UTF8
      $InstallContent = $InstallContent -replace '\{\{SCRIPT_PATH\}\}', $ScriptPathEsc
      $InstallContent = $InstallContent -replace '\{\{ICON_PATH\}\}', $IconPathEsc
      
      # Replace all icon placeholders
      foreach($Key in $IconPaths.Keys) {
        $InstallContent = $InstallContent -replace "\{\{$Key\}\}", $IconPaths[$Key]
      }
      
      $InstallRegPath = Join-Path $InstallPath "Install_Context_Menu.reg"
      Set-Content -Path $InstallRegPath -Value $InstallContent -Encoding UTF8 -Force
    } else {
      Write-Host "Warning: Install template not found at $InstallTemplate" -ForegroundColor Yellow
      $InstallRegPath = $null
    }
    
    if(Test-Path $UninstallTemplate) {
      $UninstallContent = Get-Content -Path $UninstallTemplate -Raw -Encoding UTF8
      $UninstallRegPath = Join-Path $InstallPath "Uninstall_Context_Menu.reg"
      Set-Content -Path $UninstallRegPath -Value $UninstallContent -Encoding UTF8 -Force
    } else {
      Write-Host "Warning: Uninstall template not found at $UninstallTemplate" -ForegroundColor Yellow
      $UninstallRegPath = $null
    }
    
    return @{ InstallReg = $InstallRegPath; UninstallReg = $UninstallRegPath }
    
  } catch {
    Write-Host "Failed to generate registry files: $($_.Exception.Message)" -ForegroundColor Yellow
    return $null
  }
}

function Install-ToolAssets {
  try{
    if(-not (Test-Path $script:Config.InstallDir)){ New-Item -ItemType Directory -Path $script:Config.InstallDir | Out-Null }
    $ScriptSrc = if($PSCommandPath){ $PSCommandPath } else { $MyInvocation.MyCommand.Path }
    $ScriptDest = Join-Path $script:Config.InstallDir "$($script:Config.ToolName).ps1"
    
    # Copy script with proper UTF8 encoding to preserve Unicode characters
    $ScriptContent = Get-Content -Path $ScriptSrc -Raw -Encoding UTF8
    Set-Content -Path $ScriptDest -Value $ScriptContent -Encoding UTF8 -Force
    
    $ScriptRoot = Split-Path -Parent $ScriptSrc
    $AssetsPath = Join-Path $ScriptRoot "assets"
    
    # Copy main icon
    $IconSrc = Join-Path $AssetsPath "Doka.ico"
    $IconDest = Join-Path $script:Config.InstallDir "Doka.ico"
    if(Test-Path $IconSrc){ Copy-Item -Path $IconSrc -Destination $IconDest -Force } else { $IconDest = $null }
    
    # Copy all option-specific icons
    foreach($IconFile in $script:Config.IconFiles) {
      $OptionIconSrc = Join-Path $AssetsPath $IconFile
      $OptionIconDest = Join-Path $script:Config.InstallDir $IconFile
      if(Test-Path $OptionIconSrc) { 
        Copy-Item -Path $OptionIconSrc -Destination $OptionIconDest -Force 
        Write-Host "Copied $IconFile to install directory" -ForegroundColor DarkGray
      } else {
        Write-Host "Warning: $IconFile not found in assets directory" -ForegroundColor Yellow
      }
    }
    
    # Copy ASCII art file
    $ArtDest = $null
    $ArtSrcCandidates = @(
      (Join-Path $AssetsPath "doka_ascii.txt"),
      (Join-Path $ScriptRoot "doka_ascii.txt")
    )
    $ArtSrc = $null
    foreach($Candidate in $ArtSrcCandidates){ if(-not $ArtSrc -and (Test-Path $Candidate)){ $ArtSrc = $Candidate } }
    if($ArtSrc){
      $ArtName = Split-Path -Leaf $ArtSrc
      $ArtDest = Join-Path $script:Config.InstallDir $ArtName
      Copy-Item -Path $ArtSrc -Destination $ArtDest -Force
    }
    
    # Setup PATH and convenience tools
    Add-ToUserPath $script:Config.InstallDir
    $CmdPath = Join-Path $script:Config.InstallDir "scmontage.cmd"
    $CmdLines = @(
      '@echo off',
      'powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%LOCALAPPDATA%\Doka-ScreenShotTool\Doka-ScreenShotTool.ps1" %*'
    )
    Set-Content -Path $CmdPath -Value $CmdLines -Encoding ASCII -Force
    
    [Environment]::SetEnvironmentVariable("SCMONTAGE", $ScriptDest, "User")
    $env:SCMONTAGE = $ScriptDest
    
    # Generate registry files
    $RegFiles = New-RegistryFiles -InstallPath $script:Config.InstallDir -IconPath $IconDest -ScriptRoot $ScriptRoot
    
    # Copy registry files to script directory
    if($RegFiles -and $RegFiles.InstallReg -and $RegFiles.UninstallReg) {
      try {
        $ScriptDirInstallReg = Join-Path $ScriptRoot "Install_Context_Menu.reg"
        $ScriptDirUninstallReg = Join-Path $ScriptRoot "Uninstall_Context_Menu.reg"
        Copy-Item -Path $RegFiles.InstallReg -Destination $ScriptDirInstallReg -Force
        Copy-Item -Path $RegFiles.UninstallReg -Destination $ScriptDirUninstallReg -Force
      } catch {
        Write-Host "Warning: Could not copy registry files to script directory" -ForegroundColor Yellow
      }
    }
    
    return @{ ScriptPath=$ScriptDest; IconPath=$IconDest; Shim=$CmdPath; ArtPath=$ArtDest; RegFiles=$RegFiles }
  } catch {
    Write-Host "Failed to install tool assets: $($_.Exception.Message)" -ForegroundColor Yellow
    return $null
  }
}

# ═══════════════════════════════════════════════════════════════════════════════
# IMAGE ANALYSIS & PROCESSING
# ═══════════════════════════════════════════════════════════════════════════════

function Get-ImageStats($images,$magick){
  $totalB=0.0; $totalAR=0.0; $n=0; $wide=0; $std=0; $tall=0
  foreach($img in $images){
    try{
      $fmt = "%[fx:mean],%w,%h\n"
      $line = & $magick identify -quiet -format $fmt -- "$($img.FullName)" 2>$null
      $parts = $line -split ','
      if($parts.Count -ge 3){
        $mean=[double]$parts[0]
        $w=[double]$parts[1]; $h=[double]$parts[2]
        if($h -gt 0){ $ar=$w/$h } else { $ar=1.0 }
        $totalB += $mean; $totalAR += $ar; $n++
        if($ar -ge 1.6){ $wide++ } elseif($ar -le 0.8){ $tall++ } else { $std++ }
      }
    } catch {}
  }
  if($n -eq 0){ return @{ Mean=0.5; AvgAR=1.0; Counts=@{wide=0;standard=0;tall=0} } }
  return @{ Mean=($totalB/$n); AvgAR=($totalAR/$n); Counts=@{wide=$wide;standard=$std;tall=$tall} }
}

function Get-AutomaticSettings($images,$magick){
  Write-Host "Analyzing images for theme and orientation..." -ForegroundColor Yellow
  $stats = Get-ImageStats $images $magick
  $avgB = $stats.Mean; $avgAR=$stats.AvgAR
  $wide=$stats.Counts.wide; $std=$stats.Counts.standard; $tall=$stats.Counts.tall
  $useDark = $avgB -gt 0.5
  $count = $images.Count

  $perfectSquares = @(1,4,9,16,25,36)
  if($perfectSquares -contains $count){ $usePortrait=$true; $reason="perfect square grid" }
  elseif($count -le 3){ $usePortrait=$true; $reason="few images" }
  elseif($count -ge 12){ $usePortrait = ($avgAR -lt 1.2); $reason="many images; avg AR $([math]::Round($avgAR,2))" }
  else { $usePortrait = ($tall -gt $wide) -or ($avgAR -lt 1.1); $reason="mix: $wide wide, $std standard, $tall tall" }

  Write-Host ("  Theme: {0} (avg brightness {1:P0})" -f ($(if($useDark){'Dark'}else{'Light'}), $avgB)) -ForegroundColor White
  Write-Host ("  Orientation: {0} ({1})" -f ($(if($usePortrait){'Portrait'}else{'Wide'}), $reason)) -ForegroundColor White
  @{ UseDark=$useDark; UsePortrait=$usePortrait }
}

function Get-OptimalGrid([int]$count,[string]$orientation){
  $bestCols=1; $bestRows=$count
  $target = if($orientation -eq 'portrait'){0.75}else{1.33}
  $bestDiff=[math]::Abs(($bestCols/$bestRows) - $target)
  for($cols=1; $cols -le $count; $cols++){
    $rows=[math]::Ceiling($count/$cols)
    $ratio=$cols/$rows
    $diff=[math]::Abs($ratio - $target)
    if($diff -lt $bestDiff){ $bestCols=$cols; $bestRows=$rows; $bestDiff=$diff }
  }
  @{ Columns=$bestCols; Rows=$bestRows }
}

# ═══════════════════════════════════════════════════════════════════════════════
# UNIFIED MONTAGE CREATION ENGINE
# ═══════════════════════════════════════════════════════════════════════════════

function New-UnifiedMontage {
  param(
    [Parameter(Mandatory)]$Images,
    [Parameter(Mandatory)][string]$MagickPath,
    [Parameter(Mandatory)][string]$InputFolder,
    [Parameter(Mandatory)][bool]$IsDark,
    [string]$MontageType = "Grid",  # Grid, Stack, Carousel
    [bool]$IsPortrait = $true,
    [string]$ModeDescription = "",
    [string]$OutputFileOverride = $null
  )
  
  $folderInfo = Get-Item $InputFolder
  $folderName = $folderInfo.Name
  $outputFolder = $folderInfo.Parent.FullName
  $imageCount = $Images.Count
  
  # Determine output file name
  if($OutputFileOverride) {
    $outFile = $OutputFileOverride
  } else {
    $modeText = if($IsDark){'Dark'}else{'Light'}
    $suffix = if($ModeDescription -eq "Auto"){"_Auto"}else{""}
    
    switch($MontageType) {
      "Grid" { 
        $orientationText = if($IsPortrait){'Portrait'}else{'Wide'}
        $outFile = "${orientationText}_${modeText}_${folderName}${suffix}.png"
      }
      "Stack" { $outFile = "Stack_${modeText}_${folderName}.png" }
      "Carousel" { $outFile = "Carousel_${modeText}_${folderName}.png" }
    }
  }
  
  $outPath = Join-Path $outputFolder $outFile
  
  # Configure geometry and tile based on montage type
  switch($MontageType) {
    "Grid" {
      $orientation = if($IsPortrait){'portrait'}else{'landscape'}
      $grid = Get-OptimalGrid -count $imageCount -orientation $orientation
      $tile = "$($grid.Columns)x$($grid.Rows)"
      $geometry = "+$($script:Config.Border.Spacing)+$($script:Config.Border.Spacing)"
      Write-Host ("Creating {0} {1} montage ({2}x{3}) with DOKA branded borders..." -f $(if($IsPortrait){'Portrait'}else{'Wide'}), $(if($IsDark){'Dark'}else{'Light'}), $grid.Columns, $grid.Rows) -ForegroundColor Cyan
    }
    "Stack" {
      $maxHeight = 0
      foreach($img in $Images){
        try {
          $info = & $MagickPath identify -format "%h" -- "$($img.FullName)" 2>$null
          $h = [int]$info
          if($h -gt $maxHeight){ $maxHeight = $h }
        } catch {}
      }
      if($maxHeight -le 0){ $maxHeight = 100 }
      $tile = "1x${imageCount}"
      $geometry = "x${maxHeight}+$($script:Config.Border.Spacing)+$($script:Config.Border.Spacing)"
      Write-Host ("Creating Stack (vertical, {0} mode) with DOKA branded borders..." -f $(if($IsDark){'Dark'}else{'Light'})) -ForegroundColor Cyan
    }
    "Carousel" {
      $maxWidth = 0
      foreach($img in $Images){
        try {
          $info = & $MagickPath identify -format "%w" -- "$($img.FullName)" 2>$null
          $w = [int]$info
          if($w -gt $maxWidth){ $maxWidth = $w }
        } catch {}
      }
      if($maxWidth -le 0){ $maxWidth = 100 }
      $tile = "${imageCount}x1"
      $geometry = "${maxWidth}x+$($script:Config.Border.Spacing)+$($script:Config.Border.Spacing)"
      Write-Host ("Creating Carousel (horizontal, {0} mode) with DOKA branded borders..." -f $(if($IsDark){'Dark'}else{'Light'})) -ForegroundColor Cyan
    }
  }
  
  # 1) Create temporary directory for bordered images
  $tempDir = Join-Path $env:TEMP "DokaMontage_$(Get-Random)"
  New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
  
  # 2) Apply DOKA borders to each individual image
  $borderedImages = @()
  foreach($img in $Images) {
    $tempImg = Join-Path $tempDir "bordered_$($img.Name)"
    
    # Apply dual borders to individual image
    & $MagickPath $img.FullName `
      -bordercolor $script:Config.Colors.DokaYellow -border $script:Config.Border.YellowWidth `
      -bordercolor $script:Config.Colors.DokaBlue   -border $script:Config.Border.BlueWidth `
      $tempImg
    
    $borderedImages += $tempImg
  }

  # 3) Create montage from bordered images
  $imArgs = @('montage')
  foreach($f in $borderedImages){ $imArgs += $f }
  $imArgs += @(
    '-tile', $tile,
    '-geometry', $geometry,
    '-background', $(if($IsDark){$script:Config.Colors.DarkBg}else{$script:Config.Colors.LightBg}),
    '-shadow',
    '-quality', '95',
    '-density', '150',
    $outPath
  )

  # 4) Run montage and cleanup
  & $MagickPath @imArgs
  Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
  
  $success = ($LASTEXITCODE -eq 0)
  if($success){ 
    Write-Host "SUCCESS: $outFile" -ForegroundColor Green 
  } else { 
    Write-Host "FAILED: $outFile (exit $LASTEXITCODE)" -ForegroundColor Red 
  }
  
  return @{ Success = $success; FileName = $outFile }
}

# ═══════════════════════════════════════════════════════════════════════════════
# MAIN EXECUTION LOGIC
# ═══════════════════════════════════════════════════════════════════════════════

function Invoke-Setup {
  $magick = Initialize-ImageMagick -forceUpdate:$false
  if($magick){
    Write-Host "Setup completed successfully." -ForegroundColor Green
    Write-Host "You can now use 'magick' from any terminal." -ForegroundColor Cyan
    $assets = Install-ToolAssets
    if($assets){
      Write-Host ("Installed tool to: {0}" -f $script:Config.InstallDir) -ForegroundColor Green
      if($assets.Shim -and (Test-Path $assets.Shim)){
        Write-Host ("Run: scmontage -a <folder>") -ForegroundColor DarkGray
      }
      if($env:SCMONTAGE){
        Write-Host ("User env var SCMONTAGE -> $env:SCMONTAGE") -ForegroundColor DarkGray
      }
      if($assets.RegFiles -and $assets.RegFiles.InstallReg){
        Write-Host ("Registry files generated: Install_Context_Menu.reg & Uninstall_Context_Menu.reg") -ForegroundColor DarkGray
      }
      
      # Prompt for context menu installation
      if($assets.RegFiles -and $assets.RegFiles.InstallReg -and (Test-Path $assets.RegFiles.InstallReg)){
        Write-Host ""
        $contextMenuChoice = Read-Host "Install Windows Context Menu Integration? (Y/n)"
        if($contextMenuChoice -eq "" -or $contextMenuChoice -match "^[Yy]") {
          try {
            Write-Host "Installing context menu integration..." -ForegroundColor Cyan
            Start-Process -FilePath "regedit.exe" -ArgumentList "/s", "`"$($assets.RegFiles.InstallReg)`"" -Wait -Verb RunAs
            Write-Host "Context menu integration installed successfully!" -ForegroundColor Green
          } catch {
            Write-Host "Failed to install context menu: $($_.Exception.Message)" -ForegroundColor Yellow
            Write-Host "You can manually install it later by running: Install_Context_Menu.reg" -ForegroundColor Gray
          }
        } else {
          Write-Host "Context menu installation skipped. You can install it later by running: Install_Context_Menu.reg" -ForegroundColor Gray
        }
      }
    }
    
    # Show footer with ASCII art
    $art = @()
    if($assets.ArtPath -and (Test-Path $assets.ArtPath)){
      $art = Get-Content -Path $assets.ArtPath -Encoding UTF8 | ForEach-Object { $_.Replace('-', ' ') }
    }
    $lines = @(
      '  Tool successfully installed',
      '  Made for Doka by ezellhof',
      '  https://github.com/Ezellhof/DOKA-ScreenShotTool'
    ) + $art
    Show-Footer -success $true -Lines $lines -ContentForeground DarkBlue -ContentBackground Yellow -DrawSeparator $true
    return $true
  } else {
    Write-Host "Setup failed." -ForegroundColor Red
    Show-Footer -success $false -Lines @('  Install failed')
    return $false
  }
}

function Invoke-TestMode($images, $magick, $Folder) {
  Write-Host "TEST MODE: creating all 8 combinations (portrait/landscape × dark/light + stack/carousel dark/light)..." -ForegroundColor Magenta
  $ok = 0
  
  # Standard grid montages (4 combinations)
  foreach($isPortrait in $true,$false){
    foreach($isDark in $true,$false){
      $result = New-UnifiedMontage -Images $images -MagickPath $magick -InputFolder $Folder -IsDark $isDark -MontageType "Grid" -IsPortrait $isPortrait -ModeDescription "Test"
      if($result.Success){ $ok++ }
    }
  }
  
  # Stack montages (2 combinations)
  foreach($isDark in $true,$false){
    $result = New-UnifiedMontage -Images $images -MagickPath $magick -InputFolder $Folder -IsDark $isDark -MontageType "Stack"
    if($result.Success){ $ok++ }
  }
  
  # Carousel montages (2 combinations)
  foreach($isDark in $true,$false){
    $result = New-UnifiedMontage -Images $images -MagickPath $magick -InputFolder $Folder -IsDark $isDark -MontageType "Carousel"
    if($result.Success){ $ok++ }
  }
  
  Write-Host ("Test completed: {0}/8 successful" -f $ok) -ForegroundColor ($(if($ok -eq 8){'Green'}else{'Yellow'}))
  Show-Footer ($ok -eq 8)
  return ($ok -eq 8)
}

function Main {
  # Setup mode
  if($setup){
    $success = Invoke-Setup
    exit $(if($success){0}else{1})
  }

  # Default to automatic mode if no flags provided
  if(-not ($p -or $w -or $t -or $a -or $s -or $c)){ 
    Write-Host "No mode specified - defaulting to automatic (-a)" -ForegroundColor Yellow
    $a=$true 
  }

  # Initialize ImageMagick
  $magick = Initialize-ImageMagick
  if(-not $magick){ 
    Write-Host "ImageMagick setup failed." -ForegroundColor Red
    Show-Footer $false
    exit 1 
  }

  # Validate folder
  if(-not $Folder){ 
    Write-Host "Provide a folder path." -ForegroundColor Red
    Show-Footer $false
    exit 1 
  }
  if(-not (Test-Path $Folder -PathType Container)){ 
    Write-Host "Folder not found: $Folder" -ForegroundColor Red
    Show-Footer $false
    exit 1 
  }

  # Get images
  $images = Get-Images $Folder
  if(-not $images -or $images.Count -eq 0){ 
    Write-Host "No PNGs found in: $Folder" -ForegroundColor Red
    Show-Footer $false
    exit 1 
  }
  Write-Host ("Found {0} PNG files" -f $images.Count) -ForegroundColor Green

  # Process based on mode
  if($t){
    $success = Invoke-TestMode $images $magick $Folder
    exit $(if($success){0}else{1})
  }

  # For all other modes, get automatic theme settings
  $auto = Get-AutomaticSettings $images $magick
  $isDark = $auto.UseDark

  # Execute the appropriate montage type
  $result = $null
  if($a){
    $result = New-UnifiedMontage -Images $images -MagickPath $magick -InputFolder $Folder -IsDark $isDark -MontageType "Grid" -IsPortrait $auto.UsePortrait -ModeDescription "Auto"
  } elseif($p){
    $result = New-UnifiedMontage -Images $images -MagickPath $magick -InputFolder $Folder -IsDark $isDark -MontageType "Grid" -IsPortrait $true -ModeDescription "Portrait"
  } elseif($w){
    $result = New-UnifiedMontage -Images $images -MagickPath $magick -InputFolder $Folder -IsDark $isDark -MontageType "Grid" -IsPortrait $false -ModeDescription "Wide"
  } elseif($s){
    $result = New-UnifiedMontage -Images $images -MagickPath $magick -InputFolder $Folder -IsDark $isDark -MontageType "Stack"
  } elseif($c){
    $result = New-UnifiedMontage -Images $images -MagickPath $magick -InputFolder $Folder -IsDark $isDark -MontageType "Carousel"
  }

  if($result) {
    Show-Footer $result.Success
    exit $(if($result.Success){0}else{1})
  } else {
    Show-Footer $false
    exit 1
  }
}

# ═══════════════════════════════════════════════════════════════════════════════
# ENTRY POINT
# ═══════════════════════════════════════════════════════════════════════════════

try { 
  Main 
} catch { 
  Write-Host $_.Exception.Message -ForegroundColor Red
  Show-Footer $false
  exit 1 
}