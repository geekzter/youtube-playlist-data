#!/usr/bin/env pwsh
<# 
.SYNOPSIS 
    Imports CSV into playlist
#> 
#Requires -Version 5

### Arguments
param ( 
    [parameter(Mandatory=$true)][string]$CsvFile,
    [parameter(Mandatory=$true)][string]$PlaylistID,
    [parameter(Mandatory=$false)][string]$CredentialFile=$env:GOOGLE_APPLICATION_CREDENTIALS
) 

. (Join-Path $PSScriptRoot functions.ps1)

# Retrieve playlist items, so we can check for duplicates
function Get-PlaylistData (
    [parameter(Mandatory=$true)][string]$PlaylistID=$null,
    [parameter(Mandatory=$false)][int]$BatchSize=50
) {
    Write-Debug "Get-PlaylistData -PlaylistID $PlaylistID -BatchSize $BatchSize"
    $videos = New-Object -Type System.Collections.ArrayList
    do {
        try {
            Wait-BackOff

            $token = Get-GoogleToken -CredentialFile $CredentialFile
            $headers = @{
                'Accept'        = 'application/json'
                'Authorization' = "Bearer $token"
            }
            Write-Debug ($headers | Out-String)

            do {
                $url = "https://youtube.googleapis.com/youtube/v3/playlistItems?part=snippet&playlistId=${PlaylistID}&maxResults=${BatchSize}&pageToken=$($result.nextPageToken)"
                Write-Debug "url: $url"
                $result = (Invoke-RestMethod -Uri $url -Method Get -Headers $headers)
                if ($DebugPreference -ieq "Continue") {
                    Write-Debug $result
                }
                foreach ($item in $result.items) {
                    $videoId = $item.snippet.resourceId.videoId
                    $count = $videos.Add($videoId)
                }
                if ($count -gt $BatchSize) {
                    # Start displaying count after first batch of results
                    Write-Host $count
                }
                Write-Debug "nextPageToken: $($result.nextPageToken)"
            } while ($result.nextPageToken)

            Reset-BackOff
        }
        catch [Microsoft.PowerShell.Commands.HttpResponseException] {
            Write-Debug "Microsoft.PowerShell.Commands.HttpResponseException"
            Display-ExceptionInformation
            switch -regex ($_.ErrorDetails.Message) {
                "INTERNAL_ERROR" {
                    Calculate-BackOff
                }
                "SERVICE_UNAVAILABLE" {
                    Calculate-BackOff
                }
                "quotaExceeded" {  
                    Calculate-BackOff
                }
                "emporar.*navailable" {
                    Calculate-BackOff
                }
                "rateLimitExceeded" {
                    Calculate-BackOff
                }
                default {
                    Reset-BackOff
                    break
                }
            }
        }   
        catch [System.Net.Http.HttpRequestException] {
            Write-Debug "System.Net.Http.HttpRequestException"
            Display-ExceptionInformation
            Calculate-BackOff
        }
        catch [System.Management.Automation.RuntimeException] {
            Write-Debug "System.Management.Automation.RuntimeException"
            Display-ExceptionInformation
            switch -regex ($_.Exception.Message) {
                "Max retries exceeded" {
                    Calculate-BackOff
                }
                "nodename nor servname provided" {
                    Calculate-BackOff
                }
                "There was a problem refreshing your current auth tokens" {
                    Calculate-BackOff
                }
                default {
                    Reset-BackOff
                    break
                }
            }
        }
        catch {
            Display-ExceptionInformation
            break
        }
    } while ($(Continue-BackOff))
  
    return $videos
}

# Package validation & setup
Validate-Packages

# Validate input
Write-Information $MyInvocation.line
$scriptDirectory = (Split-Path -parent -Path $MyInvocation.MyCommand.Path)
$configFile = (Join-Path $scriptDirectory "config.json")
if (Test-Path $configFile) {
    $config       = (Get-Content $configFile | ConvertFrom-Json)
    if (!$PSBoundParameters.ContainsKey('CredentialFile')) {
        $CredentialFile = $config.ClientCredentialFile
    }
} else {
    Write-Information "$configFile not found"
}
if (!$CredentialFile) {
    Write-Host "Specify CredentialFile via argument or config.json"
    Get-Help $MyInvocation.MyCommand.Definition
    exit
}
Write-Debug "CredentialFile: $CredentialFile"

if (Test-Path $CsvFile) {
    $dataFile = Get-Item $CsvFile
} else {
    Write-Warning "$CsvFile not found"
    exit
}

