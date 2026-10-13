[CmdletBinding()]
param(
    [string]$Handle = "@cartoon-in-6",
    [string]$ApiKey = $env:YOUTUBE_API_KEY
)

$ErrorActionPreference = "Stop"
if ([string]::IsNullOrWhiteSpace($ApiKey)) {
    throw "Set the YOUTUBE_API_KEY environment variable in this PowerShell session first. Do not put the key in a script or commit it."
}

$encodedHandle = [uri]::EscapeDataString($Handle)
$channelUri = "https://www.googleapis.com/youtube/v3/channels?part=snippet,statistics,contentDetails&forHandle=$encodedHandle&key=$([uri]::EscapeDataString($ApiKey))"
$response = Invoke-RestMethod -Method Get -Uri $channelUri

if (-not $response.items -or $response.items.Count -eq 0) {
    throw "No channel returned for handle $Handle. Check the handle, API key, and YouTube Data API v3 access."
}

$channel = $response.items[0]
$result = [ordered]@{
    channelTitle = $channel.snippet.title
    channelId = $channel.id
    handle = $Handle
    description = $channel.snippet.description
    publishedAt = $channel.snippet.publishedAt
    subscriberCount = $channel.statistics.subscriberCount
    videoCount = $channel.statistics.videoCount
    viewCount = $channel.statistics.viewCount
    uploadsPlaylistId = $channel.contentDetails.relatedPlaylists.uploads
    note = "Public API statistics only; this does not connect or authorize your Google account."
}

$result | ConvertTo-Json -Depth 5
