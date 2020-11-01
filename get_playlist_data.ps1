#!/usr/bin/env pwsh
<# 
.SYNOPSIS 
    Creates a list of items in a YouTube playlist
#> 
#Requires -Version 5

### Arguments
param ( 
    [parameter(Mandatory=$false)][string]$ApiKey=$null,
    [parameter(Mandatory=$false)][string]$PlaylistID=$null
) 

function Get-PlaylistName (
    [parameter(Mandatory=$true)][string]$ApiKey=$null,
    [parameter(Mandatory=$true)][string]$PlaylistID=$null
) {
    $headers = @{
        'Accept' = 'application/json'
    }
    $url = "https://youtube.googleapis.com/youtube/v3/playlists?part=snippet&id=${PlaylistID}&key=${ApiKey}"
    Write-Verbose "url: $url"
    $result = (Invoke-RestMethod -Uri $url -Method Get -Headers $headers)
    
    return $result.items[0].snippet.title
}
function Get-PlaylistData (
    [parameter(Mandatory=$true)][string]$ApiKey=$null,
    [parameter(Mandatory=$true)][string]$PlaylistID=$null
) {
    $headers = @{
        'Accept' = 'application/json'
    }
    $videos = New-Object -Type System.Collections.ArrayList
    $batchSize = 50
    do {
        $url = "https://youtube.googleapis.com/youtube/v3/playlistItems?part=snippet&playlistId=${PlaylistID}&key=${ApiKey}&maxResults=${batchSize}&pageToken=$($result.nextPageToken)"
        Write-Verbose "url: $url"
        $result = (Invoke-RestMethod -Uri $url -Method Get -Headers $headers)
        foreach ($item in $result.items) {
            Write-Debug $item
            Write-Debug $item.snippet
            $video = $($item.snippet)
            $videoUrl = "https://www.youtube.com/watch?v=$($item.snippet.resourceId.videoId)"
            $video = $video | Add-Member -MemberType NoteProperty -Name url -Value $videoUrl -Force
            Write-Debug "item.snippet: $($item.snippet)"
            $count = $videos.Add($item.snippet)
        }
        if ($count -gt $batchSize) {
            # Start displaying count after first batch of results
            Write-Host $count
        }
        Write-Verbose "nextPageToken: $($result.nextPageToken)"
    } while ($result.nextPageToken)
    
    return $videos
}

# Validate input
Write-Information $MyInvocation.line
$scriptDirectory = (Split-Path -parent -Path $MyInvocation.MyCommand.Path)
$configFile = (Join-Path $scriptDirectory "config.json")
if (Test-Path $configFile) {
    $config       = (Get-Content $configFile | ConvertFrom-Json)
    if (!$PSBoundParameters.ContainsKey('ApiKey')) {
        $ApiKey = $config.ApiKey
    }
    if (!$PSBoundParameters.ContainsKey('PlaylistID')) {
        $PlaylistID = $config.PlaylistID
    }
} else {
    Write-Information "$configFile not found"
}
if (!($ApiKey -and $PlaylistID)) {
    Write-Host "Specify ApiKey and PlaylistID via arguments or config.json"
    Get-Help $MyInvocation.MyCommand.Definition
    exit
}

# Get playlist name
$playListName = Get-PlaylistName -ApiKey $ApiKey -PlaylistID $PlaylistID
if (!$playListName) {
    Write-Warning "No playlist found with id $PlaylistID, exiting"
    exit
}

# Get playlist data
Write-Host "Retrieving data for playlist '$playListName'..."
$videos = Get-PlaylistData -ApiKey $ApiKey -PlaylistID $PlaylistID

# Export to CSV and plain text
$exportDirectory = (Join-Path $scriptDirectory "data") 
$null = New-Item -ItemType Directory -Force -Path $exportDirectory 
$baseExportName = $(Join-Path $exportDirectory "$($playListName -replace " ","-")-$(Get-Date -f "yyyyMMddHHmmss")")  
$csvFileName = "${baseExportName}.csv"
# Hide multiline description, Excel won't be able to import it :-(
$videos | Select-Object  -Property position, title, publishedAt, url | Export-Csv -Path "$csvFileName" -NoTypeInformation
Write-Host "$csvFileName (can be imported into Excel)"

$txtFileName = "${baseExportName}.txt"
$videos | Format-Table -Property position, title, publishedAt, url, description | Out-File $txtFileName -Width 4096
Write-Host "$txtFileName"
