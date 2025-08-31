param(
    [switch]$p,  # Portrait
    [switch]$w,  # Landscape
    [switch]$d,  # Dark mode
    [switch]$l,  # Light mode
    [switch]$t,  # Test mode - create all 4 combinations
    [switch]$a,  # Automatic mode - detect optimal settings
    [switch]$setup,  # Force setup/update of ImageMagick
    [Parameter(Mandatory=$false, Position=0)]
    [string]$Folder
)

# Tool Information
$ToolName = "OP-ScreenAssembly"
$Version = "v1.0"
$Department = "Operations"

# Display Branding with DOKA ASCII art
function Show-Footer {
    param([bool]$success = $true)
    
    Write-Host ""
    Write-Host "╔════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║                                                                    ║" -ForegroundColor Cyan
    Write-Host "║  ██████╗  ██████╗ ██╗  ██╗ █████╗                ██████╗ ██████╗   ║" -ForegroundColor Yellow
    Write-Host "║  ██╔══██╗██╔═══██╗██║ ██╔╝██╔══██╗              ██╔═══██╗██╔══██╗  ║" -ForegroundColor Yellow
    Write-Host "║  ██║  ██║██║   ██║█████╔╝ ███████║   ███████║   ██║   ██║██████╔╝  ║" -ForegroundColor Yellow
    Write-Host "║  ██║  ██║██║   ██║██╔═██╗ ██╔══██║   ╚══════╝   ██║   ██║██╔═══╝   ║" -ForegroundColor Yellow
    Write-Host "║  ██████╔╝╚██████╔╝██║  ██╗██║  ██║              ╚██████╔╝██║       ║" -ForegroundColor Yellow
    Write-Host "║  ╚═════╝  ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝               ╚═════╝ ╚═╝       ║" -ForegroundColor Yellow
    Write-Host "║                                                                    ║" -ForegroundColor Cyan
    Write-Host "║              ScreenAssembly Tool - Made by ezellhof                ║" -ForegroundColor Blue
    Write-Host "║     Powered by ImageMagick® - Open Source Image Processing         ║" -ForegroundColor DarkGray
    if ($success) {
        Write-Host "║  Your Sceenshot Montage have been assembled with DOKA precision!   ║" -ForegroundColor Green
    } else {
        Write-Host "║     Assembly FAILED     - Please check errors and try again        ║" -ForegroundColor Red
    }
    Write-Host "╚════════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
}

# Global variables
$ImageMagickPath = ""
$PortableDir = Join-Path $env:LOCALAPPDATA "ImageMagick-Portable"

# Function to get current ImageMagick version
function Get-InstalledVersion {
    try {
        # Try system PATH first
        $version = & "magick" "--version" 2>$null | Select-Object -First 1
        if ($version -match "ImageMagick (\d+\.\d+\.\d+-\d+)") {
            return @{
                Version = $matches[1]
                Path = "magick"  # Available in PATH
                Available = $true
            }
        }
    } catch {
        # System version not available
    }
    
    # Try portable installation - magick.exe should be directly in PortableDir
    $portableMagick = Join-Path $PortableDir "magick.exe"
    if (Test-Path $portableMagick) {
        try {
            $version = & $portableMagick "--version" 2>$null | Select-Object -First 1
            if ($version -match "ImageMagick (\d+\.\d+\.\d+-\d+)") {
                return @{
                    Version = $matches[1]
                    Path = $portableMagick
                    Available = $true
                }
            }
        } catch {
            # Portable version corrupted
        }
    }
    
    return @{Available = $false}
}

# Function to get latest version from ImageMagick website
function Get-LatestVersion {
    try {
        Write-Host "Checking latest ImageMagick version..." -ForegroundColor Yellow
        $response = Invoke-WebRequest -Uri "https://imagemagick.org/script/download.php#windows" -UseBasicParsing -TimeoutSec 10
        
        # Look for Windows portable download links
        if ($response.Content -match "ImageMagick-(\d+\.\d+\.\d+-\d+)-portable-Q16-HDRI-x64\.zip") {
            return @{
                Version = $matches[1]
                DownloadUrl = "https://imagemagick.org/archive/binaries/ImageMagick-$($matches[1])-portable-Q16-HDRI-x64.zip"
                Available = $true
            }
        }
        
        Write-Host "Could not parse latest version from website" -ForegroundColor Yellow
        return @{Available = $false}
    } catch {
        Write-Host "Failed to check latest version: $($_.Exception.Message)" -ForegroundColor Yellow
        return @{Available = $false}
    }
}

