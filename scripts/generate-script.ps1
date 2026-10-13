[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$Title,
    [string]$Model = "qwen2.5:7b",
    [string]$OllamaUrl = "http://localhost:11434"
)
$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path -Parent $PSScriptRoot
$ConfigPath = Join-Path $RepoRoot "config\channel.json"
$OutputRoot = Join-Path $RepoRoot "video-projects"
$Slug = (($Title.ToLowerInvariant() -replace '[^a-z0-9]+', '-') -replace '(^-|-$)', '')
if ([string]::IsNullOrWhiteSpace($Slug)) { $Slug = "video-$(Get-Date -Format 'yyyyMMdd-HHmmss')" }
$ProjectPath = Join-Path $OutputRoot $Slug
if (-not (Test-Path -LiteralPath $ConfigPath)) { throw "Missing channel config: $ConfigPath" }
if (-not (Test-Path -LiteralPath $ProjectPath)) { & (Join-Path $PSScriptRoot "new-video.ps1") -Title $Title }
$config = Get-Content -LiteralPath $ConfigPath -Raw | ConvertFrom-Json
try {
    $null = Invoke-RestMethod -Method Get -Uri "$($OllamaUrl.TrimEnd('/'))/api/tags" -TimeoutSec 5
} catch {
    throw "Ollama is not responding at $OllamaUrl. Install Ollama, open it, and pull the model: ollama pull $Model. Original error: $($_.Exception.Message)"
}
$channelContext = "Channel URL: $($config.channelUrl)" + [Environment]::NewLine
$channelContext += "Language: Urdu" + [Environment]::NewLine
$channelContext += "Video type: long-form tutorial" + [Environment]::NewLine
$channelContext += "Audience hypothesis: $($config.defaultAudience). This is a starting hypothesis, not verified analytics."
$prompt = @"
You are a careful Urdu-language YouTube tutorial producer. Return only valid JSON, no markdown fences.
Topic/title: $Title
$channelContext

Create a helpful 6-10 minute Urdu long-form tutorial package. Do not promise virality, invent statistics, or claim research was performed when no sources were supplied. Keep tool names and commands accurate; mark anything needing verification. Avoid copying existing creators' scripts. Use natural Urdu script, not Hindi Devanagari and not Roman Urdu unless a product name requires it.

Return a JSON object with exactly these keys:
{
  "titleOptions": ["three distinct Urdu title options"],
  "hook": "opening hook for the first 15 seconds",
  "intro": "short introduction",
  "scriptSections": [{"heading":"section heading in Urdu","narration":"full narration paragraph(s)","visualNotes":"what should appear on screen"}],
  "storyboard": [{"time":"00:00-00:20","voiceover":"short summary","visual":"visual instruction","onscreenText":"short Urdu text"}],
  "description": "YouTube description in Urdu with clear placeholder if a link or fact needs adding",
  "keywords": ["relevant keyword"],
  "hashtags": ["#RelevantTag"],
  "thumbnailText": "short thumbnail text",
  "factCheckItems": ["claim/source to verify"]
}
Include a complete, useful narration with enough sections for a 6-10 minute video, and a clear CTA. Keep hashtags relevant and modest in number.
"@
$body = @{ model = $Model; prompt = $prompt; stream = $false; format = "json"; options = @{ temperature = 0.65 } } | ConvertTo-Json -Depth 8
Write-Host "Generating Urdu script with local model '$Model'..." -ForegroundColor Cyan
$response = Invoke-RestMethod -Method Post -Uri "$($OllamaUrl.TrimEnd('/'))/api/generate" -ContentType "application/json" -Body $body -TimeoutSec 900
if ([string]::IsNullOrWhiteSpace($response.response)) { throw "Ollama returned an empty response." }
try { $data = $response.response | ConvertFrom-Json } catch { throw "The model response was not valid JSON. Try again or use a different model. Details: $($_.Exception.Message)" }
if (-not $data.titleOptions -or -not $data.scriptSections) { throw "The model response is missing required fields. Try again." }
New-Item -ItemType Directory -Path $ProjectPath -Force | Out-Null
$scriptLines = [System.Collections.Generic.List[string]]::new()
$scriptLines.Add("# $Title")
$scriptLines.Add("")
$scriptLines.Add("## ٹائٹل کے آپشنز")
foreach ($t in $data.titleOptions) { $scriptLines.Add("- $t") }
$scriptLines.Add("")
$scriptLines.Add("## Hook")
$scriptLines.Add([string]$data.hook)
$scriptLines.Add("")
$scriptLines.Add("## تعارف")
$scriptLines.Add([string]$data.intro)
foreach ($section in $data.scriptSections) {
    $scriptLines.Add("")
    $scriptLines.Add("## $($section.heading)")
    $scriptLines.Add([string]$section.narration)
    $scriptLines.Add("")
    $scriptLines.Add("**ویژول نوٹس:** $($section.visualNotes)")
}
$scriptLines.Add("")
$scriptLines.Add("## سین بہ سین Storyboard")
$scriptLines.Add("| وقت | وائس اوور | ویژول | اسکرین ٹیکسٹ |")
$scriptLines.Add("|---|---|---|---|")
foreach ($scene in $data.storyboard) {
    $cells = @($scene.time, $scene.voiceover, $scene.visual, $scene.onscreenText) | ForEach-Object { ([string]$_) -replace '\|','/' -replace '\r?\n',' ' }
    $scriptLines.Add("| $($cells -join ' | ') |")
}
$scriptLines.Add("")
$scriptLines.Add("## حقائق کی تصدیق")
foreach ($item in $data.factCheckItems) { $scriptLines.Add("- [ ] $item") }
Set-Content -LiteralPath (Join-Path $ProjectPath "script.md") -Value ($scriptLines -join [Environment]::NewLine) -Encoding utf8
$description = [string]$data.description
if ($data.keywords) { $description += [Environment]::NewLine + [Environment]::NewLine + "Keywords: " + ($data.keywords -join ", ") }
Set-Content -LiteralPath (Join-Path $ProjectPath "description.txt") -Value $description -Encoding utf8
$hashtags = @($data.hashtags | Select-Object -Unique) -join " "
Set-Content -LiteralPath (Join-Path $ProjectPath "hashtags.txt") -Value $hashtags -Encoding utf8
Set-Content -LiteralPath (Join-Path $ProjectPath "thumbnail-brief.txt") -Value ([string]$data.thumbnailText) -Encoding utf8
$review = @"
# Final Review — $Title
- [ ] Script read aloud and corrected in Urdu
- [ ] Every factual claim checked against reliable sources
- [ ] No unsupported claim of virality or fabricated statistic
- [ ] Titles and description match the actual video
- [ ] Hashtags and keywords are relevant
- [ ] Visuals, music, and voice have appropriate usage rights
- [ ] Narration and subtitles are synchronized
- [ ] Full exported MP4 watched from start to finish
- [ ] Thumbnail checked at small/mobile size
- [ ] AI disclosure considered if realistic synthetic footage is used
- [ ] Final upload approved by channel owner
"@
Set-Content -LiteralPath (Join-Path $ProjectPath "final-review.md") -Value $review -Encoding utf8
Write-Host ""
Write-Host "AI script package generated: $ProjectPath" -ForegroundColor Green
Write-Host "Review script.md, description.txt, hashtags.txt, thumbnail-brief.txt and final-review.md."
Write-Host "This uses a local Ollama model; it does not browse the web or make an MP4 by itself."
