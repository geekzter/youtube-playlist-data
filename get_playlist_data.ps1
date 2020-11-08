#!/usr/bin/env pwsh
<# 
.SYNOPSIS 
    Creates a list of items in a YouTube playlist, and stores it in the data subdirectory
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

            # Remove linefeeds, as Excel won't be able to import them :-(
            $item.snippet.description = (($item.snippet.description) -replace "`r`n","<br/>")
            $item.snippet.description = (($item.snippet.description) -replace "`n","<br/>")
            $item.snippet.description = (($item.snippet.description) -replace "`r","<br/>")

            $video = $($item.snippet)

            # Parse suspecter track details
            $Matches.Clear()

            [regex]$yearRegex = '(?<year>\d\d\d\d)'
            $yearMatches = $yearRegex.Matches($item.snippet.title)
            $yearCount = ($yearMatches | Measure-Object).Count
            $year = $yearMatches[$yearCount-1]
            $video | Add-Member -MemberType NoteProperty -Name parsed_year -Value $year -Force

            $null = $item.snippet.title -match " *(?<artist>[\&\w\. ]+) +- +(?<title>[\&\w\.\' ]+)"
            # Add-Member -InputObject $item.snippet.title -NotePropertyName "parsed_artist" -NotePropertyValue $Matches['artist']
            $video | Add-Member -MemberType NoteProperty -Name parsed_artist -Value $Matches['artist'] -Force
            $video | Add-Member -MemberType NoteProperty -Name parsed_title -Value $Matches['title'] -Force

            $null = $item.snippet.title -imatch " *(?<version>[\w\'\`"\. ]*(Groove|Instrumental|Mix|Version))" 
            $video | Add-Member -MemberType NoteProperty -Name parsed_version -Value $Matches['version'] -Force

            $videoUrl = "https://www.youtube.com/watch?v=$($item.snippet.resourceId.videoId)"
            $video | Add-Member -MemberType NoteProperty -Name url -Value $videoUrl -Force
            Write-Debug "video: $video"
            $count = $videos.Add($video)
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
$videos | Select-Object  -Property position, title, parsed_artist, parsed_title, parsed_version, parsed_year, publishedAt, url, description | Export-Csv -Path "$csvFileName" -NoTypeInformation -Encoding utf8BOM
Write-Host "$csvFileName (can be imported into Excel)"

$txtFileName = "${baseExportName}.txt"
$videos | Format-Table -Property position, title, parsed_artist, parsed_title, parsed_version, parsed_year, publishedAt, url, description | Out-File $txtFileName -Width 4096
Write-Host "$txtFileName"