# Function to download and install ImageMagick portable
function Install-ImageMagickPortable {
    param([string]$downloadUrl, [string]$version)
    
    Write-Host "`nDownloading ImageMagick $version..." -ForegroundColor Cyan
    
    # Create directories
    if (Test-Path $PortableDir) {
        Remove-Item $PortableDir -Recurse -Force
    }
    New-Item -ItemType Directory -Path $PortableDir -Force | Out-Null
    
    $zipPath = Join-Path $PortableDir "ImageMagick-$version.zip"
    $tempExtractDir = Join-Path $PortableDir "temp_extract"
    
    try {
        # Download with simple progress indicator
        $uri = [System.Uri]$downloadUrl
        $webRequest = [System.Net.HttpWebRequest]::Create($uri)
        $webRequest.Method = "GET"
        
        $webResponse = $webRequest.GetResponse()
        $totalBytes = $webResponse.ContentLength
        $responseStream = $webResponse.GetResponseStream()
        
        $fileStream = [System.IO.File]::Create($zipPath)
        $buffer = New-Object byte[] 8192
        $totalBytesRead = 0
        
        do {
            $bytesRead = $responseStream.Read($buffer, 0, $buffer.Length)
            if ($bytesRead -gt 0) {
                $fileStream.Write($buffer, 0, $bytesRead)
                $totalBytesRead += $bytesRead
                
                if ($totalBytes -gt 0) {
                    $percent = [math]::Round(($totalBytesRead / $totalBytes) * 100, 1)
                    Write-Progress -Activity "Downloading ImageMagick" -Status "$percent% Complete ($([math]::Round($totalBytesRead/1MB, 1)) MB)" -PercentComplete $percent
                }
            }
        } while ($bytesRead -gt 0)
        
        $fileStream.Close()
        $responseStream.Close()
        $webResponse.Close()
        
        Write-Progress -Activity "Downloading ImageMagick" -Completed
        Write-Host "Download completed. Extracting..." -ForegroundColor Green
        
        # Extract to temporary directory
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        [System.IO.Compression.ZipFile]::ExtractToDirectory($zipPath, $tempExtractDir)
        
        # Find the extracted ImageMagick directory
        $extractedSubDir = Get-ChildItem -Path $tempExtractDir -Directory | Where-Object { $_.Name -like "ImageMagick-*-portable-*" } | Select-Object -First 1
        
        if ($extractedSubDir) {
            # Move all files from subdirectory to PortableDir root
            Write-Host "Flattening directory structure..." -ForegroundColor Yellow
            $sourceDir = $extractedSubDir.FullName
            Get-ChildItem -Path $sourceDir | Move-Item -Destination $PortableDir
        } else {
            Write-Host "Warning: Expected subdirectory structure not found, extracting directly" -ForegroundColor Yellow
            Get-ChildItem -Path $tempExtractDir | Move-Item -Destination $PortableDir
        }
        
        # Clean up temporary files
        Remove-Item $tempExtractDir -Recurse -Force -ErrorAction SilentlyContinue
        Remove-Item $zipPath -Force -ErrorAction SilentlyContinue
        
        # Verify installation
        $magickExe = Join-Path $PortableDir "magick.exe"
        if (Test-Path $magickExe) {
            Write-Host "ImageMagick installed successfully!" -ForegroundColor Green
            Write-Host "Location: $magickExe" -ForegroundColor Gray
            
            # Add PortableDir to user PATH
            Add-ToUserPath -pathToAdd $PortableDir
            
            return $magickExe
        } else {
            Write-Host "Installation failed - magick.exe not found" -ForegroundColor Red
            return $null
        }
        
    } catch {
        Write-Host "Installation failed: $($_.Exception.Message)" -ForegroundColor Red
        # Clean up on failure
        if (Test-Path $zipPath) { Remove-Item $zipPath -Force -ErrorAction SilentlyContinue }
        if (Test-Path $tempExtractDir) { Remove-Item $tempExtractDir -Recurse -Force -ErrorAction SilentlyContinue }
        return $null
    }
}

