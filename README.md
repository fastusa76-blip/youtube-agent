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


## 4. Generate a full Urdu script locally (free, no cloud API key)

This uses Ollama on your own PC. It needs enough RAM and disk space to download/run the model.

1. Install Ollama from https://ollama.com/download/windows
2. Open PowerShell and run:

~~~powershell
ollama pull qwen2.5:7b
~~~

3. From the repository root, generate the script package:

~~~powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\scripts\generate-script.ps1 -Title "AI Se Cartoon Video Kaise Banayein"
~~~

The script uses the local Ollama API and writes the Urdu script, storyboard, description, hashtags, thumbnail brief, and final review checklist. It does not browse the web, so fact-check the content before use. If your PC has limited RAM, use a smaller Ollama model and pass its name with `-Model`.

## 5. Build a slideshow MP4 (requires FFmpeg and visuals)

Install FFmpeg and confirm `ffmpeg -version` works. Put properly licensed PNG/JPG/WEBP images into the generated project's `visuals` folder. Optional narration audio can be named `narration.mp3`, `narration.wav`, or `narration.m4a` in the project folder.

~~~powershell
$Project = ".\video-projects\ai-se-cartoon-video-kaise-banayein"
New-Item -ItemType Directory -Force "$Project\visuals" | Out-Null
# Copy your licensed visual images into the visuals folder before building.
pwsh -NoProfile -ExecutionPolicy Bypass -File .\scripts\build-video.ps1 -Project "ai-se-cartoon-video-kaise-banayein"
~~~

This produces `final-video.mp4` from still images and optional narration. It is a slideshow builder, not a generative motion-video model. If the narration is longer than the slideshow, add more images or increase `-SecondsPerImage`.

## 6. Free video tool notes

See [docs/free-video-tools.md](docs/free-video-tools.md) for current official links and free-tier limitations. Free credits, regional access, watermark rules, and AI voices can change.

Manual approval remains required. Do not upload until you have watched the whole exported video and completed `final-review.md`.
