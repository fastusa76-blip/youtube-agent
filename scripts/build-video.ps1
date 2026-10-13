[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Project,
    [int]$SecondsPerImage = 8,
    [switch]$Overwrite
)
$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path -Parent $PSScriptRoot
if ([System.IO.Path]::IsPathRooted($Project)) { $ProjectPath = [System.IO.Path]::GetFullPath($Project) }
else { $ProjectPath = [System.IO.Path]::GetFullPath((Join-Path (Join-Path $RepoRoot "video-projects") $Project)) }
if (-not (Test-Path -LiteralPath $ProjectPath)) { throw "Project folder not found: $ProjectPath" }
$ffmpeg = Get-Command ffmpeg -ErrorAction SilentlyContinue
if (-not $ffmpeg) { throw "FFmpeg is not installed or not on PATH. Install FFmpeg, open a new PowerShell window, then verify with: ffmpeg -version" }
$VisualsPath = Join-Path $ProjectPath "visuals"
if (-not (Test-Path -LiteralPath $VisualsPath)) { throw "Create a visuals folder and add licensed image files first: $VisualsPath" }
$images = @(Get-ChildItem -LiteralPath $VisualsPath -File | Where-Object { $_.Extension -match '^\.(png|jpg|jpeg|webp)$' } | Sort-Object Name)
if ($images.Count -eq 0) { throw "No PNG/JPG/JPEG/WEBP images found in $VisualsPath" }
$audioCandidates = @("narration.mp3","narration.wav","narration.m4a") | ForEach-Object { Join-Path $ProjectPath $_ }
$audio = $audioCandidates | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
$outputPath = Join-Path $ProjectPath "final-video.mp4"
if ((Test-Path -LiteralPath $outputPath) -and -not $Overwrite) { throw "Output already exists: $outputPath. Use -Overwrite to replace it." }
$listPath = Join-Path $ProjectPath "ffmpeg-concat-list.txt"
$lines = [System.Collections.Generic.List[string]]::new()
foreach ($img in $images) {
    $safePath = $img.FullName.Replace('\','/').Replace("'","'\''")
    $lines.Add("file '$safePath'")
    $lines.Add("duration $SecondsPerImage")
}
$safeLast = $images[-1].FullName.Replace('\','/').Replace("'","'\''")
$lines.Add("file '$safeLast'")
Set-Content -LiteralPath $listPath -Value ($lines -join [Environment]::NewLine) -Encoding utf8
$videoFilter = "scale=1920:1080:force_original_aspect_ratio=decrease,pad=1920:1080:(ow-iw)/2:(oh-ih)/2,format=yuv420p"
$args = @("-y","-f","concat","-safe","0","-i",$listPath)
if ($audio) { $args += @("-i",$audio,"-vf",$videoFilter,"-c:v","libx264","-preset","medium","-crf","23","-r","30","-c:a","aac","-b:a","192k","-shortest",$outputPath) }
else { $args += @("-vf",$videoFilter,"-c:v","libx264","-preset","medium","-crf","23","-r","30","-an",$outputPath) }
Write-Host "Building a 1080p slideshow video from $($images.Count) images..." -ForegroundColor Cyan
if ($audio) { Write-Host "Narration audio found: $audio" } else { Write-Host "No narration audio found; creating a silent video. Add narration.mp3 or narration.wav to include voiceover." }
& $ffmpeg.Source @args
if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $outputPath)) { throw "FFmpeg failed to create the MP4. Review the FFmpeg output above." }
Write-Host ""
Write-Host "Video created: $outputPath" -ForegroundColor Green
Write-Host "This builder uses still images and optional narration; it does not generate AI motion clips."
Write-Host "Review the full MP4 and final-review.md before uploading."