# Function to add directory to user PATH
function Add-ToUserPath {
    param([string]$pathToAdd)
    
    try {
        $currentPath = [Environment]::GetEnvironmentVariable("PATH", "User")
        
        if ($currentPath -notlike "*$pathToAdd*") {
            Write-Host "Adding ImageMagick to user PATH..." -ForegroundColor Yellow
            $newPath = if ($currentPath) { "$currentPath;$pathToAdd" } else { $pathToAdd }
            [Environment]::SetEnvironmentVariable("PATH", $newPath, "User")
            
            # Update current session
            $env:PATH += ";$pathToAdd"
            
            Write-Host "Added to PATH. You may need to restart your terminal for system-wide access." -ForegroundColor Green
        } else {
            Write-Host "ImageMagick already in user PATH" -ForegroundColor Green
        }
    } catch {
        Write-Host "Could not modify user PATH: $($_.Exception.Message)" -ForegroundColor Yellow
        Write-Host "You can manually add '$pathToAdd' to your user PATH" -ForegroundColor Yellow
    }
}

# Function to setup ImageMagick
function Setup-ImageMagick {
    param([bool]$forceUpdate = $false)
    
    Write-Host "Checking ImageMagick installation..." -ForegroundColor Cyan
    
    $installed = Get-InstalledVersion
    $latest = Get-LatestVersion
    
    if (!$latest.Available) {
        Write-Host "Cannot determine latest version. Using existing installation if available." -ForegroundColor Yellow
        if ($installed.Available) {
            return $installed.Path
        } else {
            Write-Host "No ImageMagick installation found and cannot download latest version." -ForegroundColor Red
            return $null
        }
    }
    
    $needsInstall = $false
    
    if (!$installed.Available) {
        Write-Host "ImageMagick not found." -ForegroundColor Yellow
        $needsInstall = $true
    } elseif ($installed.Version -ne $latest.Version -or $forceUpdate) {
        Write-Host "Current version: $($installed.Version)" -ForegroundColor Yellow
        Write-Host "Latest version: $($latest.Version)" -ForegroundColor Yellow
        $needsInstall = $true
    } else {
        Write-Host "ImageMagick $($installed.Version) is up to date!" -ForegroundColor Green
        return $installed.Path
    }
    
    if ($needsInstall) {
        $result = Install-ImageMagickPortable -downloadUrl $latest.DownloadUrl -version $latest.Version
        if ($result) {
            return "magick"  # Should now be available in PATH
        } else {
            return $null
        }
    }
    
    return $installed.Path
}

# Setup mode - just install/update ImageMagick
if ($setup) {
    Show-Footer  # ADD THIS LINE
    $result = Setup-ImageMagick -forceUpdate $true
    if ($result) {
        Write-Host "`nSetup completed successfully!" -ForegroundColor Green
        Write-Host "You can now use 'magick' command from any terminal." -ForegroundColor Cyan
        Show-Footer -success $true  # ADD THIS LINE
    } else {
        Write-Host "`nSetup failed!" -ForegroundColor Red
        Show-Footer -success $false  # ADD THIS LINE
    }
    exit
}

# Validate folder parameter for montage operations
if (!$Folder) {
    Write-Host "Error: Folder parameter is required for montage operations" -ForegroundColor Red
    Write-Host "Usage: .\script.ps1 -setup  OR  .\script.ps1 -a folder_path" -ForegroundColor Yellow
    Show-Footer -success $false  # ADD THIS LINE
    exit 1
}

# Automatic Setup and Error Footer
$ImageMagickPath = Setup-ImageMagick
if (!$ImageMagickPath) {
    Write-Host "ImageMagick setup failed. Cannot proceed." -ForegroundColor Red
    Show-Footer -success $false  # ADD THIS LINE
    exit 1
}

# Default to Automatic mode if no flags are provided (4 the lazy ones)
if (-not ($p -or $w -or $d -or $l -or $t -or $a)) {
    Write-Host "No mode specified - defaulting to automatic mode (-a)" -ForegroundColor Yellow
    $a = $true
}

