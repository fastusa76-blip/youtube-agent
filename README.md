# YouTube AI Automation Agent (Urdu Long Videos)

Configured for:
- Channel: https://youtube.com/@cartoon-in-6
- Language: Urdu
- Format: Long-form videos
- Publishing: Manual approval only

## Current status
This safe starter creates a production folder with an Urdu script template, SEO description, hashtags, and checklist. The public channel-information script uses YouTube Data API v3 when you provide an API key.

Not implemented yet: AI model integration, automated trend research, voice generation, video rendering, thumbnail generation, or YouTube upload. A generated template is not a finished video.

## Requirements
- Windows and PowerShell 7.6.6
- Git
- Optional: YouTube Data API v3 key for public channel statistics

## 1. Create a video project
Run from the repository root:

~~~powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\scripts\new-video.ps1 -Title "AI Se Cartoon Video Kaise Banayein"
~~~

Creates video-projects\<slug> with script.md, description.txt, hashtags.txt, ai-prompt.md, and checklist.md. Review and fact-check all drafts.

## 2. Optional: inspect public channel info
Enable YouTube Data API v3 in Google Cloud Console and create an API key. Then run:

~~~powershell
$env:YOUTUBE_API_KEY = Read-Host "Paste YouTube Data API key"
pwsh -NoProfile -ExecutionPolicy Bypass -File .\scripts\get-channel-public-info.ps1
~~~

The key is only set in this PowerShell session and is not saved in the repository. Do not commit API keys or OAuth tokens.

## 3. Verify files
~~~powershell
Test-Path .\README.md
Test-Path .\config\channel.json
Test-Path .\templates\urdu-long-video-template.md
Test-Path .\scripts\new-video.ps1
Test-Path .\scripts\get-channel-public-info.ps1
Get-ChildItem .\scripts, .\templates, .\config
~~~

The five Test-Path commands should return True.

## Publishing safety
This project does not sign in to Google, upload, or publish anything. Any future upload feature must use Google OAuth and keep the final publishing action under your explicit approval.
