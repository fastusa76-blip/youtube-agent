[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$Title
)

$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path -Parent $PSScriptRoot
$TemplatePath = Join-Path $RepoRoot "templates\urdu-long-video-template.md"
$ConfigPath = Join-Path $RepoRoot "config\channel.json"
$ProjectsRoot = Join-Path $RepoRoot "video-projects"

if (-not (Test-Path -LiteralPath $TemplatePath)) { throw "Template missing: $TemplatePath" }
if (-not (Test-Path -LiteralPath $ConfigPath)) { throw "Channel configuration missing: $ConfigPath" }

$config = Get-Content -LiteralPath $ConfigPath -Raw | ConvertFrom-Json
$slug = (($Title.ToLowerInvariant() -replace '[^a-z0-9]+', '-') -replace '(^-|-$)', '')
if ([string]::IsNullOrWhiteSpace($slug)) { $slug = "video-$(Get-Date -Format 'yyyyMMdd-HHmmss')" }

New-Item -ItemType Directory -Path $ProjectsRoot -Force | Out-Null
$ProjectPath = Join-Path $ProjectsRoot $slug
if (Test-Path -LiteralPath $ProjectPath) { throw "Project already exists: $ProjectPath. Use a different title." }
New-Item -ItemType Directory -Path $ProjectPath | Out-Null

$template = Get-Content -LiteralPath $TemplatePath -Raw
$template = $template.Replace("{{TITLE}}", $Title)
Set-Content -LiteralPath (Join-Path $ProjectPath "script.md") -Value $template -Encoding utf8

$description = @"
$Title | اردو ٹیوٹوریل

اس ویڈیو میں ہم اس موضوع کو مرحلہ وار سمجھیں گے:
[ویڈیو مکمل ہونے کے بعد یہاں درست خلاصہ لکھیں۔]

چینل: $($config.channelUrl)

#UrduTutorial #AITutorial #CartoonIn6
"@
Set-Content -LiteralPath (Join-Path $ProjectPath "description.txt") -Value $description -Encoding utf8

@"
#UrduTutorial
#AITutorial
#CartoonIn6
"@ | Set-Content -LiteralPath (Join-Path $ProjectPath "hashtags.txt") -Encoding utf8

$prompt = @"
آپ اردو زبان میں یوٹیوب کے لیے ایک مفید لانگ فارم ٹیوٹوریل تیار کرنے میں مدد کریں۔

چینل: $($config.channelUrl)
ویڈیو کا موضوع: $Title

ہدایات:
- پہلے موضوع کے لیے تازہ اور قابلِ اعتماد ریسرچ ذرائع تجویز کریں۔
- غیر تصدیق شدہ بات، جعلی اعدادوشمار یا وائرل ہونے کی ضمانت نہ دیں۔
- قدرتی اردو میں 6 تا 10 منٹ کا مکمل وائس اوور اسکرپٹ لکھیں۔
- Hook، تعارف، مرحلہ وار ہدایات، عام غلطیاں، خلاصہ اور مختصر CTA شامل کریں۔
- ہر سین کے لیے ویژول/اسکرین ریکارڈنگ اور سب ٹائٹل نوٹ دیں۔
- تین ٹائٹل، ایک ڈسکرپشن، متعلقہ keywords اور 3 تا 5 متعلقہ hashtags دیں۔
- حقائق اور کاپی رائٹ کے لیے الگ verification checklist دیں۔
- حتمی ویڈیو اپلوڈ نہ کریں؛ صرف ڈرافٹ بنائیں، انسانی منظوری ضروری ہے۔
"@
Set-Content -LiteralPath (Join-Path $ProjectPath "ai-prompt.md") -Value $prompt -Encoding utf8

$checklist = @"
# Production Checklist: $Title
- [ ] Research sources checked
- [ ] Script fact-checked and edited
- [ ] Urdu narration reviewed
- [ ] Visuals and media rights checked
- [ ] Voiceover and subtitles completed
- [ ] Video rendered and watched in full
- [ ] Description, keywords and hashtags checked
- [ ] Thumbnail checked on mobile size
- [ ] Owner approved the final video
- [ ] Upload performed manually by owner
"@
Set-Content -LiteralPath (Join-Path $ProjectPath "checklist.md") -Value $checklist -Encoding utf8

Write-Host ""
Write-Host "Video project created successfully:" -ForegroundColor Green
Write-Host $ProjectPath
Write-Host "Files: script.md, description.txt, hashtags.txt, ai-prompt.md, checklist.md"
Write-Host "Note: these are drafts/templates; this command does not call an AI model or render an MP4."