# Enhanced validation logic for Flags and the lazy Option (PowerShell HELL maybe because of vibecoding)
if ($a) {
    Write-Host "`nAUTOMATIC MODE: Analyzing images to determine optimal settings..." -ForegroundColor Magenta
} elseif (-not $t) {
    if (-not ($p -xor $w)) {
        Write-Host "Error: Choose either -p (portrait) or -w (landscape), or use -t for test mode, or -a for automatic" -ForegroundColor Red
        Write-Host "Defaulting to automatic mode (-a)..." -ForegroundColor Yellow
        $a = $true
        $p = $false
        $w = $false
        $d = $false
        $l = $false
    }
    if (-not ($d -xor $l) -and -not $a) {
        Write-Host "Error: Choose either -d (dark) or -l (light), or use -t for test mode, or -a for automatic" -ForegroundColor Red
        Write-Host "Defaulting to automatic mode (-a)..." -ForegroundColor Yellow
        $a = $true
        $p = $false
        $w = $false
        $d = $false
        $l = $false
    }
}

# Check if Folder exists
# (WIP) MAKE IT COOL RECURSIVE WITH -m for MASS OPTION
if (-not (Test-Path $Folder -PathType Container)) {
    Write-Host "Error: Folder '$Folder' does not exist" -ForegroundColor Red
    exit 1
}

# Get all PNG files in the folder
# (WIP) MAKE IT eat all Files
$pngFiles = Get-ChildItem -Path $Folder -Filter "*.png"
$imageCount = $pngFiles.Count

if ($imageCount -eq 0) {
    Write-Host "Error: No PNG files found in '$Folder'" -ForegroundColor Red
    exit 1
}

Write-Host "Found $imageCount PNG files" -ForegroundColor Green

# Function to analyze image brightness
function Get-ImageBrightness {
    param([string]$imagePath)
    
    try {
        $result = & "magick" "identify" "-format" "%[fx:mean]" $imagePath 2>$null
        return [double]$result
    } catch {
        Write-Host "Warning: Could not analyze brightness for $imagePath" -ForegroundColor Yellow
        return 0.5
    }
}

# Function to get image dimensions (Later used for Aspect Ratio determination)
function Get-ImageDimensions {
    param([string]$imagePath)
    
    try {
        $result = & "magick" "identify" "-format" "%wx%h" $imagePath 2>$null
        $dimensions = $result -split 'x'
        return @{Width = [int]$dimensions[0]; Height = [int]$dimensions[1]}
    } catch {
        Write-Host "Warning: Could not get dimensions for $imagePath" -ForegroundColor Yellow
        return @{Width = 1920; Height = 1080}
    }
}

