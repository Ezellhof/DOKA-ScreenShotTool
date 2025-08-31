param(
  [Parameter(Position=0)][string]$Folder,
  [switch]$setup,
  [switch]$reinstall,
  [switch]$a,
  [switch]$t,
  [switch]$p,
  [switch]$w,
  [switch]$d,
  [switch]$l
)

# OP-ScreenAssembly v1.0 - Doka Screenshot Montage Tool
# Optimized, production-ready version with robust ImageMagick setup and auto heuristics
# Made for Doka by ezellhof - https://github.com/Ezellhof/DOKA-ScreenShotTool

# Globals
$ToolName = "OP-ScreenAssembly"
$Version  = "v1.0"
$Portable = Join-Path $env:LOCALAPPDATA "ImageMagick-Portable"
$FallbackUrl = "https://download.imagemagick.org/ImageMagick/download/binaries/ImageMagick-7.1.1-32-portable-Q16-x64.zip"
$InstallDir = Join-Path $env:LOCALAPPDATA "OP-ScreenAssembly"

function Show-Footer {
  param(
    [bool]$success = $true,
    [string[]]$Lines,
    [System.ConsoleColor]$ContentForeground,
    [System.ConsoleColor]$ContentBackground,
    [bool]$DrawSeparator = $false
  )
  $title = "  $ToolName - $Version"
  $defaultMsg = if ($success) { "  Montage assembled successfully" } else { "  Assembly FAILED - check errors" }
  $content = if ($Lines -and $Lines.Count -gt 0) { $Lines } else { @($defaultMsg) }
  # Provide 1 space left + 1 space right padding inside the frame
  $inner = ($content + $title | ForEach-Object { $_.Length } | Measure-Object -Maximum).Maximum + 2
  $top    = '╔' + ('═' * $inner) + '╗'
  $bottom = '╚' + ('═' * $inner) + '╝'
  Write-Host ""
  Write-Host $top -ForegroundColor Cyan
  Write-Host ('║' + (' ' + $title).PadRight($inner) + '║') -ForegroundColor Blue
  $separatorDrawn = $false
  foreach($c in $content){
    $textCentered = ' ' + $c.PadRight($inner - 1)
    
    # Check if this line contains ASCII art (@ symbols or starts with dots)
    if(($c -match '@' -or $c -match '^\.*[@.]') -and $ContentBackground){
      # Draw separator before ASCII art if this is the first art line
      if($DrawSeparator -and -not $separatorDrawn) {
        $separator = '╠' + ('═' * $inner) + '╣'
        Write-Host $separator -ForegroundColor Cyan
        $separatorDrawn = $true
      }
      
      # For ASCII art lines: apply background to entire art content, trimmed to actual width
      $trimmed = $c.TrimEnd()
      $artLine = ' ' + $trimmed + ' '
      $padding = $inner - $artLine.Length
      $leftPad = ' ' * [math]::Floor($padding / 2)
      $rightPad = ' ' * ($padding - $leftPad.Length)
      
      Write-Host '║' -NoNewline -ForegroundColor Cyan
      Write-Host $leftPad -NoNewline
      Write-Host $artLine -NoNewline -ForegroundColor $ContentForeground -BackgroundColor $ContentBackground
      Write-Host $rightPad -NoNewline
      Write-Host '║' -ForegroundColor Cyan
    } else {
      # For text lines: normal formatting without background
      $line = '║' + $textCentered + '║'
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

function Get-InstalledVersion {
  try {
    $cmd = Get-Command magick -ErrorAction Stop
    $line = & $cmd.Source --version 2>$null | Select-Object -First 1
    if($line -match "ImageMagick (\d+\.\d+\.\d+-\d+)"){
      return @{ Version=$matches[1]; Path=$cmd.Source; Available=$true }
    }
  } catch {}
  $portableExe = Join-Path $Portable "magick.exe"
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
  if(-not (Test-Path $Portable)){ New-Item -ItemType Directory -Path $Portable | Out-Null }
  $ZipFile = Join-Path $env:TEMP "ImageMagick-$Version.zip"
  $ExtractPath = Join-Path $Portable "_extract"
  try{
    Write-Host "Downloading ImageMagick $Version..." -ForegroundColor Cyan
    Invoke-WebRequest -Uri $DownloadUrl -OutFile $ZipFile -TimeoutSec 60
    if(Test-Path $ExtractPath){ Remove-Item $ExtractPath -Recurse -Force -ErrorAction SilentlyContinue }
    Expand-Archive -Path $ZipFile -DestinationPath $ExtractPath -Force
    $MagickExe = Get-ChildItem -Path $ExtractPath -Recurse -Filter magick.exe | Select-Object -First 1
    if(-not $MagickExe){ throw "magick.exe not found in archive" }
    $SourceRoot = $MagickExe.DirectoryName
    Copy-Item -Path (Join-Path $SourceRoot '*') -Destination $Portable -Recurse -Force
    # Clean up nested folders from previous installs
    Get-ChildItem -Path $Portable -Directory -ErrorAction SilentlyContinue |
      Where-Object { $_.Name -like 'ImageMagick-*-portable-*' } |
      Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item $ExtractPath -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item $ZipFile -Force -ErrorAction SilentlyContinue
    $FinalMagick = Join-Path $Portable "magick.exe"
    if(Test-Path $FinalMagick){ Add-ToUserPath $Portable; return $FinalMagick }
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
  $DownloadUrl = if($Latest.Available){ $Latest.DownloadUrl } else { $FallbackUrl }
  $Version = if($Latest.Available){ $Latest.Version } else { "fallback" }
  $MagickPath = Install-ImageMagickPortable -DownloadUrl $DownloadUrl -Version $Version
  return $MagickPath
}

function Get-Images($Directory){ Get-ChildItem -Path $Directory -Filter *.png -File }

function New-RegistryFiles {
  param([string]$InstallPath, [string]$IconPath, [string]$ScriptRoot)
  
  try {
    # Escape paths for registry format (double backslashes)
    $ScriptPathEsc = (Join-Path $InstallPath "OP-ScreenAssembly.ps1") -replace '\\', '\\'
    $IconPathEsc = if($IconPath) { $IconPath -replace '\\', '\\' } else { '' }
    
    # Find template files
    $InstallTemplate = Join-Path (Join-Path $ScriptRoot "assets") "Install_Context_Menu.reg.template"
    $UninstallTemplate = Join-Path (Join-Path $ScriptRoot "assets") "Uninstall_Context_Menu.reg.template"
    
    if(Test-Path $InstallTemplate) {
      # Read install template and replace placeholders
      $InstallContent = Get-Content -Path $InstallTemplate -Raw -Encoding UTF8
      $InstallContent = $InstallContent -replace '\{\{SCRIPT_PATH\}\}', $ScriptPathEsc
      $InstallContent = $InstallContent -replace '\{\{ICON_PATH\}\}', $IconPathEsc
      
      # Write install registry file
      $InstallRegPath = Join-Path $InstallPath "Install_Context_Menu.reg"
      Set-Content -Path $InstallRegPath -Value $InstallContent -Encoding UTF8 -Force
    } else {
      Write-Host "Warning: Install template not found at $InstallTemplate" -ForegroundColor Yellow
      $InstallRegPath = $null
    }
    
    if(Test-Path $UninstallTemplate) {
      # Read uninstall template (no replacements needed)
      $UninstallContent = Get-Content -Path $UninstallTemplate -Raw -Encoding UTF8
      
      # Write uninstall registry file
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
    if(-not (Test-Path $InstallDir)){ New-Item -ItemType Directory -Path $InstallDir | Out-Null }
    $ScriptSrc = if($PSCommandPath){ $PSCommandPath } else { $MyInvocation.MyCommand.Path }
    $ScriptDest = Join-Path $InstallDir "OP-ScreenAssembly.ps1"
    Copy-Item -Path $ScriptSrc -Destination $ScriptDest -Force
    # Try to copy icon from assets directory
    $ScriptRoot = Split-Path -Parent $ScriptSrc
    $IconSrc = Join-Path (Join-Path $ScriptRoot "assets") "Doka.ico"
    $IconDest = Join-Path $InstallDir "Doka.ico"
    if(Test-Path $IconSrc){ Copy-Item -Path $IconSrc -Destination $IconDest -Force } else { $IconDest = $null }
    # Try to copy ASCII art file from assets directory
    $ArtDest = $null
    $ArtSrcCandidates = @(
      (Join-Path (Join-Path $ScriptRoot "assets") "doka_ascii.txt"),
      (Join-Path $ScriptRoot "doka_ascii.txt")
    )
    $ArtSrc = $null
    foreach($Candidate in $ArtSrcCandidates){ if(-not $ArtSrc -and (Test-Path $Candidate)){ $ArtSrc = $Candidate } }
    if($ArtSrc){
      $ArtName = Split-Path -Leaf $ArtSrc
      $ArtDest = Join-Path $InstallDir $ArtName
      Copy-Item -Path $ArtSrc -Destination $ArtDest -Force
    } else {
      # Clean up old art files if none found
      $OldArt = @(
        (Join-Path $InstallDir "doka_ascii_3.txt"),
        (Join-Path $InstallDir "doka_ascii.txt")
      )
      foreach($OldFile in $OldArt){ if(Test-Path $OldFile){ Remove-Item $OldFile -Force -ErrorAction SilentlyContinue } }
    }
  # Ensure install dir is on PATH and provide a convenience shim
  Add-ToUserPath $InstallDir
  $CmdPath = Join-Path $InstallDir "scmontage.cmd"
    # Write as separate lines to ensure proper CRLF without literal backticks; %ENV% expands in cmd at runtime
    $CmdLines = @(
      '@echo off',
      'powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%LOCALAPPDATA%\OP-ScreenAssembly\OP-ScreenAssembly.ps1" %*'
    )
  Set-Content -Path $CmdPath -Value $CmdLines -Encoding ASCII -Force
  # Expose a user env var for direct invocation via $env:SCMONTAGE
  [Environment]::SetEnvironmentVariable("SCMONTAGE", $ScriptDest, "User")
  $env:SCMONTAGE = $ScriptDest
  
  # Generate registry files with current user's paths
  $ScriptRoot = Split-Path -Parent $ScriptSrc
  $RegFiles = New-RegistryFiles -InstallPath $InstallDir -IconPath $IconDest -ScriptRoot $ScriptRoot
  
  return @{ ScriptPath=$ScriptDest; IconPath=$IconDest; Shim=$CmdPath; ArtPath=$ArtDest; RegFiles=$RegFiles }
  } catch {
    Write-Host "Failed to install tool assets: $($_.Exception.Message)" -ForegroundColor Yellow
    return $null
  }
}

function Get-ImageStats($images,$magick){
  # Returns @{ Mean=<avg brightness>; AvgAR=<avg aspect ratio>; Counts=@{wide;standard;tall} }
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
  $useDark = $avgB -gt 0.5   # bright images -> dark background for contrast
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

function New-Montage([bool]$isPortrait,[bool]$isDark,[string]$inputFolder,[string]$magick,[string]$modeDescription=""){
  $files = Get-Images $inputFolder
  $imageCount = $files.Count
  if($imageCount -le 0){ throw "No PNG files found in '$inputFolder'" }
  $folderInfo = Get-Item $inputFolder
  $folderName = $folderInfo.Name
  $outputFolder = $folderInfo.Parent.FullName

  $orientation = if($isPortrait){'portrait'}else{'landscape'}
  $orientationText = if($isPortrait){'Portrait'}else{'Wide'}
  $themeText = if($isDark){'Dark'}else{'Light'}
  $grid = Get-OptimalGrid -count $imageCount -orientation $orientation
  $bg   = if($isDark){"#1e1e1e"}else{"#e6e6e6"}
  $bor  = if($isDark){"#fc59a3"}else{"#8e3ccb"}
  $suffix = if($modeDescription -eq "Auto"){"_Auto"}else{""}
  $outFile = "${orientationText}_${themeText}_${folderName}${suffix}.png"
  $outPath = Join-Path $outputFolder $outFile

  Write-Host ("Creating {0} {1} montage ({2}x{3})..." -f $orientationText,$themeText,$grid.Columns,$grid.Rows) -ForegroundColor Cyan
  $tile = "$($grid.Columns)x$($grid.Rows)"
  $imArgs = @('montage')
  foreach($f in $files){ $imArgs += $f.FullName }
  $imArgs += @('-tile', $tile, '-geometry', '+12+12', '-background', $bg, '-bordercolor', $bor, '-border', '6', '-shadow', '-quality', '95', '-density', '150', $outPath)
  & $magick @imArgs
  if($LASTEXITCODE -eq 0){ Write-Host "SUCCESS: $outFile" -ForegroundColor Green; return $true }
  else { Write-Host "FAILED: $outFile (exit $LASTEXITCODE)" -ForegroundColor Red; return $false }
}

function Main {
  # Setup mode: install/update ImageMagick and tool assets
  if($setup){
    $magick = Initialize-ImageMagick -forceUpdate:$false
    if($magick){
      Write-Host "Setup completed successfully." -ForegroundColor Green
      Write-Host "You can now use 'magick' from any terminal." -ForegroundColor Cyan
      $assets = Install-ToolAssets
      if($assets){
        Write-Host ("Installed tool to: {0}" -f $InstallDir) -ForegroundColor Green
        if($assets.Shim -and (Test-Path $assets.Shim)){
          Write-Host ("Run: scmontage -a <folder>") -ForegroundColor DarkGray
        }
        if($env:SCMONTAGE){
          Write-Host ("User env var SCMONTAGE -> $env:SCMONTAGE") -ForegroundColor DarkGray
        }
        if($assets.RegFiles -and $assets.RegFiles.InstallReg){
          Write-Host ("Registry files generated: Install_Context_Menu.reg & Uninstall_Context_Menu.reg") -ForegroundColor DarkGray
        }
      }
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
      return
    } else {
      Write-Host "Setup failed." -ForegroundColor Red
      Show-Footer -success $false -Lines @('  Install failed')
      exit 1
    }
  }

  # Reinstall-only mode: refresh installed script/shim/env without IM update
  if($reinstall){
    $assets = Install-ToolAssets
    if($assets){
      Write-Host "Tool assets refreshed successfully." -ForegroundColor Green
      if($assets.Shim -and (Test-Path $assets.Shim)){
        Write-Host ("Run: scmontage -a <folder>") -ForegroundColor DarkGray
      }
      if($env:SCMONTAGE){ Write-Host ("User env var SCMONTAGE -> $env:SCMONTAGE") -ForegroundColor DarkGray }
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
      return
    } else {
      Write-Host "Reinstall failed." -ForegroundColor Red
      Show-Footer -success $false -Lines @('  Reinstall failed')
      exit 1
    }
  }

  # Default to automatic mode if no flags provided (like full script)
  if(-not ($p -or $w -or $d -or $l -or $t -or $a)){ Write-Host "No mode specified - defaulting to automatic (-a)" -ForegroundColor Yellow; $a=$true }

  $magick = Initialize-ImageMagick
  if(-not $magick){ Write-Host "ImageMagick setup failed." -ForegroundColor Red; Show-Footer $false; exit 1 }

  if(-not $Folder){ Write-Host "Provide a folder path." -ForegroundColor Red; Show-Footer $false; exit 1 }
  if(-not (Test-Path $Folder -PathType Container)){ Write-Host "Folder not found: $Folder" -ForegroundColor Red; Show-Footer $false; exit 1 }

  $images = Get-Images $Folder
  if(-not $images -or $images.Count -eq 0){ Write-Host "No PNGs found in: $Folder" -ForegroundColor Red; Show-Footer $false; exit 1 }
  Write-Host ("Found {0} PNG files" -f $images.Count) -ForegroundColor Green

  if($a){
    $s = Get-AutomaticSettings $images $magick
    $ok = New-Montage -isPortrait $s.UsePortrait -isDark $s.UseDark -inputFolder $Folder -magick $magick -modeDescription "Auto"
    Show-Footer $ok; if(-not $ok){ exit 1 }; return
  }

  if(-not $t){
    if(-not ($p -xor $w)){ Write-Host "Choose either -p (portrait) or -w (landscape); falling back to -a" -ForegroundColor Yellow; $a=$true; return (Main) }
    if(-not ($d -xor $l)){ Write-Host "Choose either -d (dark) or -l (light); falling back to -a" -ForegroundColor Yellow; $a=$true; return (Main) }
  }

  if($t){
    Write-Host "TEST MODE: creating all 4 combinations..." -ForegroundColor Magenta
  $ok=0
  foreach($pr in $true,$false){ foreach($dk in $true,$false){ if(New-Montage $pr $dk $Folder $magick "Test"){ $ok++ } }}
    Write-Host ("Test completed: {0}/4 successful" -f $ok) -ForegroundColor ($(if($ok -eq 4){'Green'}else{'Yellow'}))
    Show-Footer ($ok -eq 4); return
  }

  $ok2 = New-Montage -isPortrait $p -isDark $d -inputFolder $Folder -magick $magick -modeDescription "Manual"
  Show-Footer $ok2; if(-not $ok2){ exit 1 }
}

try { Main } catch { Write-Host $_.Exception.Message -ForegroundColor Red; Show-Footer $false; exit 1 }