# Main
$importData = Import-Csv $dataFile.FullName

# Retrieve playlist items, so we can check for duplicates
[System.Collections.ArrayList]$videoIds = Get-PlaylistData -PlaylistID $PlaylistID
if ((!$videoIds) -or ($videoIds.Count -eq 0)) {
    Write-Warning "Unable to retrieve existing playlist items, exiting..."
    exit
}

$cursorFileName = "$($dataFile.FullName)-${PlaylistID}-cursor.txt"
$imported = 0
:outer foreach ($importTrack in $importData) {
    do {
        try {
            Wait-BackOff

            Write-Debug $importTrack
    
            if ($videoIds.Contains($importTrack.id)) {
                $targetOccurrence = $videoIds.IndexOf($importTrack.id)
                Write-Host "Import skipped (duplicate) (source: $($importTrack.position) -> target: $targetOccurrence): $($importTrack.title)"
                continue
            }

            $playListSnippetTemplate = ('{"snippet":{"playlistId":"PLAYLIST_ID","resourceId":{"kind":"youtube#video","videoId":"VIDEO_ID"}}}' | ConvertFrom-Json)
            $playListSnippetTemplate.snippet.playlistId = $PlaylistID
            $playListSnippetTemplate.snippet.resourceId.videoId = $importTrack.id
        
            $token = Get-GoogleToken -CredentialFile $CredentialFile
            $snippet = ($playListSnippetTemplate | ConvertTo-Json)
            $headers = @{
                'Accept'        = "application/json"
                'Authorization' = "Bearer $token"
                'Content-Type'  = "application/json"
            }
            Write-Debug ($headers | Out-String)
    
            $url = "https://youtube.googleapis.com/youtube/v3/playlistItems?part=snippet"
            Write-Debug "url: $url"
            $result = (Invoke-RestMethod -Uri $url -Method Post -Headers $headers -Body $snippet -StatusCodeVariable status)
            if ($DebugPreference -ieq "Continue") {
                Write-Debug $result
            }
            $importedTrackTitle = $result.snippet.title
            if ($importedTrackTitle) {
                # Keep track of what we have imported
                $imported++
                $playListItemCount = $videoIds.Add($importTrack.id)
                Write-Output $importTrack.position | Out-File $cursorFileName
    
                Write-Host "Imported # $imported (source: $($importTrack.position) -> target: $playListItemCount): ${importedTrackTitle}"
            } else {
                Write-Warning "Import failed: $($importTrack.title)"
            }

            Reset-BackOff
        }
        catch [Microsoft.PowerShell.Commands.HttpResponseException] {
            Write-Debug "Microsoft.PowerShell.Commands.HttpResponseException"
            Display-ExceptionInformation
            # https://developers.google.com/youtube/v3/docs/errors
            switch -regex ($_.ErrorDetails.Message) {
                "INTERNAL_ERROR" {
                    Calculate-BackOff
                }
                "SERVICE_UNAVAILABLE" {
                    Calculate-BackOff
                }
                "playlistItemsNotAccessible" {
                    Reset-BackOff
                    Write-Host "Import skipped (item hidden) (source: $($importTrack.position)): $($importTrack.title)"
                    continue
                }
                "quotaExceeded" {  
                    Calculate-BackOff
                }
                "emporar.*navailable" {
                    Calculate-BackOff
                }
                "rateLimitExceeded" {
                    Calculate-BackOff
                }
                "videoNotFound" {
                    Reset-BackOff
                    Write-Host "Import skipped (item deleted) (source: $($importTrack.position)): $($importTrack.title)"
                    continue
                }
                default {
                    Reset-BackOff
                    break outer
                }
            }
        }
        catch [System.Net.Http.HttpRequestException] {
            Write-Debug "System.Net.Http.HttpRequestException"
            Display-ExceptionInformation
            Calculate-BackOff
        }
        catch [System.Management.Automation.RuntimeException] {
            Write-Debug "System.Management.Automation.RuntimeException"
            Display-ExceptionInformation
            switch -regex ($_.Exception.Message) {
                "Max retries exceeded" {
                    Calculate-BackOff
                }
                "nodename nor servname provided" {
                    Calculate-BackOff
                }
                "There was a problem refreshing your current auth tokens" {
                    Calculate-BackOff
                }
                default {
                    Reset-BackOff
                    break
                }
            }
        }
        catch {
            Display-ExceptionInformation
            break outer
        }
    } while ($(Continue-BackOff))
}