# "-a" Flag => Function to determine optimal settings automatically
function Get-AutomaticSettings {
    param([array]$imageFiles)
    
    Write-Host "Analyzing image brightness and dimensions..." -ForegroundColor Yellow
    
    $totalBrightness = 0
    $totalAspectRatio = 0
    $wideImages = 0      # Widescreen formats (16:9, 16:10, cinema, etc.)
    $tallImages = 0      # Portrait formats (phone vertical, etc.)
    $standardImages = 0  # Traditional formats (Something inbetween) (4:3, 5:4, 3:2)
    
    # Loop for checking through all the selected Pictures
    # (WIP) for the -mass Flag and Recursiveness in General
    foreach ($file in $imageFiles) {
        $brightness = Get-ImageBrightness -imagePath $file.FullName
        $totalBrightness += $brightness
        
        $dims = Get-ImageDimensions -imagePath $file.FullName
        $aspectRatio = $dims.Width / $dims.Height
        $totalAspectRatio += $aspectRatio
        
        if ($aspectRatio -ge 1.6) { 
            $wideImages++
        } elseif ($aspectRatio -le 0.8) { 
            $tallImages++
        } else { 
            $standardImages++
        }
    }
    
    # Determine Dark/Light Mode => Check Screenshots for their Avrage Brightness 
    $avgBrightness = $totalBrightness / $imageFiles.Count
    $useDark = $avgBrightness -gt 0.5
    $brightnessPercent = [math]::Round($avgBrightness * 100, 0)
    $themeReason = if ($useDark) { "images are bright ($brightnessPercent% brightness)" } else { "images are dark ($brightnessPercent% brightness)" }
    
    # Determine Aspect Ratio 
    $avgAspectRatio = $totalAspectRatio / $imageFiles.Count
    $perfectSquares = @(1, 4, 9, 16, 25)
    
    $usePortrait = if ($perfectSquares -contains $imageFiles.Count) {
        $orientationReason = "perfect square grid ($([math]::Sqrt($imageFiles.Count))x$([math]::Sqrt($imageFiles.Count))) layout"
        $true
    } elseif ($imageFiles.Count -le 3) {
        $orientationReason = "few images work better in portrait layout"
        $true
    } elseif ($imageFiles.Count -ge 12) {
        $orientationReason = "many images: average aspect ratio is $([math]::Round($avgAspectRatio, 2))"
        $avgAspectRatio -lt 1.2
    } else {
        $orientationReason = "image analysis: $wideImages widescreen, $standardImages standard, $tallImages portrait"
        ($tallImages -gt $wideImages) -or ($avgAspectRatio -lt 1.1)
    }
    
    Write-Host "Auto-detected settings:" -ForegroundColor Cyan
    Write-Host "  Theme: $( if ($useDark) { 'Dark' } else { 'Light' } ) ($themeReason)" -ForegroundColor White
    Write-Host "  Orientation: $( if ($usePortrait) { 'Portrait' } else { 'Wide' } ) ($orientationReason)" -ForegroundColor White
    
    return @{
        UseDark = $useDark
        UsePortrait = $usePortrait
    }
}

# Calculate optimal grid layout => Based on how many Images and their Aspect Ratios
function Get-OptimalGrid {
    param([int]$count, [string]$orientation)
    
    $bestCols = 1
    $bestRows = $count
    $targetRatio = if ($orientation -eq "portrait") { 0.75 } else { 1.33 }
    $bestDiff = [Math]::Abs(($bestCols / $bestRows) - $targetRatio)
    
    for ($cols = 1; $cols -le $count; $cols++) {
        $rows = [Math]::Ceiling($count / $cols)
        $ratio = $cols / $rows
        $diff = [Math]::Abs($ratio - $targetRatio)
        
        if ($diff -lt $bestDiff) {
            $bestCols = $cols
            $bestRows = $rows
            $bestDiff = $diff
        }
    }
    
    return @{Columns = $bestCols; Rows = $bestRows}
}

# If you made it till here high5 you are actually tring to read what you execute <3
# We are done ANALysing the selected Screenshots and
# We will craft the the ImageMagick Command here
# ImageMagik (https://github.com/ImageMagick/ImageMagick)
# (Made by actual S-Tier Programers and given away for Free) 
# They make no Money of it so go and Support the Real Project if you like it (https://github.com/sponsors/ImageMagick)
# Dont think my PowerShell AI Mess here can do cool Montages you F00L ;)

