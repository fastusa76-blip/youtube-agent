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
$playlistId = $channel.contentDetails.relatedPlaylists.uploads
$playlistUri = "https://www.googleapis.com/youtube/v3/playlistItems?part=snippet,contentDetails&playlistId=$([uri]::EscapeDataString($playlistId))&maxResults=10&key=$([uri]::EscapeDataString($ApiKey))"
$playlistResponse = Invoke-RestMethod -Method Get -Uri $playlistUri

$recentVideos = @(
    foreach ($item in $playlistResponse.items) {
        [ordered]@{
            title = $item.snippet.title
            publishedAt = $item.snippet.publishedAt
            videoId = $item.contentDetails.videoId
            url = "https://www.youtube.com/watch?v=$($item.contentDetails.videoId)"
        }
    }
)

$result = [ordered]@{
    channelTitle = $channel.snippet.title
    channelId = $channel.id
    handle = $Handle
    description = $channel.snippet.description
    publishedAt = $channel.snippet.publishedAt
    subscriberCount = $channel.statistics.subscriberCount
    videoCount = $channel.statistics.videoCount
    viewCount = $channel.statistics.viewCount
    uploadsPlaylistId = $playlistId
    recentVideos = $recentVideos
    note = "Public channel statistics and recent public video titles only. This does not authorize your Google account or infer a reliable niche automatically."
}

$result | ConvertTo-Json -Depth 6