# Function to create Screenshoot-Montage with now kown settings
function Create-Montage {
    param(
        [bool]$isPortrait,
        [bool]$isDark,
        [string]$inputFolder,
        [string]$outputFolder,
        [string]$folderName,
        [int]$imageCount,
        [string]$modeDescription = ""
    )
    
    $orientation = if ($isPortrait) { "portrait" } else { "landscape" }
    $orientationText = if ($isPortrait) { "Portrait" } else { "Wide" }
    $themeText = if ($isDark) { "Dark" } else { "Light" }
    
    $grid = Get-OptimalGrid -count $imageCount -orientation $orientation
    
    $displayMode = if ($modeDescription) { " ($modeDescription)" } else { "" }
    Write-Host "`nCreating $orientationText $themeText montage$displayMode..." -ForegroundColor Cyan
    Write-Host "Layout: $($grid.Columns) columns x $($grid.Rows) rows" -ForegroundColor Yellow
    
    $backgroundColor = if ($isDark) { "#1e1e1e" } else { "#e6e6e6" }
    $borderColor = if ($isDark) { "#fc59a3" } else { "#8e3ccb" }
    
    $suffix = if ($modeDescription) { "_Auto" } else { "" }
    $filename = "${orientationText}_${themeText}_${folderName}${suffix}.png"
    $outputPath = Join-Path $outputFolder $filename
    $inputPattern = Join-Path $inputFolder "*.png"
    
    # Craft the final Magick Command
    $magickCommand = @(
        "magick", "montage"
        $inputPattern
        "-tile", "$($grid.Columns)x$($grid.Rows)"
        "-geometry", "+12+12" # 12px x 2 => 24px spacing between images  
        "-background", $backgroundColor
        "-bordercolor", $borderColor
        "-border", "6" # 6px border around Screenshots # if i think about a colorpicker logic i will never do this actually :D
        "-shadow" # Add subtle drop shadow
        "-quality", "95" # High quality output 95/100
        "-density", "150" # Good resolution for screen viewing
        $outputPath
    )
    
    # Clean the Crafted ImageMagick Command and display it in a clean way
    $displayCommand = "magick montage `"$inputPattern`" -tile $($grid.Columns)x$($grid.Rows) -geometry +12+12 -background $backgroundColor -bordercolor $borderColor -border 3 -shadow -quality 95 -density 150"
    Write-Host "Command: $displayCommand" -ForegroundColor DarkGray ## Change Color to Red for debugging
    
    try {
        & $magickCommand[0] $magickCommand[1..($magickCommand.Length-1)]
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "SUCCESS: $filename" -ForegroundColor Green
            return $true
        } else {
            Write-Host "FAILED: $filename (exit code $LASTEXITCODE)" -ForegroundColor Red
            return $false
        }
    } catch {
        Write-Host "ERROR: $filename - $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Get folder name and output directory
$folderInfo = Get-Item $Folder
$folderName = $folderInfo.Name
$outputFolder = $folderInfo.Parent.FullName

Write-Host "Output folder: $outputFolder" -ForegroundColor Yellow

# Error handling for Output => did it work yes/no
# Forget the Footer Stuff its for the ASCII Branding
if ($a) {
    $autoSettings = Get-AutomaticSettings -imageFiles $pngFiles
    $success = Create-Montage -isPortrait $autoSettings.UsePortrait -isDark $autoSettings.UseDark -inputFolder $Folder -outputFolder $outputFolder -folderName $folderName -imageCount $imageCount -modeDescription "Auto"
    
    if ($success) {
        Write-Host "`nAutomatic montage completed successfully!" -ForegroundColor Green
        Show-Footer -success $true  # ADD THIS LINE
    } else {
        Write-Host "`nAutomatic montage creation failed!" -ForegroundColor Red
        Show-Footer -success $false  # ADD THIS LINE
        exit 1
    }
} elseif ($t) {
    Write-Host "`nTEST MODE: Creating all 4 combinations..." -ForegroundColor Magenta
    
    $combinations = @(
        @{Portrait=$true; Dark=$true; Name="Portrait_Dark"},
        @{Portrait=$true; Dark=$false; Name="Portrait_Light"},
        @{Portrait=$false; Dark=$true; Name="Wide_Dark"},
        @{Portrait=$false; Dark=$false; Name="Wide_Light"}
    )
    
    $successCount = 0
    foreach ($combo in $combinations) {
        $success = Create-Montage -isPortrait $combo.Portrait -isDark $combo.Dark -inputFolder $Folder -outputFolder $outputFolder -folderName $folderName -imageCount $imageCount
        if ($success) { $successCount++ }
    }
    
    Write-Host "`nTest completed: $successCount/4 montages created successfully" -ForegroundColor $(if ($successCount -eq 4) { "Green" } else { "Yellow" })
    Show-Footer -success ($successCount -eq 4)  # ADD THIS LINE
} else {
    $success = Create-Montage -isPortrait $p -isDark $d -inputFolder $Folder -outputFolder $outputFolder -folderName $folderName -imageCount $imageCount
    
    if ($success) {
        Write-Host "`nMontage completed successfully!" -ForegroundColor Green
        Show-Footer -success $true  # ADD THIS LINE
    } else {
        Write-Host "`nMontage creation failed!" -ForegroundColor Red
        Show-Footer -success $false  # ADD THIS LINE
        exit 1
    }
}